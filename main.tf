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
# module "compute_engines" {
#   source                     = "./modules/compute"
#   for_each                   = { for compute in toset(var.compute_engines) : compute.name => compute }
#   machine_type               = each.value.machine_type
#   instance_name              = each.value.name
#   boot_disk                  = each.value.boot_disk
#   network_interface          = each.value.network_interface
#   zone                       = each.value.zone
#   image                      = each.value.image
#   tags                       = each.value.tags
#   sql_db_environment_configs = each.value.sql_db_environment_configs
#   vpcs_with_db_instance      = module.vpcs
#   depends_on                 = [module.vpcs]
#   service_account_email      = module.service_accounts[each.value.service_account_id].service_account_email
#   service_account_scopes     = each.value.service_account_scopes
#   environment_variables      = each.value.environment_variables
# }

# output "compute_instance_public_ips" {
#   value     = module.compute_engines
#   sensitive = false
# }
output "vpcs_with_db_instance" {
  value     = module.vpcs
  sensitive = true
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

module "dns_records" {
  source           = "./modules/dns-record"
  for_each         = { for dns_record in toset(var.dns_records) : dns_record.id => dns_record }
  publicIps        = [module.gce-lb-http.external_ip]
  dns_record_name  = each.value.dns_record_name
  recordType       = each.value.recordType
  ttl              = each.value.ttl
  instance_name    = each.value.instance_name
  dns_managed_zone = each.value.dns_managed_zone
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


data "google_compute_image" "my_image" {
  family  = var.image_family.family
  project = var.image_family.project
}

resource "google_compute_region_instance_template" "default" {
  name                 = var.instance_template.name
  description          = var.instance_template.description
  tags                 = var.instance_template.tags
  instance_description = var.instance_template.instance_description
  machine_type         = var.instance_template.machine_type
  can_ip_forward       = var.instance_template.can_ip_forward

  scheduling {
    automatic_restart   = var.instance_template.scheduling.automatic_restart
    on_host_maintenance = var.instance_template.scheduling.on_host_maintenance
  }


  disk {
    source_image = data.google_compute_image.my_image.self_link
    auto_delete  = var.instance_template.disk.auto_delete
    boot         = var.instance_template.disk.boot
    disk_size_gb = var.instance_template.disk.disk_size_gb
    disk_type    = var.instance_template.disk.disk_type
  }
  network_interface {
    subnetwork_project = var.instance_template.network_interface.subnetwork_project
    network            = var.instance_template.network_interface.network
    subnetwork         = var.instance_template.network_interface.subnetwork
    access_config {

    }

  }
  service_account {
    email  = module.service_accounts["${var.instance_template.service_account.service_account_id}"].service_account_email
    scopes = var.instance_template.service_account.scopes
  }

  metadata_startup_script = <<EOF
#!/bin/bash
rm -f /opt/webapp/.env
{
  echo "DB_USERNAME=webapp"
  echo "DB_NAME=webapp"
  echo "DB_PASSWORD=${module.vpcs["${var.instance_template.metadata_startup_script_values.db_host_vpc_name}"].db_instances_configs["${var.instance_template.metadata_startup_script_values.db_host_db_instance_name}"].db_password}"
  echo "PORT=3000"
  echo "PUB_TOPIC=${var.instance_template.metadata_startup_script_values.pub_topic}"
  echo "PUB_PROJECT_ID=${var.instance_template.metadata_startup_script_values.pub_project_id}"
  echo "DB_HOST=${module.vpcs["${var.instance_template.metadata_startup_script_values.db_host_vpc_name}"].db_instances_configs["${var.instance_template.metadata_startup_script_values.db_host_db_instance_name}"].db_host}"
} > /opt/webapp/.env

echo ".env file has been updated."
EOF
}



resource "google_compute_health_check" "autohealing" {
  name                = var.health_check.name
  check_interval_sec  = var.health_check.check_interval_sec
  timeout_sec         = var.health_check.timeout_sec
  healthy_threshold   = var.health_check.healthy_threshold
  unhealthy_threshold = var.health_check.unhealthy_threshold

  http_health_check {
    request_path = var.health_check.http_health_check.request_path
    port         = var.health_check.http_health_check.port
  }
}


resource "google_compute_region_instance_group_manager" "appserver" {
  name = var.instance_group_manager.name

  base_instance_name = var.instance_group_manager.base_instance_name
  region             = var.instance_group_manager.region

  version {
    instance_template = google_compute_region_instance_template.default.self_link
  }
  named_port {
    name = var.instance_group_manager.named_port.name
    port = var.instance_group_manager.named_port.port
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = var.instance_group_manager.auto_healing_policies.initial_delay_sec
  }

  instance_lifecycle_policy {
    force_update_on_repair = var.instance_group_manager.instance_lifecycle_policy.force_update_on_repair
  }
  depends_on = [module.vpcs]

}

resource "google_compute_region_autoscaler" "webappserver_autoscaler" {
  name   = var.auto_scaler.name
  region = var.auto_scaler.region
  target = google_compute_region_instance_group_manager.appserver.id

  autoscaling_policy {
    max_replicas    = var.auto_scaler.autoscaling_policy.max_replicas
    min_replicas    = var.auto_scaler.autoscaling_policy.min_replicas
    cooldown_period = var.auto_scaler.autoscaling_policy.cooldown_period

    cpu_utilization {
      target = var.auto_scaler.cpu_utilization.target
    }
    scale_in_control {
      max_scaled_in_replicas {
        fixed = var.auto_scaler.scale_in_control.max_scaled_in_replicas.fixed
      }
      time_window_sec = var.auto_scaler.scale_in_control.time_window_sec
    }

  }

}


module "gce-lb-http" {
  source  = "GoogleCloudPlatform/lb-http/google"
  version = "~> 9.0"

  project                         = var.load_balancer.project
  name                            = var.load_balancer.name
  ssl                             = var.load_balancer.ssl
  managed_ssl_certificate_domains = var.load_balancer.managed_ssl_certificate_domains
  firewall_projects               = var.load_balancer.firewall_projects
  target_tags                     = var.load_balancer.target_tags
  http_forward                    = var.load_balancer.http_forward
  https_redirect                  = var.load_balancer.https_redirect

  #  this firewall is created for each backend to allow health check on the follieng netowkrs with specified taret tags
  firewall_networks = [module.vpcs["${var.load_balancer.firewall_network_sub}"].vpc.self_link]


  backends = {
    default = {
      port        = var.load_balancer.backends.port
      protocol    = var.load_balancer.backends.protocol
      port_name   = var.load_balancer.backends.port_name
      timeout_sec = var.load_balancer.backends.timeout_sec
      enable_cdn  = var.load_balancer.backends.enable_cdn

      health_check = {
        request_path = var.load_balancer.backends.health_check.request_path
        port         = 3000
      }

      log_config = {
        enable      = var.load_balancer.backends.log_config.enable
        sample_rate = var.load_balancer.backends.log_config.sample_rate
      }

      groups = [
        {
          group          = google_compute_region_instance_group_manager.appserver.instance_group
          balancing_mode = var.load_balancer.backends.group_balancing_mode
        },
      ]
      iap_config = {
        enable = var.load_balancer.iap_config.enable
      }
    }
  }
}

output "gce-lb-http-output" {
  value     = module.gce-lb-http
  sensitive = true
}


