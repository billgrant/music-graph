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

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  metadata_startup_script = file("${path.module}/startup-script.sh")

  labels = {
    environment = var.environment
    app         = "music-graph"
  }
}

# Firewall rule for HTTP
resource "google_compute_firewall" "http" {
  name    = "allow-http-${var.environment}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = var.allowed_ips
  target_tags   = ["http-server"]
}

# Firewall rule for HTTPS
resource "google_compute_firewall" "https" {
  name    = "allow-https-${var.environment}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = var.allowed_ips
  target_tags   = ["https-server"]
}

# Firewall rule for SSH (restricted to your IP)
resource "google_compute_firewall" "ssh" {
  name    = "allow-ssh-${var.environment}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ips
  target_tags   = ["music-graph-${var.environment}"]
}