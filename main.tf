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
  family  = "csye6225"
  project = "cloudspring2024-dev-415217"
}

resource "google_compute_region_instance_template" "default" {
  name                 = "weappserver-template"
  description          = "This template is used to create webapp server instances."
  tags                 = ["webapp-instance"]
  instance_description = "description assigned to instances"
  machine_type         = "e2-medium"
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }


  disk {
    source_image = data.google_compute_image.my_image.self_link
    auto_delete  = true
    boot         = true
    disk_size_gb = 40
    disk_type    = "pd-balanced"
  }
  network_interface {
    subnetwork_project = "cloudspring2024-demo-415217"
    network            = "vpc-network"
    subnetwork         = "projects/cloudspring2024-demo-415217/regions/us-east1/subnetworks/webapp"
    # To Do remove public IP
    access_config {

    }

  }
  service_account {
    email  = module.service_accounts["service-account-logging"].service_account_email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<EOF
#!/bin/bash
rm -f /opt/webapp/.env
{
  echo "DB_USERNAME=webapp"
  echo "DB_NAME=webapp"
  echo "DB_PASSWORD=${module.vpcs["vpc-network"].db_instances_configs["db"].db_password}"
  echo "PORT=3000"
  echo "PUB_TOPIC=verify_email"
  echo "PUB_PROJECT_ID=cloudspring2024-demo-415217"
  echo "DB_HOST=${module.vpcs["vpc-network"].db_instances_configs["db"].db_host}"
} > /opt/webapp/.env

echo ".env file has been updated."
EOF
}



resource "google_compute_health_check" "autohealing" {
  name                = "webappserver-health-check"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2 # 50 seconds

  http_health_check {
    request_path = "/healthz"
    port         = "3000"
  }
}


resource "google_compute_region_instance_group_manager" "appserver" {
  name = "webappserver-igm"

  base_instance_name = "webappserver-igm-managed"
  region             = "us-east1"

  version {
    instance_template = google_compute_region_instance_template.default.self_link
  }
  named_port {
    name = "webapp-port"
    port = 3000
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = 300
  }

  instance_lifecycle_policy {
    force_update_on_repair = "YES"
  }
  depends_on = [module.vpcs]

}

resource "google_compute_region_autoscaler" "webappserver_autoscaler" {
  name   = "my-region-webapp-autoscaler"
  region = "us-east1"
  target = google_compute_region_instance_group_manager.appserver.id

  autoscaling_policy {
    max_replicas    = 4
    min_replicas    = 2
    cooldown_period = 150

    cpu_utilization {
      target = 0.1
    }
    scale_in_control {
      max_scaled_in_replicas {
        fixed = 1
      }
      time_window_sec = 60
    }

  }

}


module "gce-lb-http" {
  source  = "GoogleCloudPlatform/lb-http/google"
  version = "~> 9.0"

  project = "cloudspring2024-demo-415217"
  name    = "group-http-lb"

  ssl                             = true
  managed_ssl_certificate_domains = ["varunjayakumar.me"]
  #  this firewall is created for each backend to allow health check on the follieng netowkrs with specified taret tags
  firewall_networks = [module.vpcs["vpc-network"].vpc.self_link]
  firewall_projects = ["cloudspring2024-demo-415217"]
  target_tags       = ["webapp-instance"]
  http_forward      = false
  https_redirect    = false

  backends = {
    default = {
      port        = 3000
      protocol    = "HTTP"
      port_name   = "webapp-port"
      timeout_sec = 10
      enable_cdn  = false

      health_check = {
        request_path = "/healthz"
        port         = 3000
      }

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      groups = [
        {
          group          = google_compute_region_instance_group_manager.appserver.instance_group
          balancing_mode = "UTILIZATION"

        },
      ]
      iap_config = {
        enable = false
      }
    }
  }
}

output "gce-lb-http-output" {
  value     = module.gce-lb-http
  sensitive = true
}


