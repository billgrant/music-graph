terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable Secret Manager API
resource "google_project_service" "secretmanager" {
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# Enable Cloud SQL Admin API
resource "google_project_service" "sqladmin" {
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

# Enable Cloud Run API
resource "google_project_service" "cloudrun" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

# Import existing GCR repository into Terraform state
import {
  to = google_artifact_registry_repository.music_graph
  id = "projects/music-graph-479719/locations/us/repositories/gcr.io"
}

# Configure cleanup policy for Google Container Registry (Artifact Registry)
# GCR uses Artifact Registry as its backend
resource "google_artifact_registry_repository" "music_graph" {
  location      = var.region
  repository_id = "gcr.io"
  description   = "Container registry for music-graph Docker images"
  format        = "DOCKER"

  cleanup_policies {
    id     = "delete-old-dev-images"
    action = "DELETE"

    condition {
      tag_state    = "TAGGED"
      tag_prefixes = ["dev-"]
      older_than   = "2592000s"  # Delete dev images older than 30 days
    }
  }

  cleanup_policies {
    id     = "keep-production-releases"
    action = "KEEP"

    condition {
      tag_state    = "TAGGED"
      tag_prefixes = ["v", "production", "latest"]
    }
  }
}

# Google Cloud Storage bucket for database backups
resource "google_storage_bucket" "database_backups" {
  name          = "music-graph-backups-${var.project_id}"
  location      = "US"  # Multi-region for disaster recovery
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  versioning {
    enabled = false  # Don't need versioning for backups
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 7  # Delete backups older than 7 days
    }
  }

  labels = {
    purpose = "database-backups"
    app     = "music-graph"
  }
}

# IAM: Allow VMs to write to backup bucket
resource "google_storage_bucket_iam_member" "backup_writer" {
  bucket = google_storage_bucket.database_backups.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

# IAM: Allow reading backups for restore
resource "google_storage_bucket_iam_member" "backup_reader" {
  bucket = google_storage_bucket.database_backups.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
}

# AWS provider for Route53 DNS management (certbot)
provider "aws" {
  region = "us-east-1"  # Route53 is global, but provider needs a region
}

# AWS IAM resources for certbot Route53 DNS-01 challenge
# This allows certbot to create DNS TXT records for domain validation

resource "aws_iam_policy" "certbot_route53" {
  name        = "certbot-route53-dns-music-graph"
  description = "Allows certbot to create DNS records in Route53 for domain validation"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:GetChange"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "route53:ChangeResourceRecordSets"
        Resource = "arn:aws:route53:::hostedzone/*"
      }
    ]
  })
}

resource "aws_iam_user" "certbot" {
  name = "certbot-music-graph"
}

resource "aws_iam_user_policy_attachment" "certbot_route53" {
  user       = aws_iam_user.certbot.name
  policy_arn = aws_iam_policy.certbot_route53.arn
}

resource "aws_iam_access_key" "certbot" {
  user = aws_iam_user.certbot.name
}

# IAM: Allow GitHub Actions service account to deploy to Cloud Run
resource "google_project_iam_member" "github_actions_cloud_run" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:github-actions-music-graph@${var.project_id}.iam.gserviceaccount.com"
}

# Outputs for certbot AWS credentials
output "certbot_access_key_id" {
  description = "AWS Access Key ID for certbot (save to ~/.aws/credentials on VMs)"
  value       = aws_iam_access_key.certbot.id
}

output "certbot_secret_access_key" {
  description = "AWS Secret Access Key for certbot (save to ~/.aws/credentials on VMs)"
  value       = aws_iam_access_key.certbot.secret
  sensitive   = true
}
