output "nomad_server_ips" {
  description = "Lista de IPs públicos dos Nomad Servers"
  value       = [for s in google_compute_instance.nomad_server : s.network_interface[0].access_config[0].nat_ip]
}

output "nomad_client_group" {
  description = "Nome do grupo de instâncias dos Nomad Clients"
  value       = google_compute_instance_group_manager.nomad_clients.name
}