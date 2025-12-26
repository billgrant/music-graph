terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend bucket configured via -backend-config in CI
  backend "gcs" {
    prefix = "state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "aws" {
  region = "us-east-1" # Route53 is global, region is just for provider
}

module "music_graph" {
  source = "../../modules/music-graph"

  project_id    = var.project_id
  region        = var.region
  environment   = "prod"
  admin_ips     = var.admin_ips
  domain_base   = var.domain_base
  app_subdomain = var.app_subdomain
}

# =============================================================================
# Variables - provided via TF_VAR_* environment variables in CI
# =============================================================================

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "domain_base" {
  description = "Base domain (e.g., billgrant.io)"
  type        = string
}

variable "app_subdomain" {
  description = "Application subdomain prefix (e.g., music-graph)"
  type        = string
}

variable "admin_ips" {
  description = "List of admin IP addresses for Cloud SQL access (set via TF_VAR_admin_ips)"
  type        = list(string)
  default     = []
}

output "cloud_run_url" {
  value = module.music_graph.cloud_run_url
}

output "cloud_sql_connection_name" {
  value = module.music_graph.cloud_sql_connection_name
}
