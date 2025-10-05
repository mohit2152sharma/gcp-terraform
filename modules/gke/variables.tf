variable "environment" {
  description = "The environment name (dev, staging, production)"
  type        = string
  validation {
    condition = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

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

# Logging and Monitoring Variables
variable "logging_components" {
  type        = list(string)
  description = "List of logging components to enable. Options: SYSTEM_COMPONENTS, WORKLOADS, APISERVER"
  default     = null
  validation {
    condition = var.logging_components == null || can([
      for component in var.logging_components : contains(["SYSTEM_COMPONENTS", "WORKLOADS", "APISERVER"], component)
    ])
    error_message = "Logging components must be one of: SYSTEM_COMPONENTS, WORKLOADS, APISERVER."
  }
}

variable "monitoring_components" {
  type        = list(string)
  description = "List of monitoring components to enable. Options: SYSTEM_COMPONENTS, WORKLOADS, DAEMONSET"
  default     = null
  validation {
    condition = var.monitoring_components == null || can([
      for component in var.monitoring_components : contains(["SYSTEM_COMPONENTS", "WORKLOADS", "DAEMONSET"], component)
    ])
    error_message = "Monitoring components must be one of: SYSTEM_COMPONENTS, WORKLOADS, DAEMONSET."
  }
}

variable "enable_managed_prometheus" {
  type        = bool
  description = "Enable managed Prometheus for monitoring"
  default     = null
}

# Note: GKE Backup for Applications and Config Connector 
# are not supported in all Google provider versions
# They should be managed separately if needed



# Workload Identity - Workload Service Account and Mapping
# Workload Identity - Workload Service Account and Mapping
variable "create_workload_identity_sa" {
  type        = bool
  description = "Create a Google service account for workloads and bind it to a Kubernetes service account via Workload Identity"
  default     = true
}

variable "workload_gsa_name" {
  type        = string
  description = "Account ID (name) for the Google service account used by workloads"
  default     = "gke-workload"
}

variable "workload_gsa_display_name" {
  type        = string
  description = "Optional display name for the workload Google service account"
  default     = null
}

variable "workload_gsa_description" {
  type        = string
  description = "Description for the workload Google service account"
  default     = "GKE Workload Identity service account for accessing Google APIs"
}

variable "workload_sa_roles" {
  type        = list(string)
  description = "Project roles to grant to the workload Google service account"
  default     = [
    "roles/secretmanager.secretAccessor",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter"
  ]
}

variable "workload_k8s_service_account_name" {
  type        = string
  description = "Kubernetes service account name to map to the Google service account"
  default     = "workload"
}

variable "workload_k8s_service_account_namespace" {
  type        = string
  description = "Kubernetes namespace for the service account mapping"
  default     = "default"
}

variable "create_k8s_service_account" {
  type        = bool
  description = "Whether to create the Kubernetes service account with the proper Workload Identity annotation (requires configured kubernetes provider)"
  default     = false
}

# Workload Identity - Multiple namespace mappings
variable "workload_identity_mappings" {
  description = "List of Workload Identity mappings to create across namespaces. When non-empty, single-mapping variables are ignored."
  type = list(object({
    namespace        = string
    ksa_name         = string
    create_gsa       = optional(bool, true)
    gsa_name         = optional(string)         # Account ID without domain; if null, a default is derived
    gsa_display_name = optional(string)
    gsa_description  = optional(string)
    roles            = optional(list(string), [
      "roles/secretmanager.secretAccessor",
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter"
    ])
    create_ksa       = optional(bool, false)
  }))
  default = []
}
