variable "project_id" {
  type        = string
  description = "GCP project ID to deploy into."
}

variable "region" {
  type        = string
  description = "Region for the Artifact Registry repository."
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "Zone for the (zonal) GKE cluster. A zonal cluster is cheaper and qualifies for the one free zonal cluster per billing account."
  default     = "us-central1-a"
}

variable "cluster_name" {
  type        = string
  description = "Name of the GKE cluster."
  default     = "telemetry-collector"
}

variable "repository_id" {
  type        = string
  description = "Artifact Registry Docker repository ID that holds the collector image."
  default     = "telemetry-collector"
}

variable "machine_type" {
  type        = string
  description = "Machine type for the node pool. e2-standard-2 (2 vCPU / 8 GiB) comfortably fits the collector, Loki, Prometheus, and the log agent."
  default     = "e2-standard-2"
}

variable "node_count" {
  type        = number
  description = "Number of nodes in the pool. Two nodes lets the DaemonSet log agent demonstrate multi-node collection."
  default     = 2
}
