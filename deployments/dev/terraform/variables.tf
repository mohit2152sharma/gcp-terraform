variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  default     = "dev"
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace for applications"
  default     = "default"
}

variable "domain_name" {
  type        = string
  description = "Domain name for ingress"
  default     = ""
}

variable "enable_nginx_ingress" {
  type        = bool
  description = "Enable NGINX Ingress Controller"
  default     = true
}

variable "enable_cert_manager" {
  type        = bool
  description = "Enable cert-manager for SSL certificates"
  default     = true
}

variable "services" {
  type = map(object({
    enabled     = bool
    image       = string
    tag         = string
    replicas    = number
    port        = number
    target_port = number
    paths       = list(string)
    hosts       = list(string)
    resources = object({
      requests = object({
        cpu    = string
        memory = string
      })
      limits = object({
        cpu    = string
        memory = string
      })
    })
    autoscaling = object({
      enabled                        = bool
      min_replicas                   = number
      max_replicas                   = number
      target_cpu_utilization         = number
      target_memory_utilization      = number
    })
    env_vars       = map(string)
    config_maps    = map(string)
    secrets        = map(string)
    health_check_path = string
  }))
  description = "Map of services to deploy"
  default     = {}
}


