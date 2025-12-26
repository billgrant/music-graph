variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "environment" {
  description = "Environment name (prod, dev)"
  type        = string
}

variable "admin_ips" {
  description = "List of admin IP addresses for Cloud SQL access (set via TF_VAR_admin_ips for local debugging)"
  type        = list(string)
  default     = []
}

variable "domain_base" {
  description = "Base domain (e.g., billgrant.io)"
  type        = string
}

variable "app_subdomain" {
  description = "Application subdomain prefix (e.g., music-graph)"
  type        = string
}
