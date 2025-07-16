# main.tf
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "nomad_network" {
  name                    = "nomad-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "nomad_subnet" {
  name          = "nomad-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.nomad_network.id
}

resource "google_compute_firewall" "nomad_firewall" {
  name    = "nomad-firewall"
  network = google_compute_network.nomad_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "4646-4666", "3000-3999", "5672", "9090"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "nomad_server" {
  count        = 3
  name         = "nomad-server-${count.index + 1}"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.nomad_network.id
    subnetwork = google_compute_subnetwork.nomad_subnet.name
    access_config {}
  }

  metadata_startup_script = file("startup-scripts/nomad-server.sh")

  tags = ["nomad"]
}

resource "google_compute_instance_template" "nomad_client_template" {
  name         = "nomad-client-template"
  machine_type = "e2-medium"

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = google_compute_network.nomad_network.id
    subnetwork = google_compute_subnetwork.nomad_subnet.name
    access_config {}
  }

  metadata_startup_script = file("startup-scripts/nomad-client.sh")
  tags                    = ["nomad"]
}

resource "google_compute_instance_group_manager" "nomad_clients" {
  name               = "nomad-clients"
  base_instance_name = "nomad-client"
  version {
    instance_template = google_compute_instance_template.nomad_client_template.id
  }
  target_size = 2
  zone        = var.zone
}