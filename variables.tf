variable "project_id"{
    type = string
    description = "Project ID"
    default = "cloudspring2024-demo"
}

variable "region" {
    type = string 
    description = "Region"
    default = "us-east1"
}

variable "vpc_name" {
  type = string
  description = "name of my vpc"
  default ="cloud-vpc"
}

variable "routing_mode"{
    type=string
    default="REGIONAL"
}

variable "delete_default_routes_on_create"{
    type=bool
    default=true
}

variable "auto_create_subnetworks"{
    type=bool
    default=false
}

variable "subnet_1_name"{
    type=string
    default = "webapp"
}
variable "subnet_1_cider_range" {
    type=string
    default="10.10.10.0/24"
}

variable "subnet_2_cider_range" {
    type=string
    default="10.10.20.0/24"
}
variable "subnet_2_name" {
    type=string 
    default="db"
  
}