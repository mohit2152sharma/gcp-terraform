output "cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE cluster name"
}

output "cluster_id" {
  value       = google_container_cluster.primary.id
  description = "GKE cluster ID"
}

output "cluster_endpoint" {
  value       = google_container_cluster.primary.endpoint
  description = "GKE cluster endpoint"
  sensitive   = true
}

output "cluster_ca_certificate" {
  value       = google_container_cluster.primary.master_auth.0.cluster_ca_certificate
  description = "GKE cluster CA certificate"
  sensitive   = true
}

output "cluster_location" {
  value       = google_container_cluster.primary.location
  description = "GKE cluster location"
}

output "cluster_zones" {
  value       = google_container_cluster.primary.node_locations
  description = "List of zones in which the cluster resides"
}

output "cluster_master_version" {
  value       = google_container_cluster.primary.master_version
  description = "Current master kubernetes version"
}

output "cluster_min_master_version" {
  value       = google_container_cluster.primary.min_master_version
  description = "Minimum master kubernetes version"
}

output "node_pools" {
  value = {
    for k, v in google_container_node_pool.pools : k => {
      name         = v.name
      id           = v.id
      instance_group_urls = v.instance_group_urls
      managed_instance_group_urls = v.managed_instance_group_urls
    }
  }
  description = "Map of node pool names to their details"
}

output "kubeconfig" {
  value = {
    host                   = google_container_cluster.primary.endpoint
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
  }
  description = "Kubernetes configuration"
  sensitive   = true
}

output "workload_identity_pool" {
  value       = "${var.project_id}.svc.id.goog"
  description = "Workload Identity pool for the cluster"
}
