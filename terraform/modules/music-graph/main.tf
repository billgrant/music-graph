# =============================================================================
# Route53 DNS
# =============================================================================

data "aws_route53_zone" "billgrant" {
  name = "${var.domain_base}."
}

# =============================================================================
# Cloud SQL - PostgreSQL Database
# =============================================================================

resource "google_sql_database_instance" "music_graph" {
  name             = "music-graph-${var.environment}"
  database_version = "POSTGRES_16"
  region           = var.region

  deletion_protection = var.environment == "prod" ? true : false

  settings {
    tier              = "db-g1-small"
    edition           = "ENTERPRISE"
    availability_type = "ZONAL"
    disk_size         = 10
    disk_type         = "PD_SSD"

    ip_configuration {
      ipv4_enabled = true

      dynamic "authorized_networks" {
        for_each = var.admin_ips
        content {
          name  = "admin-${authorized_networks.key}"
          value = authorized_networks.value
        }
      }
    }

    backup_configuration {
      enabled                        = var.environment == "prod" ? true : false
      point_in_time_recovery_enabled = var.environment == "prod" ? true : false
      start_time                     = "03:00"
      backup_retention_settings {
        retained_backups = 7
      }
    }

    maintenance_window {
      day  = 7
      hour = 4
    }

    user_labels = {
      environment = var.environment
      app         = "music-graph"
    }
  }
}

resource "google_sql_database" "music_graph" {
  name     = "musicgraph"
  instance = google_sql_database_instance.music_graph.name
}

resource "google_sql_user" "music_graph" {
  name     = "musicgraph"
  instance = google_sql_database_instance.music_graph.name
  password = random_password.postgres_password.result
}

# =============================================================================
# Secret Manager - Application Secrets
# =============================================================================

data "google_project" "current" {}

resource "random_password" "flask_secret_key" {
  length  = 64
  special = true
}

resource "random_password" "postgres_password" {
  length  = 32
  special = false
}

resource "google_secret_manager_secret" "flask_secret_key" {
  secret_id = "music-graph-${var.environment}-secret-key"

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    app         = "music-graph"
  }
}

resource "google_secret_manager_secret_version" "flask_secret_key" {
  secret      = google_secret_manager_secret.flask_secret_key.id
  secret_data = random_password.flask_secret_key.result
}

resource "google_secret_manager_secret" "postgres_password" {
  secret_id = "music-graph-${var.environment}-db-password"

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    app         = "music-graph"
  }
}

resource "google_secret_manager_secret_version" "postgres_password" {
  secret      = google_secret_manager_secret.postgres_password.id
  secret_data = random_password.postgres_password.result
}

resource "google_secret_manager_secret" "database_url_cloudrun" {
  secret_id = "music-graph-${var.environment}-database-url-cloudrun"

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    app         = "music-graph"
  }
}

resource "google_secret_manager_secret_version" "database_url_cloudrun" {
  secret      = google_secret_manager_secret.database_url_cloudrun.id
  secret_data = "postgresql+psycopg2://${google_sql_user.music_graph.name}:${random_password.postgres_password.result}@/${google_sql_database.music_graph.name}?host=/cloudsql/${google_sql_database_instance.music_graph.connection_name}"
}

# =============================================================================
# Cloud Run
# =============================================================================

resource "google_service_account" "cloud_run" {
  account_id   = "music-graph-${var.environment}"
  display_name = "Music Graph Cloud Run (${var.environment})"
}

resource "google_project_iam_member" "cloud_run_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

resource "google_secret_manager_secret_iam_member" "cloud_run_flask_secret" {
  secret_id = google_secret_manager_secret.flask_secret_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloud_run.email}"
}

resource "google_secret_manager_secret_iam_member" "cloud_run_database_url" {
  secret_id = google_secret_manager_secret.database_url_cloudrun.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloud_run.email}"
}

resource "google_service_account_iam_member" "github_actions_act_as_cloud_run" {
  service_account_id = google_service_account.cloud_run.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:github-actions-music-graph@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_cloud_run_v2_service" "music_graph" {
  name                = "music-graph-${var.environment}"
  location            = var.region
  deletion_protection = var.environment == "prod" ? true : false

  template {
    service_account = google_service_account.cloud_run.email

    containers {
      image = "gcr.io/${var.project_id}/music-graph:${var.environment == "prod" ? "production" : "dev-latest"}"

      ports {
        container_port = 5000
      }

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      env {
        name = "SECRET_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.flask_secret_key.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.database_url_cloudrun.secret_id
            version = "latest"
          }
        }
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.music_graph.connection_name]
      }
    }

    scaling {
      min_instance_count = var.environment == "prod" ? 1 : 0
      max_instance_count = 2
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  depends_on = [
    google_secret_manager_secret_version.flask_secret_key,
    google_secret_manager_secret_version.database_url_cloudrun,
  ]

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,  # CI/CD owns the deployed image
      client,                            # Set by gcloud, not managed by Terraform
      client_version,
      scaling,                           # Service-level scaling metadata set by GCP
    ]
  }
}

resource "google_cloud_run_v2_service_iam_member" "public" {
  name     = google_cloud_run_v2_service.music_graph.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_domain_mapping" "music_graph" {
  name     = var.environment == "prod" ? "${var.app_subdomain}.${var.domain_base}" : "dev.${var.app_subdomain}.${var.domain_base}"
  location = var.region

  metadata {
    namespace = var.project_id
  }

  spec {
    route_name = google_cloud_run_v2_service.music_graph.name
  }
}

resource "aws_route53_record" "music_graph" {
  zone_id = data.aws_route53_zone.billgrant.zone_id
  name    = var.environment == "prod" ? var.app_subdomain : "dev.${var.app_subdomain}"
  type    = "CNAME"
  ttl     = 300
  records = ["ghs.googlehosted.com"]
}
