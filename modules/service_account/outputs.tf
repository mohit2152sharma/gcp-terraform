output "service_accounts" {
  value = {
    for sa_id, sa in google_service_account.service_accounts : sa_id => {
      email         = sa.email
      name          = sa.name
      unique_id     = sa.unique_id
      display_name  = sa.display_name
      member        = "serviceAccount:${sa.email}"
      account_id    = sa.account_id
      prefixed_name = sa.account_id
      original_name = sa_id
      labels        = local.service_accounts_map[sa_id].merged_labels
    }
  }
  description = "Map of original service account IDs to their details (including prefixed names)"
}

output "service_account_emails" {
  value = {
    for sa_id, sa in google_service_account.service_accounts : sa_id => sa.email
  }
  description = "Map of original service account IDs to their email addresses"
}

output "service_account_members" {
  value = {
    for sa_id, sa in google_service_account.service_accounts : sa_id => "serviceAccount:${sa.email}"
  }
  description = "Map of original service account IDs to their IAM member strings"
}

output "service_account_keys" {
  value = {
    for sa_id, key in google_service_account_key.service_account_keys : sa_id => {
      name        = key.name
      private_key = key.private_key
    }
  }
  description = "Map of service account IDs to their private keys (base64 encoded)"
  sensitive   = true
}

output "service_account_json_keys" {
  value = {
    for sa_id, key in google_service_account_key.service_account_keys : sa_id => base64decode(key.private_key)
  }
  description = "Map of service account IDs to their JSON keys"
  sensitive   = true
}

output "workload_identity_pool" {
  value       = var.project_id != null ? "${var.project_id}.svc.id.goog" : null
  description = "Workload Identity pool for the project"
}

output "workload_identity_bindings" {
  value = {
    for pair in local.sa_workload_identity_pairs : "${pair.sa_id}-${pair.binding_name}" => {
      service_account_id    = pair.sa_id
      service_account_email = google_service_account.service_accounts[pair.sa_id].email
      namespace             = pair.namespace
      ksa_name              = pair.ksa_name
      binding_name          = pair.binding_name
    }
  }
  description = "Map of Workload Identity bindings created"
}

output "assigned_roles" {
  value = {
    for sa_id, sa_config in local.service_accounts_map : sa_id => sa_config.project_roles
  }
  description = "Map of original service account IDs to their assigned project roles"
}

output "prefixed_service_account_names" {
  value = {
    for sa_id, sa_config in local.service_accounts_map : sa_id => sa_config.prefixed_account_id
  }
  description = "Map of original service account IDs to their prefixed names (with environment)"
}

output "service_account_labels" {
  value = {
    for sa_id, sa_config in local.service_accounts_map : sa_id => sa_config.merged_labels
  }
  description = "Map of original service account IDs to their merged labels"
}
