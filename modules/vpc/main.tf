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
  name          = "global-psconnect-ip"
  address_type  = "INTERNAL"
  purpose       = "VPC_PEERING"
  network       = google_compute_network.vpc_network.id
  prefix_length = 24
}
resource "google_service_networking_connection" "default" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.peering_address_range.name]
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "default" {
  name             = "db-${random_id.db_name_suffix.hex}"
  database_version = "POSTGRES_15"
  region           = "us-east1"

  settings {
    tier                        = "db-f1-micro"
    deletion_protection_enabled = false
    availability_type           = "REGIONAL"
    disk_type                   = "PD_SSD"
    disk_size                   = 100
    edition                     = "ENTERPRISE"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc_network.id
    }
  }
  deletion_protection = false
  depends_on          = [google_service_networking_connection.default]

}

resource "google_sql_database" "database_deletion_policy" {
  name            = "webapp"
  instance        = google_sql_database_instance.default.name
  deletion_policy = "DELETE"
}

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"

}

resource "google_sql_user" "users" {
  name     = "webapp"
  instance = google_sql_database_instance.default.name
  password = random_password.db_password.result
}
