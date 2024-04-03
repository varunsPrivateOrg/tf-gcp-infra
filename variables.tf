variable "region" {
  type    = string
  default = "us-east1"
}

variable "project_id" {
  type    = string
  default = "cloudspring2024-demo"
}

variable "compute_engines" {
  type = list(object({ machine_type = string
    name = string
    zone = string
    boot_disk = object({
      initialize_params = object({
        size = number
        type = string
      })
    })
    network_interface = object({
      subnetwork_project = string
      subnetwork         = string
      access_config = object({
        network_tier = string
      })
    })
    image = object({
      family     = string
      project_id = string
    })
    tags = list(string)
    sql_db_environment_configs = object({
      vpc_network_name         = string
      database_instance_prefix = string
    })
    service_account_id     = string
    service_account_scopes = list(string)
    environment_variables = object({
      pub_topic      = string,
      pub_project_id = string
    })
  }))

}

variable "vpcs" {
  type = list(object({
    vpc_name                            = string
    vpc_auto_create_subnetworks         = bool
    vpc_routing_mode                    = string
    vpc_delete_default_routes_on_create = bool
    subnets = list(object({
      name          = string
      ip_cidr_range = string
    }))
    routes = list(object({
      name             = string
      dest_range       = string
      next_hop_gateway = string
    }))
    firewall = list(object({
      name          = string
      source_ranges = list(string)
      direction     = string
      allow = list(object({
        protocol = string
        ports    = list(string)
      }))
      deny = list(object({
        protocol = string
      }))
      target_tags = list(string)
      priority    = string
    }))
    database_instances = list(object({
      database_instance_config = object({
        name_prefix      = string
        database_version = string
        settings = object({
          tier                        = string
          deletion_protection_enabled = optional(bool)
          availability_type           = optional(string)
          disk_type                   = optional(string)
          disk_size                   = optional(number)
          edition                     = string
          ip_configuration = object({
            ipv4_enabled = optional(bool)
          })
        })
        deletion_protection = optional(bool)
      })
      database_config = object({
        name            = string
        deletion_policy = string
      })
      users_config = object({
        name = string
      })
      database_config = object({
        name            = string
        deletion_policy = string
      })
      users_config = object({
        name = string
      })
      })

    )
    peering_address_range = object({
      name          = string
      address_type  = string
      purpose       = string
      prefix_length = optional(number, 24)
    })

  }))
}

variable "dns_records" {
  type = list(object({
    id               = number
    dns_record_name  = string
    recordType       = string
    ttl              = number
    instance_name    = string
    dns_managed_zone = string
  }))
}


variable "service_accounts" {
  type = list(object({
    project_id                   = string
    service_account_id           = string
    service_account_display_name = string
    roles                        = list(string)
  }))
}


variable "cloud_functions" {

  type = list(object({
    name        = string
    location    = string
    description = string
    build_config = object({
      runtime     = string
      entry_point = string
      source = object({
        storage_source = object({
          bucket = string
          object = string
        })
      })
    })
    service_config = object({
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
    env_variable_configs = object({

      vpc_network_name        = string
      db_instance_name        = string
      direct_sendgrid_api_key = string
      direct_db_port          = string
    })
    event_trigger = object({
      trigger_region       = string
      pub_topic            = string
      event_type           = string
      service_account_name = string
      retry_policy         = optional(string, "RETRY_POLICY_RETRY")
    })
    })
  )
}


variable "topics" {
  type = list(object({
    name                       = string
    message_retention_duration = string
  }))
}


variable "vpc_connectors" {
  type = list(object({
    vpc_connector_name = string
    ip_cidr_range      = string
    network            = string
    max_instances      = number
    min_instances      = number
  }))
}

variable "image_family" {
  type = object({
    family  = string
    project = string
  })
}

variable "instance_template" {
  type = object({
    name                 = string
    description          = string
    tags                 = list(string)
    instance_description = string
    machine_type         = string
    can_ip_forward       = bool
    scheduling = object({
      automatic_restart   = bool
      on_host_maintenance = string
    })
    disk = object({
      auto_delete  = bool
      boot         = bool
      disk_size_gb = number
      disk_type    = string
    })
    network_interface = object({
      subnetwork_project = string
      network            = string
      subnetwork         = string
    })
    service_account = object({
      service_account_id = string
      scopes             = list(string)
    })
    metadata_startup_script_values = object({
      db_name                  = string
      db_username              = string
      db_password              = string
      pub_topic                = string
      pub_project_id           = string
      db_host_vpc_name         = string
      db_host_db_instance_name = string
    })
  })
}


variable "health_check" {
  type = object({
    name                = string
    check_interval_sec  = number
    timeout_sec         = number
    healthy_threshold   = number
    unhealthy_threshold = number
    http_health_check = object({
      request_path = string
      port         = string
    })
  })
}


variable "instance_group_manager" {
  type = object({
    name               = string
    base_instance_name = string
    region             = string
    named_port = object({
      name = string
      port = number
    })
    auto_healing_policies = object({
      initial_delay_sec = number
    })
    instance_lifecycle_policy = object({
      force_update_on_repair = string
    })
  })
}

variable "auto_scaler" {
  type = object({
    name   = string
    region = string
    autoscaling_policy = object({
      max_replicas    = number
      min_replicas    = number
      cooldown_period = number
    })
    cpu_utilization = object({
      target = number
    })
    scale_in_control = object({
      max_scaled_in_replicas = object({
        fixed = number
      })
      time_window_sec = number
    })
  })
}


variable "load_balancer" {
  type = object({
    project = string
    name    = string

    ssl                             = bool
    managed_ssl_certificate_domains = list(string)
    firewall_network_sub            = string
    firewall_projects               = list(string)
    target_tags                     = list(string)
    http_forward                    = bool
    https_redirect                  = bool

    backends = object({
      port        = number
      protocol    = string
      port__name  = string
      timeout_sec = number
      enable_cdn  = bool
      health_check = object({
        request_path = string
        port         = number
      })
      log_config = object({
        enable      = bool
        sample_rate = number
      })
      group_balancing_mode = string
    })
    iap_config = object({
      enable = false
    })
  })
}




