variable "database_instance_config" {
  type = object({
    name_prefix      = string
    database_version = string
    settings = object({
      tier                        = string
      deletion_protection_enabled = optional(bool, false)
      availability_type           = optional(string, "REGIONAL")
      disk_type                   = optional(string, "pd-ssd")
      disk_size                   = optional(number, 100)
      edition                     = string
      ip_configuration = object({
        ipv4_enabled = optional(bool, false)
      })
    })
    deletion_protection = optional(bool)
  })
}


variable "database_config" {
  type = object({
    name            = string
    deletion_policy = string
  })
}

variable "users_config" {
  type = object({
    name = string
  })
}
variable "vpc_reference" {
  type = string
}

variable "encryption_key_name" {
  type = string
}
