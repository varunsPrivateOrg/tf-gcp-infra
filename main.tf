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


resource "google_pubsub_topic" "email-verification" {
  name                       = "email-verification-topic"
  message_retention_duration = "604800s"
}


resource "google_vpc_access_connector" "connector" {
  name          = "vpc-connector"
  ip_cidr_range = "10.0.3.0/28"
  network       = "vpc-network"
  max_instances = 3
  min_instances = 2
  depends_on    = [module.vpcs]
}


resource "google_cloudfunctions2_function" "function" {
  name        = "gcf-function"
  location    = "us-east1"
  description = "This is a function to send out emails"
  build_config {
    runtime     = "nodejs16"
    entry_point = "sendEmail"
    source {
      storage_source {
        bucket = "csye6225-demo-gcf-source"
        object = "serverless.zip"
      }
    }
  }
  service_config {
    max_instance_count               = 1
    min_instance_count               = 1
    available_memory                 = "4Gi"
    timeout_seconds                  = 60
    max_instance_request_concurrency = 2
    available_cpu                    = "1"
    ingress_settings                 = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision   = true
    service_account_email            = module.service_accounts["service-account-cloudfunctions"].service_account_email
    vpc_connector                    = google_vpc_access_connector.connector.id
    vpc_connector_egress_settings    = "PRIVATE_RANGES_ONLY"
    environment_variables = {
      DB_NAME          = module.vpcs["vpc-network"].db_instances_configs["db"].db_name,
      DB_HOST          = module.vpcs["vpc-network"].db_instances_configs["db"].db_host
      DB_PASSWORD      = module.vpcs["vpc-network"].db_instances_configs["db"].db_password
      DB_PORT          = "5432"
      SENDGRID_API_KEY = "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"
      TOKEN_SECRET_KEY = "somethingRandom"
      DB_USER          = module.vpcs["vpc-network"].db_instances_configs["db"].db_username
    }
  }

  event_trigger {
    trigger_region        = "us-east1"
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = google_pubsub_topic.email-verification.id
    service_account_email = module.service_accounts["service-account-pub-sub"].service_account_email
    retry_policy          = "RETRY_POLICY_RETRY"
  }
  depends_on = [google_vpc_access_connector.connector]
}

# resource "google_service_account" "cloud_function" {
#   account_id   = "gcf-sa"
#   display_name = "cloud-function-service-account"
# }


# resource "google_service_account" "pub_sub" {
#   account_id   = "pub-sub-sa"
#   display_name = "pub-sub-service-account"
# }

# resource "google_project_iam_binding" "token-role1" {
#   project = var.project_id
#   role    = "roles/iam.serviceAccountTokenCreator"
#   members = [
#     "serviceAccount:${google_service_account.pub_sub.email}"
#   ]
# }

# resource "google_project_iam_binding" "token-role2" {
#   project = var.project_id
#   role    = "roles/run.invoker"
#   members = [
#     "serviceAccount:${google_service_account.pub_sub.email}"
#   ]
# }
