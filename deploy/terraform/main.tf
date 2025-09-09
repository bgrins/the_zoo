terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  default     = "us-central1-a"
}

variable "instance_name" {
  description = "Name for the Zoo instance"
  default     = "the-zoo"
}

variable "machine_type" {
  description = "GCP machine type"
  default     = "e2-standard-2"
}

variable "github_repo" {
  description = "GitHub repository URL for The Zoo"
  type        = string
}

variable "github_branch" {
  description = "Git branch to deploy"
  default     = "main"
}

variable "allowed_ips" {
  description = "List of IPs allowed to access the proxy (use 0.0.0.0/0 for all)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_firewall" "zoo_proxy" {
  name    = "${var.instance_name}-proxy"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["3128"]
  }

  source_ranges = var.allowed_ips
  target_tags   = ["zoo-proxy"]
}

resource "google_compute_instance" "zoo" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30
      type  = "pd-ssd"
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }

  tags = ["zoo-proxy"]

  metadata = {
    user-data = templatefile("${path.module}/cloud-init.yaml", {
      github_repo   = var.github_repo
      github_branch = var.github_branch
    })
  }

  metadata_startup_script = file("${path.module}/startup.sh")
}

output "instance_ip" {
  value = google_compute_instance.zoo.network_interface[0].access_config[0].nat_ip
}

output "proxy_url" {
  value = "http://${google_compute_instance.zoo.network_interface[0].access_config[0].nat_ip}:3128"
}