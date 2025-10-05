locals {
  # Environment-specific configurations
  environment_configs = {
    dev = {
      key_algorithm       = "KEY_ALG_RSA_2048"
      private_key_type    = "TYPE_GOOGLE_CREDENTIALS_FILE"
      enable_key_rotation = false
    }
    staging = {
      key_algorithm       = "KEY_ALG_RSA_2048"
      private_key_type    = "TYPE_GOOGLE_CREDENTIALS_FILE"
      enable_key_rotation = true
    }
    production = {
      key_algorithm       = "KEY_ALG_RSA_2048"
      private_key_type    = "TYPE_GOOGLE_CREDENTIALS_FILE"
      enable_key_rotation = true
    }
  }

  current_env_config = var.environment != null ? local.environment_configs[var.environment] : local.environment_configs["dev"]

  # Create a map of service accounts for for_each with environment prefix
  service_accounts_map = {
    for sa in var.service_accounts : sa.account_id => merge(sa, {
      prefixed_account_id = var.environment != null ? "${var.environment}-${sa.account_id}" : sa.account_id
      merged_labels = merge(
        var.global_labels,
        sa.labels
      )
    })
  }

  # Flatten service account and role combinations for IAM member resources
  sa_role_pairs = flatten([
    for sa_id, sa_config in local.service_accounts_map : [
      for role in sa_config.project_roles : {
        sa_id = sa_id
        role  = role
      }
    ]
  ])

  # Flatten service account and custom IAM binding combinations
  sa_custom_binding_pairs = flatten([
    for sa_id, sa_config in local.service_accounts_map : [
      for role, binding in sa_config.custom_iam_bindings : {
        sa_id   = sa_id
        role    = role
        binding = binding
      }
    ]
  ])

  # Flatten service account and workload identity combinations
  sa_workload_identity_pairs = flatten([
    for sa_id, sa_config in local.service_accounts_map : [
      for binding_name, binding in sa_config.workload_identity_bindings : {
        sa_id        = sa_id
        binding_name = binding_name
        namespace    = binding.namespace
        ksa_name     = binding.ksa_name
      }
    ]
  ])
}

# Service Accounts
resource "google_service_account" "service_accounts" {
  for_each = local.service_accounts_map

  account_id   = each.value.prefixed_account_id
  display_name = each.value.display_name != null ? each.value.display_name : each.value.prefixed_account_id
  description  = each.value.description
  project      = var.project_id
}

# Service Account Keys (optional)
resource "google_service_account_key" "service_account_keys" {
  for_each = {
    for sa_id, sa_config in local.service_accounts_map : sa_id => sa_config
    if sa_config.create_key
  }

  service_account_id = google_service_account.service_accounts[each.key].name
  key_algorithm      = each.value.key_algorithm != null ? each.value.key_algorithm : local.current_env_config.key_algorithm
  private_key_type   = each.value.private_key_type != null ? each.value.private_key_type : local.current_env_config.private_key_type
}

# Project-level IAM bindings
resource "google_project_iam_member" "service_account_roles" {
  for_each = {
    for pair in local.sa_role_pairs : "${pair.sa_id}-${pair.role}" => pair
  }

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.service_accounts[each.value.sa_id].email}"
}

# Custom IAM bindings (for specific resources)
resource "google_project_iam_binding" "custom_bindings" {
  for_each = {
    for pair in local.sa_custom_binding_pairs : "${pair.sa_id}-${pair.role}" => pair
  }

  project = var.project_id
  role    = each.value.role
  members = concat(
    ["serviceAccount:${google_service_account.service_accounts[each.value.sa_id].email}"],
    each.value.binding.members
  )

  dynamic "condition" {
    for_each = each.value.binding.condition != null ? [each.value.binding.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

# Workload Identity bindings (for GKE)
resource "google_service_account_iam_binding" "workload_identity" {
  for_each = {
    for pair in local.sa_workload_identity_pairs : "${pair.sa_id}-${pair.binding_name}" => pair
  }

  service_account_id = google_service_account.service_accounts[each.value.sa_id].name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[${each.value.namespace}/${each.value.ksa_name}]"
  ]
}
