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

  backend "gcs" {
    bucket = "music-graph-479719-tf-dev"
    prefix = "state"
  }
}

provider "google" {
  project = "music-graph-479719"
  region  = "us-east1"
}

provider "aws" {
  region = "us-east-1"
}

module "music_graph" {
  source = "../../modules/music-graph"

  project_id  = "music-graph-479719"
  region      = "us-east1"
  environment = "dev"
  admin_ips   = var.admin_ips
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
