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
  value = merge(
    # Custom node pools
    {
      for k, v in google_container_node_pool.pools : k => {
        name         = v.name
        id           = v.id
        instance_group_urls = v.instance_group_urls
        managed_instance_group_urls = v.managed_instance_group_urls
      }
    },
    # Default node pool (if created)
    length(var.node_pools) == 0 ? {
      "default-pool" = {
        name         = google_container_node_pool.default_pool[0].name
        id           = google_container_node_pool.default_pool[0].id
        instance_group_urls = google_container_node_pool.default_pool[0].instance_group_urls
        managed_instance_group_urls = google_container_node_pool.default_pool[0].managed_instance_group_urls
      }
    } : {}
  )
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

# Logging and Monitoring Outputs
output "logging_components" {
  value       = google_container_cluster.primary.logging_config[0].enable_components
  description = "Enabled logging components"
}

output "monitoring_components" {
  value       = google_container_cluster.primary.monitoring_config[0].enable_components
  description = "Enabled monitoring components"
}

output "managed_prometheus_enabled" {
  value       = length(google_container_cluster.primary.monitoring_config[0].managed_prometheus) > 0
  description = "Whether managed Prometheus is enabled"
}

output "cluster_addons" {
  value = {
    http_load_balancing         = !google_container_cluster.primary.addons_config[0].http_load_balancing[0].disabled
    horizontal_pod_autoscaling  = !google_container_cluster.primary.addons_config[0].horizontal_pod_autoscaling[0].disabled
    network_policy_config       = !google_container_cluster.primary.addons_config[0].network_policy_config[0].disabled
    vertical_pod_autoscaling    = length(google_container_cluster.primary.vertical_pod_autoscaling) > 0 ? google_container_cluster.primary.vertical_pod_autoscaling[0].enabled : false
  }
  description = "Enabled cluster addons and their status"
}


# Workload Identity - Workload Service Account Outputs
output "workload_identity_mappings" {
  value = {
    for k, m in local.wi_mappings_map : k => {
      namespace = m.namespace
      ksa_name  = m.ksa_name
      gsa_email = coalesce(
        try(google_service_account.workload_multi[k].email, null),
        try(data.google_service_account.workload_multi[k].email, null)
      )
      roles = m.roles
    }
  }
  description = "Map of namespace/KSA to resolved GSA email and roles"
}

