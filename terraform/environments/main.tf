terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Static IP address
resource "google_compute_address" "music_graph_ip" {
  name   = "${var.environment}-music-graph-ip"
  region = var.region
}


# Compute Engine instance
resource "google_compute_instance" "music_graph" {
  name         = "${var.environment}-music-graph"
  machine_type = var.machine_type
  zone         = var.zone
  allow_stopping_for_update = true

  tags = ["http-server", "https-server", "music-graph-${var.environment}"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.disk_size_gb
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.music_graph_ip.address
    }
  }

  service_account {
    # Uses the default compute engine service account
    # This enables the VM to authenticate to GCP services via metadata service
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  metadata_startup_script = file("${path.module}/startup-script.sh")

  labels = {
    environment = var.environment
    app         = "music-graph"
  }
}

# Firewall rule for HTTP (public access)
resource "google_compute_firewall" "http" {
  name    = "allow-http-${var.environment}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = var.allowed_web_ips
  target_tags   = ["http-server"]
}

# Firewall rule for HTTPS (public access)
resource "google_compute_firewall" "https" {
  name    = "allow-https-${var.environment}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = var.allowed_web_ips
  target_tags   = ["https-server"]
}

# Firewall rule for SSH (restricted access)
resource "google_compute_firewall" "ssh" {
  name    = "allow-ssh-${var.environment}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_ips
  target_tags   = ["music-graph-${var.environment}"]
}

# =============================================================================
# Secret Manager - Application Secrets
# =============================================================================

# Get project data for service account reference
data "google_project" "current" {}

# Generate random Flask SECRET_KEY
resource "random_password" "flask_secret_key" {
  length  = 64
  special = true
}

# Generate random PostgreSQL password
resource "random_password" "postgres_password" {
  length  = 32
  special = false  # Avoid special chars that might cause issues in connection strings
}

# Secret: Flask SECRET_KEY
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

# Secret: PostgreSQL password
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

# IAM: Allow VM service account to access secrets
resource "google_secret_manager_secret_iam_member" "flask_secret_key_access" {
  secret_id = google_secret_manager_secret.flask_secret_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

resource "google_secret_manager_secret_iam_member" "postgres_password_access" {
  secret_id = google_secret_manager_secret.postgres_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}