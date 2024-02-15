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
    name            = string
    dest_range      = string
    next_hop_gateway = string
  }))
}

variable "vpc_auto_create_subnetworks" {
  type        = bool
  description = "should the subnets be auto created"
}
 
variable "name" {
  type        = string
}

variable "vpc_routing_mode" {
  type        = string
}
 
variable "vpc_delete_default_routes_on_create" {
  type        = bool
  description = "should the defaults routes be deleted"
} 