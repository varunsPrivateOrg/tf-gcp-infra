variable "dns_record_name" {
  type        = string
  description = "record name with trailing ."
}

variable "recordType" {
  type = string
}

variable "ttl" {
  type    = number
  default = 300
}

variable "publicIps" {
  type = any
}
variable "instance_name" {
  type = string
}

variable "dns_managed_zone" {
  type = string
}
