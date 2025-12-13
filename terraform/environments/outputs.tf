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