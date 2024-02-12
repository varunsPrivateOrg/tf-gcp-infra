# create a VPC
resource "google_compute_network" "vpc" {
    name = var.vpc_name
    delete_default_routes_on_create = true
    auto_create_subnetworks = false
    routing_mode = var.routing_mode
}

# create a Subnet 1
resource "google_compute_subnetwork" "subnet_1" {
name=var.subnet_1_name
ip_cidr_range= var.subnet_1_cider_range
region=var.region
network=google_compute_network.vpc.id
}

# create a Subnet 2
resource "google_compute_subnetwork" "subnet_2" {
name=var.subnet_2_name
ip_cidr_range= var.subnet_2_cider_range
region=var.region
network=google_compute_network.vpc.id
}