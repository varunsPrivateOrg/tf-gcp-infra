# ToDo: enable APIs in the project and link the project with a billing account
# ToDo: specify a variable for region, project name, provider, subnet, subnet names (nothing wrong in hardcoding it initially)

# ToDo: screate two subnets with some mask (make sure to delete the default routes that are created)

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.15.0"
    }
  }
}

provider "google" {
    project     = var.project_id
    region      = var.region
}

# ToDo: create a VPC
resource "google_compute_network" "this" {
    name = var.vpc_name
    delete_default_routes_on_create = true
    auto_create_subnetworks = false
    routing_mode = var.routing_mode
}

resource "google_compute_subnetwork" "webapp" {
name=var.subnet_1_name
ip_cidr_range= var.subnet_1_cider_range
region=var.region
network=google_compute_network.this.id
}


resource "google_compute_subnetwork" "db" {
name=var.subnet_2_name
ip_cidr_range= var.subnet_2_cider_range
region=var.region
network=google_compute_network.this.id
}