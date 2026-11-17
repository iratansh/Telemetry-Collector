# Terraform — GCP infrastructure

Provisions the **cloud infrastructure only**: a GKE Standard cluster, an Artifact
Registry Docker repository, and the one IAM grant that lets nodes pull the image.
The application workloads (collector, Loki, Prometheus, log agent) are plain
Kubernetes manifests in [`../deploy/kubernetes`](../deploy/kubernetes), applied with
`kubectl` by [`../scripts/gke-deploy.sh`](../scripts/gke-deploy.sh).

See [`../DEPLOY_GKE.md`](../DEPLOY_GKE.md) for the full end-to-end runbook.

## What gets created

| Resource | File | Notes |
| --- | --- | --- |
| Enabled APIs (container, artifactregistry, compute) | `main.tf` | `disable_on_destroy = false` |
| Artifact Registry Docker repo | `main.tf` | holds `collector:<tag>` |
| GKE **Standard** zonal cluster | `main.tf` | Standard (not Autopilot) so the log DaemonSet can `hostPath`-mount `/var/log` |
| Node pool (2 × e2-standard-2) | `main.tf` | `deletion_protection = false` on the cluster |
| Artifact Registry reader for the node SA | `iam.tf` | the only Google IAM the setup needs |

> The collector itself needs **no** Google IAM — it reaches the Kubernetes API via
> in-cluster RBAC, not Workload Identity. That is intentional and keeps this simple.

## Prerequisites

- `terraform` ≥ 1.5, `gcloud`, `kubectl`, and Docker.
- `gcloud auth application-default login` (so Terraform can authenticate).
- A GCP project with billing enabled.

## Usage

```sh
cd terraform
cp terraform.tfvars.example terraform.tfvars   # set project_id
terraform init
terraform apply                                # ~5-10 min for the cluster
terraform output next_steps
```

## Teardown

```sh
terraform destroy
```

This deletes the cluster, node pool, and registry. **PersistentVolumes created by
the workloads** (Loki/Prometheus/WAL disks) are provisioned dynamically by GKE; if
`kubectl delete` was not run first, their backing Compute Engine disks may remain —
check `gcloud compute disks list` and delete any `pvc-…` disks to stop charges.

## Cost note

A zonal Standard cluster qualifies for the free cluster-management tier (one zonal
cluster per billing account); you pay for the two `e2-standard-2` nodes and the
persistent disks — roughly a few USD per day. Run `terraform destroy` when you are
done for the day.
