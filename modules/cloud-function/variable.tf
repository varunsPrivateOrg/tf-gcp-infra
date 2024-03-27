variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "description" {
  type    = string
  default = "This is a cloud function"
}

variable "build_config" {
  type = object({
    runtime     = string
    entry_point = string
    source = object({
      storage_source = object({
        bucket = string
        object = string
      })
    })
  })
}

variable "service_config" {
  type = object({
    max_instance_count               = optional(number, 1)
    min_instance_count               = optional(number, 1)
    available_memory                 = optional(string, "4Gi")
    timeout_seconds                  = optional(number, 60)
    max_instance_request_concurrency = optional(number, 2)
    available_cpu                    = optional(string, "1")
    ingress_settings                 = optional(string, "ALLOW_INTERNAL_ONLY")
    all_traffic_on_latest_revision   = optional(bool, true)
    service_account_name             = string
    vpc_connector_name               = string
    vpc_connector_egress_settings    = string
  })
}

variable "env_variable_configs" {
  type = object({
    vpc_network_name        = string
    db_instance_name        = string
    direct_sendgrid_api_key = string
    direct_db_port          = string
  })
}

variable "event_trigger" {
  type = object({
    trigger_region       = string
    event_type           = string
    service_account_name = string
    retry_policy         = optional(string, "RETRY_POLICY_RETRY")
  })
}

variable "topics" {
  type = any
}

variable "vpcs" {
  type = any
}

variable "service_accounts" {
  type = any
}

variable "vpc_connectors" {
  type = any
}
