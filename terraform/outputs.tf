output "instance_name" {
  value = google_compute_instance.music_graph.name
}

output "instance_external_ip" {
  value = google_compute_instance.music_graph.network_interface[0].access_config[0].nat_ip
}

output "ssh_command" {
  value = "gcloud compute ssh ${google_compute_instance.music_graph.name} --zone=${var.zone}"
}