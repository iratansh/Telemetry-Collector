# The collector needs NO Google Cloud IAM: it reaches the Kubernetes API with an
# in-cluster ServiceAccount authorized by Kubernetes RBAC (deploy/kubernetes/rbac.yaml),
# and talks to Loki over plain in-cluster HTTP. So there is no Workload Identity
# binding here on purpose — it would add moving parts for no benefit.
#
# The Google IAM that IS needed is around the container image:
#   - GKE nodes (the compute default SA) must PULL it.
#   - Cloud Build must PUSH it (the recommended build path; see scripts/gke-deploy.sh).
#
# Granting the compute default SA artifactregistry.writer covers node pulls AND
# Cloud Build when it runs as that SA (the default in current GCP projects). The
# @cloudbuild grant covers projects where Cloud Build still uses its legacy SA.
resource "google_artifact_registry_repository_iam_member" "compute_sa" {
  location   = google_artifact_registry_repository.collector.location
  repository = google_artifact_registry_repository.collector.repository_id
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${data.google_project.this.number}-compute@developer.gserviceaccount.com"
}

resource "google_artifact_registry_repository_iam_member" "cloudbuild_sa" {
  location   = google_artifact_registry_repository.collector.location
  repository = google_artifact_registry_repository.collector.repository_id
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${data.google_project.this.number}@cloudbuild.gserviceaccount.com"
}
