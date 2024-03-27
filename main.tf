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

module "service_accounts" {
  source                       = "./modules/service-account"
  for_each                     = { for service_account in toset(var.service_accounts) : service_account.service_account_id => service_account }
  project_id                   = each.value.project_id
  service_account_id           = each.value.service_account_id
  service_account_display_name = each.value.service_account_display_name
  roles                        = each.value.roles
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
  service_account_email      = module.service_accounts[each.value.service_account_id].service_account_email
  service_account_scopes     = each.value.service_account_scopes
  environment_variables      = each.value.environment_variables
}


output "vpcs_with_db_instance" {
  value     = module.vpcs
  sensitive = true
}

output "compute_instance_public_ips" {
  value     = module.compute_engines
  sensitive = false
}

output "service_account_emails" {
  value     = module.service_accounts
  sensitive = false
}

output "topics" {
  value     = module.topics
  sensitive = false
}

output "vcp_connectors" {
  value     = module.vpc_connectors
  sensitive = false

}

module "dns_records" {
  source           = "./modules/dns-record"
  for_each         = { for dns_record in toset(var.dns_records) : dns_record.id => dns_record }
  publicIps        = module.compute_engines
  dns_record_name  = each.value.dns_record_name
  recordType       = each.value.recordType
  ttl              = each.value.ttl
  instance_name    = each.value.instance_name
  dns_managed_zone = each.value.dns_managed_zone
}

module "topics" {
  source                     = "./modules/topics"
  for_each                   = { for topic in toset(var.topics) : topic.name => topic }
  name                       = each.value.name
  message_retention_duration = each.value.message_retention_duration
}

module "vpc_connectors" {
  source             = "./modules/vpc-connector"
  for_each           = { for vpc_connector in toset(var.vpc_connectors) : vpc_connector.vpc_connector_name => vpc_connector }
  vpc_connector_name = each.value.vpc_connector_name
  ip_cidr_range      = each.value.ip_cidr_range
  network            = each.value.network
  min_instances      = each.value.min_instances
  max_instances      = each.value.max_instances
  depends_on         = [module.vpcs]
}

module "cloud_functions" {
  source               = "./modules/cloud-function"
  for_each             = { for cloud_function in toset(var.cloud_functions) : cloud_function.name => cloud_function }
  name                 = each.value.name
  location             = each.value.location
  description          = each.value.description
  build_config         = each.value.build_config
  service_config       = each.value.service_config
  env_variable_configs = each.value.env_variable_configs
  event_trigger        = each.value.event_trigger
  vpcs                 = module.vpcs
  service_accounts     = module.service_accounts
  topics               = module.topics
  vpc_connectors       = module.vpc_connectors
  depends_on           = [module.vpc_connectors]
}

