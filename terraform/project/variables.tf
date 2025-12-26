variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "project_number" {
  description = "GCP project number (for service account IAM)"
  type        = string
}

variable "region" {
  description = "GCP region for Artifact Registry"
  type        = string
}
