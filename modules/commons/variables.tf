variable "environment" {
  description = "The environment name (dev, staging, production)"
  type        = string
  validation {
    condition = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "additional_labels" {
  description = "Additional labels to merge with default labels"
  type        = map(string)
  default     = {}
}
