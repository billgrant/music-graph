variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-east1"
}

variable "route53_zone_name" {
  description = "Route53 hosted zone name"
  type        = string
  default     = "billgrant.io."
}
