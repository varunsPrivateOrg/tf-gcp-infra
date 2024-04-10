/*
This is a module (template) that creates a VPC and subnets within the VPC based on the provided
configurations
*/
resource "google_compute_network" "vpc_network" {
  name                            = var.name
  auto_create_subnetworks         = var.vpc_auto_create_subnetworks
  routing_mode                    = var.vpc_routing_mode
  delete_default_routes_on_create = var.vpc_delete_default_routes_on_create
}

# iterate through the subnet list and create each subnet
resource "google_compute_subnetwork" "subnets" {
  for_each      = { for subnet in toset(var.subnets) : subnet.name => subnet }
  name          = each.value.name
  ip_cidr_range = each.value.ip_cidr_range
  network       = google_compute_network.vpc_network.name
}

# iterate through the routes and create each route
resource "google_compute_route" "routes" {
  for_each         = { for route in toset(var.routes) : route.name => route }
  name             = each.value.name
  dest_range       = each.value.dest_range
  next_hop_gateway = each.value.next_hop_gateway
  network          = google_compute_network.vpc_network.name
}

# resource "google_compute_firewall" "firewall" {
#   name    = "default-firewall"
#   network = google_compute_network.vpc_network.name
#   source_ranges = ["10.0.1.0/24"]
#   allow {
#     protocol = "tcp"
#     ports    = ["3000"]
#   }
#   direction = "INGRESS"
#   source_tags = ["web-subnet"]
# }
resource "google_compute_firewall" "firewall" {
  for_each      = { for firewall in toset(var.firewall) : firewall.name => firewall }
  name          = each.value.name
  network       = google_compute_network.vpc_network.name
  source_ranges = each.value.source_ranges
  direction     = each.value.direction
  dynamic "deny" {
    for_each = each.value.deny
    content {
      protocol = deny.value.protocol
    }
  }
  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }
  priority    = each.value.priority
  target_tags = each.value.target_tags
}


resource "google_compute_global_address" "peering_address_range" {
  name          = var.peering_address_range.name
  address_type  = var.peering_address_range.address_type
  purpose       = var.peering_address_range.purpose
  network       = google_compute_network.vpc_network.id
  prefix_length = var.peering_address_range.prefix_length
}
resource "google_service_networking_connection" "default" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.peering_address_range.name]
  deletion_policy         = "ABANDON"
}


module "database_instance" {
  for_each                 = { for db_instance in toset(var.database_instances) : db_instance.database_instance_config.name_prefix => db_instance }
  source                   = "../db-instance"
  database_instance_config = each.value.database_instance_config
  database_config          = each.value.database_config
  users_config             = each.value.users_config
  vpc_reference            = google_compute_network.vpc_network.id
  depends_on               = [google_service_networking_connection.default]
  encryption_key_name      = var.encryption_key_name
}
