data "google_project" "this" {}

locals {
  # APIs the cluster and registry need. disable_on_destroy is false so a
  # destroy does not try to turn APIs off for the whole project.
  services = [
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "cloudbuild.googleapis.com",
  ]
}

resource "google_project_service" "enabled" {
  for_each           = toset(local.services)
  service            = each.value
  disable_on_destroy = false
}

# Docker repository that holds the collector image the GKE workload pulls.
resource "google_artifact_registry_repository" "collector" {
  location      = var.region
  repository_id = var.repository_id
  format        = "DOCKER"
  description   = "Images for the distributed telemetry collector"

  depends_on = [google_project_service.enabled]
}

# GKE Standard (not Autopilot): the log-shipping DaemonSet needs a hostPath
# mount of /var/log, which Autopilot blocks. Zonal to minimize cost.
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone

  # Manage our own pool so we control machine type and size.
  remove_default_node_pool = true
  initial_node_count       = 1

  # This is a disposable study cluster — allow terraform destroy to delete it.
  deletion_protection = false

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {}

  release_channel {
    channel = "REGULAR"
  }

  depends_on = [google_project_service.enabled]
}

resource "google_container_node_pool" "primary" {
  name     = "primary"
  cluster  = google_container_cluster.primary.id
  location = var.zone

  node_count = var.node_count

  node_config {
    machine_type = var.machine_type
    disk_size_gb = 50
    disk_type    = "pd-balanced"

    # Broad scope keeps setup simple for a study project; the node identity is
    # still the default compute service account, granted only AR read in iam.tf.
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    labels = {
      pool = "primary"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
