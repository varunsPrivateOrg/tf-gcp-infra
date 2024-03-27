resource "google_cloudfunctions2_function" "function" {
  name        = var.name
  location    = var.location
  description = var.description
  build_config {
    runtime     = var.build_config.runtime
    entry_point = var.build_config.entry_point
    source {
      storage_source {
        bucket = var.build_config.source.storage_source.bucket
        object = var.build_config.source.storage_source.object
      }
    }
  }
  service_config {
    max_instance_count               = var.service_config.max_instance_count
    min_instance_count               = var.service_config.min_instance_count
    available_memory                 = var.service_config.available_memory
    timeout_seconds                  = var.service_config.timeout_seconds
    max_instance_request_concurrency = var.service_config.max_instance_request_concurrency
    available_cpu                    = var.service_config.available_cpu
    ingress_settings                 = var.service_config.ingress_settings
    all_traffic_on_latest_revision   = var.service_config.all_traffic_on_latest_revision
    service_account_email            = var.service_accounts[var.service_config.service_account_name].service_account_email
    vpc_connector                    = var.vpc_connectors[var.service_config.vpc_connector_name].connector_id
    vpc_connector_egress_settings    = var.service_config.vpc_connector_egress_settings
    environment_variables = {
      DB_NAME          = var.vpcs[var.env_variable_configs.vpc_network_name].db_instances_configs[var.env_variable_configs.db_instance_name].db_name,
      DB_HOST          = var.vpcs[var.env_variable_configs.vpc_network_name].db_instances_configs[var.env_variable_configs.db_instance_name].db_host
      DB_PASSWORD      = var.vpcs[var.env_variable_configs.vpc_network_name].db_instances_configs[var.env_variable_configs.db_instance_name].db_password
      DB_PORT          = var.env_variable_configs.direct_db_port
      SENDGRID_API_KEY = var.env_variable_configs.direct_sendgrid_api_key
      DB_USER          = var.vpcs[var.env_variable_configs.vpc_network_name].db_instances_configs[var.env_variable_configs.db_instance_name].db_username
    }
  }

  event_trigger {
    trigger_region        = var.event_trigger.trigger_region
    event_type            = var.event_trigger.event_type
    pubsub_topic          = var.topics[var.event_trigger.pub_topic].topic_id
    service_account_email = var.service_accounts[var.event_trigger.service_account_name].service_account_email
    retry_policy          = var.event_trigger.retry_policy
  }
}


