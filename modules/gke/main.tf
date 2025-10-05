locals {
  # Environment-specific configurations
  environment_configs = {
    dev = {
      machine_type   = "e2-medium"
      min_node_count = 1
      max_node_count = 3
      disk_size_gb   = 20
      preemptible    = true
      # Logging and Monitoring - Basic for dev
      logging_components        = ["SYSTEM_COMPONENTS", "WORKLOADS"]
      monitoring_components     = ["SYSTEM_COMPONENTS"]
      enable_managed_prometheus = false
    }
    staging = {
      machine_type   = "e2-standard-2"
      min_node_count = 2
      max_node_count = 5
      disk_size_gb   = 30
      preemptible    = false
      # Logging and Monitoring - Enhanced for staging
      logging_components        = ["SYSTEM_COMPONENTS", "WORKLOADS", "APISERVER"]
      monitoring_components     = ["SYSTEM_COMPONENTS", "WORKLOADS"]
      enable_managed_prometheus = true
    }
    production = {
      machine_type   = "e2-standard-4"
      min_node_count = 3
      max_node_count = 10
      disk_size_gb   = 50
      preemptible    = false
      # Logging and Monitoring - Full for production
      logging_components        = ["SYSTEM_COMPONENTS", "WORKLOADS", "APISERVER"]
      monitoring_components     = ["SYSTEM_COMPONENTS", "WORKLOADS", "DAEMONSET"]
      enable_managed_prometheus = true
    }
  }

  current_env_config = local.environment_configs[var.environment]

  # Merge environment-specific labels with provided labels
  cluster_labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
    cluster     = var.name
  })

  wi_has_multi = length(var.workload_identity_mappings) > 0

  wi_mappings_base = local.wi_has_multi ? var.workload_identity_mappings : [
    {
      namespace        = var.workload_k8s_service_account_namespace
      ksa_name         = var.workload_k8s_service_account_name
      create_gsa       = var.create_workload_identity_sa
      gsa_name         = var.workload_gsa_name
      gsa_display_name = var.workload_gsa_display_name
      gsa_description  = var.workload_gsa_description
      roles            = var.workload_sa_roles
      create_ksa       = var.create_k8s_service_account
    }
  ]

  wi_mappings_normalized = [
    for mapping in local.wi_mappings_base : merge(mapping, {
      create_gsa = lookup(mapping, "create_gsa", local.wi_has_multi ? true : var.create_workload_identity_sa)
      roles      = distinct(coalesce(lookup(mapping, "roles", null), var.workload_sa_roles))
      create_ksa = lookup(mapping, "create_ksa", local.wi_has_multi ? false : var.create_k8s_service_account)

      gsa_account_id = substr(
        trim(
          join(
            "",
            regexall(
              "[a-z0-9-]",
              lower(coalesce(lookup(mapping, "gsa_name", null), "wi-${var.environment}-${mapping.namespace}-${mapping.ksa_name}"))
            )
          ),
          "-"
        ),
        0,
        30
      )

      gsa_display_name = coalesce(lookup(mapping, "gsa_display_name", null), "WI ${mapping.namespace}/${mapping.ksa_name}")
      gsa_description  = coalesce(lookup(mapping, "gsa_description", null), var.workload_gsa_description)
      gsa_email        = "${substr(
        trim(
          join(
            "",
            regexall(
              "[a-z0-9-]",
              lower(coalesce(lookup(mapping, "gsa_name", null), "wi-${var.environment}-${mapping.namespace}-${mapping.ksa_name}"))
            )
          ),
          "-"
        ),
        0,
        30
      )}@${var.project_id}.iam.gserviceaccount.com"
      ksa_member       = "serviceAccount:${var.project_id}.svc.id.goog[${mapping.namespace}/${mapping.ksa_name}]"
    })
  ]

  wi_mappings_map = {
    for mapping in local.wi_mappings_normalized : "${mapping.namespace}/${mapping.ksa_name}" => merge(mapping, {
      key = "${mapping.namespace}/${mapping.ksa_name}"
    })
  }
}

locals {
  wi_role_bindings = flatten([
    for key, mapping in local.wi_mappings_map : [
      for role in mapping.roles : {
        key  = key
        role = role
      }
    ]
  ])

  wi_role_bindings_map = {
    for binding in local.wi_role_bindings : "${binding.key}:${binding.role}" => binding
  }
}

# Data source for Google client configuration
data "google_client_config" "default" {}

# GKE cluster
resource "google_container_cluster" "primary" {
  name                = var.name
  location            = var.location
  deletion_protection = false

  project = var.project_id

  # Node locations
  node_locations = var.node_locations

  # Remove default node pool
  remove_default_node_pool = var.remove_default_node_pool
  initial_node_count       = var.initial_node_count

  # Kubernetes version
  min_master_version = var.kubernetes_version == "latest" ? null : var.kubernetes_version

  # Network configuration
  network    = var.network
  subnetwork = var.subnetwork

  # IP allocation policy for VPC-native networking
  ip_allocation_policy {
    cluster_secondary_range_name  = var.secondary_range_name_pods
    services_secondary_range_name = var.secondary_range_name_services
  }

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # Master authorized networks
  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Logging configuration
  logging_config {
    enable_components = var.logging_components != null ? var.logging_components : local.current_env_config.logging_components
  }

  # Monitoring configuration
  monitoring_config {
    enable_components = var.monitoring_components != null ? var.monitoring_components : local.current_env_config.monitoring_components

    dynamic "managed_prometheus" {
      for_each = (var.enable_managed_prometheus != null ? var.enable_managed_prometheus : local.current_env_config.enable_managed_prometheus) ? [1] : []
      content {
        enabled = true
      }
    }
  }

  # Add-ons configuration
  addons_config {
    http_load_balancing {
      disabled = !var.enable_http_load_balancing
    }

    horizontal_pod_autoscaling {
      disabled = !var.enable_horizontal_pod_autoscaling
    }

    network_policy_config {
      disabled = !var.enable_network_policy
    }

    # Note: vertical_pod_autoscaling, gke_backup_agent_config, and config_connector_config
    # may not be supported in all Google provider versions
    # They are managed separately or through cluster configuration
  }

  # Network policy
  dynamic "network_policy" {
    for_each = var.enable_network_policy ? [1] : []
    content {
      enabled = true
    }
  }

  # Vertical Pod Autoscaling (separate configuration)
  dynamic "vertical_pod_autoscaling" {
    for_each = var.enable_vertical_pod_autoscaling ? [1] : []
    content {
      enabled = true
    }
  }

  # Resource labels
  resource_labels = merge(local.cluster_labels, var.resource_labels)

  # Lifecycle
  lifecycle {
    ignore_changes = [
      node_pool,
      initial_node_count,
    ]
  }

  # Dependencies
  depends_on = [
    data.google_client_config.default
  ]
}

