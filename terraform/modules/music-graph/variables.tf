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

variable "route53_zone_name" {
  description = "Route53 hosted zone name"
  type        = string
  default     = "billgrant.io."
}
