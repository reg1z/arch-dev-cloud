output "external_ip" {
  description = "External IP address of the dev VM"
  value       = google_compute_instance.dev.network_interface[0].access_config[0].nat_ip
}
