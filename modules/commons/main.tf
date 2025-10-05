locals {

  # Environment-specific configurations
  environment_configs = {
    dev = {
      name_suffix = "dev"
      project_id  = "saral-458210"
      region      = "asia-south1"
    }
    staging = {
      name_suffix = "staging"
      project_id  = "saral-458210"
      region      = "asia-south1"
    }
    production = {
      name_suffix = "prod"
      project_id  = "saral-458210"
      region      = "asia-south1"
    }
  }

  current_env_config = local.environment_configs[var.environment]

  # Default labels with environment
  default_labels = {
    environment = var.environment
    owner       = "devops"
    managed     = "terraform"
  }

  # Merge default labels with additional labels
  labels = merge(local.default_labels, var.additional_labels)

  # Environment-specific naming
  name_prefix = var.environment
  project_id  = local.environment_configs[var.environment]["project_id"]
  region      = local.environment_configs[var.environment]["region"]
}
