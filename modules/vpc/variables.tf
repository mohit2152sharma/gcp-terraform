variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "name" {
  type        = string
  description = "Name of the VPC"
}

variable "auto_create_subnetworks" {
  type        = bool
  default     = false
  description = "Whether to auto create subnetworks (set to false for custom mode)"
}

variable "routing_mode" {
  type        = string
  default     = "REGIONAL"
  description = "Routing mode: REGIONAL or GLOBAL"
}

variable "subnets" {
  description = "List of subnets to create"
  type = list(object({
    name          = string
    ip_cidr_range = string
    region        = string
    secondary_ip_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })), [])
  }))
  default = []
}