# Node pools
resource "google_container_node_pool" "pools" {
  for_each = { for np in var.node_pools : np.name => np }

  name     = each.value.name
  location = google_container_cluster.primary.location
  cluster  = google_container_cluster.primary.name
  project  = var.project_id


  # Node locations (same as cluster by default)
  node_locations = var.node_locations

  # Node count configuration
  node_count = each.value.min_node_count == each.value.max_node_count ? each.value.node_count : null

  dynamic "autoscaling" {
    for_each = each.value.min_node_count != each.value.max_node_count ? [1] : []
    content {
      min_node_count = each.value.min_node_count
      max_node_count = each.value.max_node_count
    }
  }

  # Node configuration
  node_config {
    preemptible  = each.value.preemptible
    spot         = each.value.spot
    machine_type = each.value.machine_type

    # Service account
    service_account = "default"
    oauth_scopes    = each.value.oauth_scopes

    # Labels and tags
    labels = merge(local.cluster_labels, each.value.labels)
    tags   = each.value.tags

    # Disk configuration
    disk_size_gb = each.value.disk_size_gb
    disk_type    = each.value.disk_type
    image_type   = each.value.image_type

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Taints
    dynamic "taint" {
      for_each = each.value.taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
  }

  # Management
  management {
    auto_repair  = each.value.auto_repair
    auto_upgrade = each.value.auto_upgrade
  }

  # Lifecycle
  lifecycle {
    ignore_changes = [
      initial_node_count,
    ]
  }

  # Dependencies
  depends_on = [google_container_cluster.primary]
}

# Default node pool if no custom node pools are specified
resource "google_container_node_pool" "default_pool" {
  count = length(var.node_pools) == 0 ? 1 : 0

  name     = "${var.name}-default-pool"
  location = google_container_cluster.primary.location
  cluster  = google_container_cluster.primary.name
  project  = var.project_id

  # Node locations
  node_locations = var.node_locations

  # Autoscaling
  autoscaling {
    min_node_count = local.current_env_config.min_node_count
    max_node_count = local.current_env_config.max_node_count
  }

  # Node configuration with environment-specific defaults
  node_config {
    preemptible  = local.current_env_config.preemptible
    machine_type = local.current_env_config.machine_type

    # Service account
    service_account = "default"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Labels
    labels = local.cluster_labels

    # Disk configuration
    disk_size_gb = local.current_env_config.disk_size_gb
    disk_type    = "pd-standard"
    image_type   = "COS_CONTAINERD"

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  # Management
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Dependencies
  depends_on = [google_container_cluster.primary]
}

# Workload Identity - Google Service Accounts per namespace
resource "google_service_account" "workload_multi" {
  for_each = {
    for k, mapping in local.wi_mappings_map : k => mapping
    if mapping.create_gsa && mapping.gsa_account_id != null
  }

  provider = google
  project      = var.project_id
  account_id   = each.value.gsa_account_id
  display_name = each.value.gsa_display_name
  description  = each.value.gsa_description
}

data "google_service_account" "workload_multi" {
  for_each = {
    for k, mapping in local.wi_mappings_map : k => mapping
    if !mapping.create_gsa && mapping.gsa_account_id != null
  }

  provider   = google
  account_id = each.value.gsa_account_id
  project    = var.project_id
}

resource "google_project_iam_member" "workload_roles" {
  for_each = local.wi_role_bindings_map

  provider = google
  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${coalesce(
    try(google_service_account.workload_multi[each.value.key].email, null),
    try(data.google_service_account.workload_multi[each.value.key].email, null)
  )}"
}

resource "google_service_account_iam_member" "workload_identity" {
  for_each = local.wi_mappings_map

  provider = google
  service_account_id = coalesce(
    try(google_service_account.workload_multi[each.key].name, null),
    try(data.google_service_account.workload_multi[each.key].name, null)
  )

  role   = "roles/iam.workloadIdentityUser"
  member = each.value.ksa_member
}

resource "kubernetes_service_account" "workload" {
  for_each = {
    for k, mapping in local.wi_mappings_map : k => mapping if mapping.create_ksa
  }

  provider = kubernetes
  metadata {
    name      = each.value.ksa_name
    namespace = each.value.namespace
    annotations = {
      "iam.gke.io/gcp-service-account" = coalesce(
        try(google_service_account.workload_multi[each.key].email, null),
        try(data.google_service_account.workload_multi[each.key].email, null)
      )
    }
  }
}

