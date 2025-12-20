variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "music-graph-479719"
}

variable "project_number" {
  description = "GCP project number (for service account IAM)"
  type        = string
  default     = "384521044390"
}

variable "region" {
  description = "GCP region for Artifact Registry"
  type        = string
  default     = "us"
}
