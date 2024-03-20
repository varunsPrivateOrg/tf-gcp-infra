variable "service_account_id" {
  type = string
}

variable "service_account_display_name" {
  type = string
}

variable "project_id" {
  type = string
}

# variable "role-1" {
#   type = string
# }

# variable "role-2" {
#   type = string
# }

variable "roles" {
  type = list(string)
}
