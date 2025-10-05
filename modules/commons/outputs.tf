output "project_id" {
  description = "The GCP project ID"
  value       = local.project_id
}

output "region" {
  description = "The GCP region"
  value       = local.region
}

output "labels" {
  description = "Common labels including environment"
  value       = local.labels
}

output "environment" {
  description = "The current environment"
  value       = var.environment
}

output "name_prefix" {
  description = "Environment-specific name prefix for resources"
  value       = local.name_prefix
}

output "environment_config" {
  description = "Environment-specific configuration settings"
  value       = local.current_env_config
}

