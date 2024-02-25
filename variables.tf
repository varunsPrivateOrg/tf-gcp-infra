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
          deletion_protection_enabled = bool
          availability_type           = string
          disk_type                   = string
          disk_size                   = number
          edition                     = string
          ip_configuration = object({
            ipv4_enabled = bool
          })
        })
        deletion_protection = bool
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
    }))

  }))
}
