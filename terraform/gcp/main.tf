terraform {
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
  zone    = var.zone
}

data "google_compute_image" "arch_dev" {
  name    = var.image_name
  project = var.project_id
}

resource "google_compute_instance" "dev" {
  name         = "arch-dev"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.arch_dev.self_link
      size  = var.disk_size_gb
      type  = "pd-ssd"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    user-data = templatefile("${path.module}/../../cloud-init/user-data.yaml.tpl", {
      username        = var.username
      ssh_public_key  = var.ssh_public_key
      ssh_private_key = var.ssh_private_key
      git_user_name   = var.git_user_name
      git_user_email  = var.git_user_email
      api_keys        = var.api_keys
      repos_to_clone  = var.repos_to_clone
    })
  }
}

resource "google_compute_firewall" "ssh" {
  name    = "arch-dev-allow-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["arch-dev"]
}
