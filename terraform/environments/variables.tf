variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-east1-b"
}

variable "environment" {
  description = "Environment name (prod, dev, staging)"
  type        = string
  default     = "prod"
}

variable "machine_type" {
  description = "GCP machine type"
  type        = string
  default     = "e2-micro"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 10
}

variable "ssh_user" {
  description = "SSH username"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "allowed_web_ips" {
  description = "List of allowed IP addresses for HTTP/HTTPS traffic"
  type        = list(string)
}

variable "allowed_ssh_ips" {
  description = "List of allowed IP addresses for SSH access"
  type        = list(string)
}

variable "use_cloud_run" {
  description = "Use Cloud Run (true) or VM (false) for DNS routing"
  type        = bool
  default     = false
}