variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "name" {
  type        = string
  description = "Name of the GKE cluster"
}

variable "location" {
  type        = string
  description = "Location (zone or region) for the cluster"
}

variable "node_locations" {
  type        = list(string)
  description = "List of zones where nodes should be located"
  default     = []
}

variable "network" {
  type        = string
  description = "VPC network name"
}

variable "subnetwork" {
  type        = string
  description = "Subnetwork name"
}

variable "secondary_range_name_pods" {
  type        = string
  description = "Name of secondary IP range for pods"
  default     = "pods"
}

variable "secondary_range_name_services" {
  type        = string
  description = "Name of secondary IP range for services"
  default     = "services"
}

variable "initial_node_count" {
  type        = number
  description = "Initial number of nodes in the default node pool"
  default     = 1
}

variable "remove_default_node_pool" {
  type        = bool
  description = "Remove default node pool"
  default     = true
}

variable "node_pools" {
  type = list(object({
    name               = string
    node_count         = optional(number, 1)
    min_node_count     = optional(number, 1)
    max_node_count     = optional(number, 3)
    machine_type       = optional(string, "e2-medium")
    disk_size_gb       = optional(number, 20)
    disk_type          = optional(string, "pd-standard")
    image_type         = optional(string, "COS_CONTAINERD")
    auto_repair        = optional(bool, true)
    auto_upgrade       = optional(bool, true)
    preemptible        = optional(bool, false)
    spot               = optional(bool, false)
    oauth_scopes       = optional(list(string), ["https://www.googleapis.com/auth/cloud-platform"])
    labels             = optional(map(string), {})
    tags               = optional(list(string), [])
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  description = "List of node pools to create"
  default     = []
}

variable "master_authorized_networks" {
  type = list(object({
    cidr_block   = string
    display_name = optional(string, "")
  }))
  description = "List of master authorized networks"
  default     = []
}

variable "enable_private_nodes" {
  type        = bool
  description = "Enable private nodes"
  default     = true
}

variable "enable_private_endpoint" {
  type        = bool
  description = "Enable private endpoint"
  default     = false
}

variable "master_ipv4_cidr_block" {
  type        = string
  description = "CIDR block for the master network"
  default     = "172.16.0.0/28"
}

variable "enable_network_policy" {
  type        = bool
  description = "Enable network policy addon"
  default     = true
}

variable "enable_http_load_balancing" {
  type        = bool
  description = "Enable HTTP load balancing addon"
  default     = true
}

variable "enable_horizontal_pod_autoscaling" {
  type        = bool
  description = "Enable horizontal pod autoscaling addon"
  default     = true
}

variable "enable_vertical_pod_autoscaling" {
  type        = bool
  description = "Enable vertical pod autoscaling addon"
  default     = false
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
  default     = "latest"
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to the cluster"
  default     = {}
}

variable "resource_labels" {
  type        = map(string)
  description = "Resource labels to apply to the cluster"
  default     = {}
}
