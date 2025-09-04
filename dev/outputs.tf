output "gke_cluster_name" {
  value       = module.gke.cluster_name
  description = "GKE cluster name"
}

output "gke_cluster_id" {
  value       = module.gke.cluster_id
  description = "GKE cluster ID"
}

output "gke_cluster_endpoint" {
  value       = module.gke.cluster_endpoint
  description = "GKE cluster endpoint"
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  value       = module.gke.cluster_ca_certificate
  description = "GKE cluster CA certificate"
  sensitive   = true
}

output "gke_cluster_location" {
  value       = module.gke.cluster_location
  description = "GKE cluster location"
}

output "gke_cluster_zones" {
  value       = module.gke.cluster_zones
  description = "List of zones in which the cluster resides"
}

output "gke_kubeconfig" {
  value       = module.gke.kubeconfig
  description = "Kubernetes configuration"
  sensitive   = true
}

output "vpc_network_id" {
  value       = module.vpc.vpc_network_id
  description = "VPC network ID"
}

output "subnet_ids" {
  value       = module.vpc.subnet_ids
  description = "Map of subnet names to their IDs"
}

output "gcr_repository_urls" {
  value       = module.gcr.repository_urls
  description = "Container registry repository URLs"
}

output "project_id" {
  value       = module.globals.project_id
  description = "GCP project ID"
}

output "region" {
  value       = module.globals.region
  description = "GCP region"
}
