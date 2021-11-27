#=================================VPC================================
variable "gcp_vpc_name" {
  description = "The name of created vpc"
  type = string
  default = "vpc"
}


variable "auto_create_subnetworks" {
  description = "It will create a subnet for each region automatically across the across CIDR-block range, if it is <true> "
  type = bool
  default = false
}

variable "routing_mode" {
  description = "The network routing mode"
  type = string
  default = "REGIONAL"
}

variable "delete_default_routes_on_create" {
  type = bool
  default = true
}


#============================SUBNETS==================================
variable "region" {
  description = "The region where resource will be created"
  type = string
  default = "us-central1"
}

variable "subnets" {
  type = list(map(string))
}

#=========================

# variable "network_name" {
#   description = "The name of the network where routes will be created"
# }

variable "routes" {
  type        = list(map(string))
  description = "List of routes being created in this VPC"
  default     = []
}

variable "module_depends_on" {
  description = "List of modules or resources this module depends on."
  type        = list(any)
  default     = []
}


#===========================FIREWALL_RULES============================

variable "firewall_rules" {
  description = "List of custom rule definitions (refer to variables file for syntax)."
  default     = []
  type = list(object({
    name                    = string
    direction               = string
    ranges                  = list(string)
    source_tags             = list(string)
    target_tags             = list(string)
    allow = list(object({
      protocol = string
      ports    = list(string)
    }))
    deny = list(object({
      protocol = string
      ports    = list(string)
    }))
  }))
}