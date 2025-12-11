terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
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
