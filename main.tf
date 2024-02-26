module "vpcs" {
  source                              = "./modules/vpc"
  for_each                            = { for vpc in toset(var.vpcs) : vpc.vpc_name => vpc }
  routes                              = each.value.routes
  vpc_delete_default_routes_on_create = each.value.vpc_delete_default_routes_on_create
  vpc_auto_create_subnetworks         = each.value.vpc_auto_create_subnetworks
  name                                = each.value.vpc_name
  vpc_routing_mode                    = each.value.vpc_routing_mode
  subnets                             = each.value.subnets
  firewall                            = each.value.firewall
  database_instances                  = each.value.database_instances
  peering_address_range               = each.value.peering_address_range

}

module "compute_engines" {
  source                     = "./modules/compute"
  for_each                   = { for compute in toset(var.compute_engines) : compute.name => compute }
  machine_type               = each.value.machine_type
  instance_name              = each.value.name
  boot_disk                  = each.value.boot_disk
  network_interface          = each.value.network_interface
  zone                       = each.value.zone
  image                      = each.value.image
  tags                       = each.value.tags
  sql_db_environment_configs = each.value.sql_db_environment_configs
  vpcs_with_db_instance      = module.vpcs
  depends_on                 = [module.vpcs]
}


output "vpcs_with_db_instance" {
  value     = module.vpcs
  sensitive = true
}
