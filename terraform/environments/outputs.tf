output "instance_name" {
  value = google_compute_instance.music_graph.name
}

output "instance_external_ip" {
  value = google_compute_instance.music_graph.network_interface[0].access_config[0].nat_ip
}

output "ssh_command" {
  value = "gcloud compute ssh ${google_compute_instance.music_graph.name} --zone=${var.zone}"
}

# Secret Manager outputs
output "secret_flask_key_name" {
  description = "Secret Manager secret name for Flask SECRET_KEY"
  value       = google_secret_manager_secret.flask_secret_key.secret_id
}

output "secret_db_password_name" {
  description = "Secret Manager secret name for PostgreSQL password"
  value       = google_secret_manager_secret.postgres_password.secret_id
}

# Cloud SQL outputs
output "cloud_sql_instance_name" {
  description = "Cloud SQL instance name"
  value       = google_sql_database_instance.music_graph.name
}

output "cloud_sql_public_ip" {
  description = "Cloud SQL public IP address"
  value       = google_sql_database_instance.music_graph.public_ip_address
}

output "cloud_sql_connection_name" {
  description = "Cloud SQL connection name (for Cloud SQL Proxy)"
  value       = google_sql_database_instance.music_graph.connection_name
}

# Cloud Run outputs
output "cloud_run_url" {
  description = "Cloud Run service URL"
  value       = google_cloud_run_v2_service.music_graph.uri
}

output "cloud_run_service_name" {
  description = "Cloud Run service name"
  value       = google_cloud_run_v2_service.music_graph.name
}

output "domain_mapping_status" {
  description = "Cloud Run domain mapping resource records (for DNS verification)"
  value       = google_cloud_run_domain_mapping.music_graph.status
}