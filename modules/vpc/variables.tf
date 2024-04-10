variable "subnets" {
  description = "list of subnets to be created"
  type = list(object({
    name          = string
    ip_cidr_range = string
  }))
  default = []
}

variable "routes" {
  description = "list of routes to be created"
  type = list(object({
    name             = string
    dest_range       = string
    next_hop_gateway = string
  }))
}

variable "vpc_auto_create_subnetworks" {
  type        = bool
  description = "should the subnets be auto created"
}

variable "name" {
  type = string
}

variable "vpc_routing_mode" {
  type = string
}

variable "vpc_delete_default_routes_on_create" {
  type        = bool
  description = "should the defaults routes be deleted"
}

variable "firewall" {
  description = "firewall for vpc"
  type = list(object({
    name          = string
    source_ranges = list(string)
    allow = list(object({
      protocol = string
      ports    = list(string)
    }))
    deny = list(object({
      protocol = string
    }))
    direction   = string
    target_tags = list(string)
    priority    = number
  }))
}

variable "database_instances" {
  type = list(object({
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
  }))
}

variable "peering_address_range" {
  type = object({
    name          = string
    address_type  = string
    purpose       = string
    prefix_length = optional(number, 24)
  })
}

variable "encryption_key_name" {
  type = string
}
