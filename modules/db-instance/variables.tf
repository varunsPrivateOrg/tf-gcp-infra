variable "database_instance_config" {
  type = object({
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
