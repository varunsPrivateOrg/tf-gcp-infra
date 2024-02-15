variable "region" {
  type        = string
  default = "us-east1"
}
 
variable "project_id" {
  type        = string
  default = "cloudspring2024-demo"
}
 
variable "vpcs" {
  type = list(object({
    vpc_name = string
    vpc_auto_create_subnetworks = bool
    vpc_routing_mode = string
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
  }))
}