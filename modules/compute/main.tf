resource "google_compute_instance" "instance-1" {
  machine_type = var.machine_type
  name         = var.instance_name
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.my_image_datasource.self_link
      size  = var.boot_disk.initialize_params.size
      type  = var.boot_disk.initialize_params.type
    }
  }

  network_interface {
    subnetwork_project = var.network_interface.subnetwork_project
    subnetwork         = var.network_interface.subnetwork
    access_config {
      network_tier = var.network_interface.access_config.network_tier
    }
  }
  tags = var.tags
}

data "google_compute_image" "my_image_datasource" {
  family  = var.image.family
  project = var.image.project_id
}
