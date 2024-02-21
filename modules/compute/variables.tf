variable "machine_type" {
  type        = string
  description = "type of vm in gcloud"
}

variable "instance_name" {
  type        = string
  description = "name of instance"
}

variable "zone" {
  type        = string
  description = "which zone should the instance be launched"
}

variable "boot_disk" {
  type = object({
    initialize_params = object({
      image = string
      size  = number
      type  = string
    })
  })
}

variable "network_interface" {
  type = object({
    subnetwork_project = string
    subnetwork         = string
    access_config = object({
      network_tier = string
    })
  })
}


variable "image" {
  type = object({
    family     = string
    project_id = string
  })
}
