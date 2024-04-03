output "db_instances_configs" {
  value = module.database_instance
}

output "vpc" {
  value = google_compute_network.vpc_network
}
