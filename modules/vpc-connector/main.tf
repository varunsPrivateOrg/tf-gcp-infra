resource "google_vpc_access_connector" "connector" {
  name          = var.vpc_connector_name
  ip_cidr_range = var.ip_cidr_range
  network       = var.network
  max_instances = var.max_instances
  min_instances = var.min_instances
  #   depends_on    = [module.vpcs]
}
