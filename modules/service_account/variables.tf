variable "environment" {
  description = "The environment name (dev, staging, production)"
  type        = string
  default     = null
  validation {
    condition     = var.environment == null || contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "service_accounts" {
  description = "List of service accounts to create with their configurations"
  type = list(object({
    account_id   = string
    display_name = optional(string)
    description  = optional(string, "Service account created by Terraform")

    # Key configuration
    create_key       = optional(bool, false)
    key_algorithm    = optional(string)
    private_key_type = optional(string)

    # IAM roles and bindings
    project_roles = optional(list(string), [])
    custom_iam_bindings = optional(map(object({
      members = list(string)
      condition = optional(object({
        title       = string
        description = string
        expression  = string
      }))
    })), {})

    # Workload Identity
    workload_identity_bindings = optional(map(object({
      namespace = string
      ksa_name  = string
    })), {})

    # Impersonation
    enable_impersonation    = optional(bool, false)
    impersonation_delegates = optional(list(string), [])

    # Labels and tags
    labels = optional(map(string), {})
    tags   = optional(list(string), [])
  }))

  validation {
    condition = alltrue([
      for sa in var.service_accounts : can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", sa.account_id))
    ])
    error_message = "All service account IDs must be 6-30 characters, start with lowercase letter, contain only lowercase letters, numbers, and hyphens."
  }
}

variable "global_labels" {
  type        = map(string)
  description = "Global labels to apply to all service accounts (usually from commons module)"
  default     = {}
}
