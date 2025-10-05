# Commons Module Outputs
output "project_id" {
  description = "The GCP project ID"
  value       = module.globals.project_id
}

output "region" {
  description = "The GCP region"
  value       = module.globals.region
}

output "environment" {
  description = "The current environment"
  value       = module.globals.environment
}

# VPC Outputs
output "vpc_network_name" {
  description = "The name of the VPC network"
  value       = module.vpc.vpc_network_name
}

output "vpc_network_id" {
  description = "The ID of the VPC network"
  value       = module.vpc.vpc_network_id
}

output "vpc_network_self_link" {
  description = "The self-link of the VPC network"
  value       = module.vpc.vpc_network_self_link
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value       = module.vpc.subnet_ids
}

output "subnet_self_links" {
  description = "Map of subnet names to their self-links"
  value       = module.vpc.subnet_self_links
}

output "subnet_ip_cidr_ranges" {
  description = "Map of subnet names to their CIDR ranges"
  value       = module.vpc.subnet_ip_cidr_ranges
}

output "subnet_secondary_ranges" {
  description = "Map of subnet names to their secondary IP ranges"
  value       = module.vpc.subnet_secondary_ranges
}

# GCR Outputs
output "gcr_repositories" {
  description = "List of created GCR repositories"
  value       = module.gcr
}

# GKE Cluster Outputs
output "gke_cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "gke_cluster_location" {
  description = "The location of the GKE cluster"
  value       = module.gke.cluster_location
}

output "gke_cluster_zones" {
  description = "The zones of the GKE cluster"
  value       = module.gke.cluster_zones
}

output "gke_cluster_master_version" {
  description = "The master Kubernetes version of the GKE cluster"
  value       = module.gke.cluster_master_version
}

output "gke_node_pools" {
  description = "The node pools of the GKE cluster"
  value       = module.gke.node_pools
}

output "gke_workload_identity_pool" {
  description = "The Workload Identity pool for the GKE cluster"
  value       = module.gke.workload_identity_pool
}

# Logging and Monitoring Outputs
output "gke_logging_components" {
  description = "Enabled logging components for the GKE cluster"
  value       = module.gke.logging_components
}

output "gke_monitoring_components" {
  description = "Enabled monitoring components for the GKE cluster"
  value       = module.gke.monitoring_components
}

output "gke_managed_prometheus_enabled" {
  description = "Whether managed Prometheus is enabled"
  value       = module.gke.managed_prometheus_enabled
}

output "gke_cluster_addons" {
  description = "Status of all enabled cluster addons"
  value       = module.gke.cluster_addons
}

# Service Account Outputs
output "service_accounts" {
  description = "Details of all created service accounts"
  value       = module.service_accounts.service_accounts
}

output "github_actions_service_account" {
  description = "GitHub Actions service account details"
  value = {
    email         = module.service_accounts.service_account_emails["github-actions"]
    member        = module.service_accounts.service_account_members["github-actions"]
    roles         = module.service_accounts.assigned_roles["github-actions"]
    prefixed_name = module.service_accounts.prefixed_service_account_names["github-actions"]
    labels        = module.service_accounts.service_account_labels["github-actions"]
  }
}

# Kubernetes Connection Information
output "kubernetes_config" {
  description = "Kubernetes configuration for connecting to the cluster"
  value = {
    cluster_name               = module.gke.cluster_name
    cluster_endpoint          = module.gke.cluster_endpoint
    cluster_ca_certificate    = module.gke.cluster_ca_certificate
    workload_identity_pool    = module.gke.workload_identity_pool
  }
  sensitive = true
}
