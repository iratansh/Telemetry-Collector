#!/bin/sh
# Build and push the collector image, then apply the Kubernetes workloads.
# Run from the repository root AFTER `terraform apply` and `get-credentials`.
#
#   PROJECT_ID=my-project REGION=us-central1 sh scripts/gke-deploy.sh
#
# Env:
#   PROJECT_ID  (required) GCP project ID
#   REGION      (default us-central1) must match terraform var.region
#   REPO        (default telemetry-collector) Artifact Registry repo ID
#   TAG         (default latest) image tag
#   BUILDER     (default cloudbuild) "cloudbuild" builds on GCP (native amd64,
#               no local Docker); "docker" builds locally with --platform linux/amd64
#   WITH_PRODUCER (default yes) set to "no" to skip the demo producer
set -eu

PROJECT_ID=${PROJECT_ID:?set PROJECT_ID to your GCP project}
REGION=${REGION:-us-central1}
REPO=${REPO:-telemetry-collector}
TAG=${TAG:-latest}
BUILDER=${BUILDER:-cloudbuild}
WITH_PRODUCER=${WITH_PRODUCER:-yes}

IMAGE="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO/collector:$TAG"
echo "Image: $IMAGE  (builder: $BUILDER)"

# 1. Build and push the image. Cloud Build is the default: it builds on GCP as
#    native amd64, so it is reliable from an Apple Silicon workstation (where an
#    emulated local `docker build --platform linux/amd64` can crash in QEMU).
case "$BUILDER" in
  cloudbuild)
    gcloud builds submit --project "$PROJECT_ID" --tag "$IMAGE" .
    ;;
  docker)
    gcloud auth configure-docker "$REGION-docker.pkg.dev" --quiet
    docker build --platform linux/amd64 -t "$IMAGE" .
    docker push "$IMAGE"
    ;;
  *)
    echo "Unknown BUILDER=$BUILDER (use 'cloudbuild' or 'docker')" >&2
    exit 2
    ;;
esac

# 2. Apply workloads. Namespace and RBAC first, then the stateful backends,
#    then the collector, the log agent, and (optionally) the demo producer.
kubectl apply -f deploy/kubernetes/namespace.yaml
kubectl apply -f deploy/kubernetes/rbac.yaml
kubectl apply -f deploy/kubernetes/loki.yaml
kubectl apply -f deploy/kubernetes/prometheus.yaml
sed "s|IMAGE_PLACEHOLDER|$IMAGE|g" deploy/kubernetes/collector.yaml | kubectl apply -f -
kubectl apply -f deploy/kubernetes/otel-agent.yaml
if [ "$WITH_PRODUCER" = "yes" ]; then
  sed "s|IMAGE_PLACEHOLDER|$IMAGE|g" deploy/kubernetes/producer.yaml | kubectl apply -f -
fi

# 3. Wait for the core pieces to come up.
kubectl -n telemetry rollout status deployment/loki --timeout=180s
kubectl -n telemetry rollout status deployment/telemetry-collector --timeout=180s

echo
echo "Deployed to namespace 'telemetry'. Next:"
echo "  sh scripts/gke-portforward.sh        # expose Loki + Prometheus to localhost"
echo "  docker compose -f deploy/local-grafana/compose.yaml up   # local Grafana"
