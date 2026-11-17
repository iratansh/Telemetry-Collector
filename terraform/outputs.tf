output "image_repository" {
  description = "Base path for the collector image. Append /collector:<tag>."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.collector.repository_id}"
}

output "registry_host" {
  description = "Artifact Registry host to authorize with `gcloud auth configure-docker`."
  value       = "${var.region}-docker.pkg.dev"
}

output "get_credentials_command" {
  description = "Run this to point kubectl at the new cluster."
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${var.zone} --project ${var.project_id}"
}

output "next_steps" {
  description = "What to do after apply."
  value       = "1) run the get_credentials_command above  2) PROJECT_ID=${var.project_id} REGION=${var.region} sh scripts/gke-deploy.sh  3) sh scripts/gke-portforward.sh  4) start local Grafana (deploy/local-grafana)"
}
