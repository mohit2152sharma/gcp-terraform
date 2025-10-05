# Service Account Module

This module creates and manages multiple Google Cloud Service Accounts with associated IAM roles, keys, and Workload Identity bindings from a single module call.

## Features

- Creates multiple Google Cloud Service Accounts from a list configuration
- **Automatic environment prefixing** of service account names (e.g., `dev-app-sa`)
- **Flexible labeling** by passing labels from commons module + service-specific labels
- Individual service account key generation
- Per-service-account project-level IAM role assignments
- Custom IAM bindings with conditions per service account
- Workload Identity bindings for GKE integration
- Individual labels per service account
- Global labels support (typically from commons module)
- Environment-specific configurations
- Comprehensive validation

## Usage

### Basic Service Accounts

```hcl
module "service_accounts" {
  source = "./modules/service_account"

  project_id  = "my-project-id"
  environment = "production"  # Creates: production-app-backend-sa, production-app-frontend-sa
  
  service_accounts = [
    {
      account_id = "app-backend-sa"  # Will become: production-app-backend-sa
      description = "Service account for backend application"
      project_roles = [
        "roles/storage.objectViewer",
        "roles/logging.logWriter"
      ]
      labels = {
        application = "backend"
        team        = "platform"
      }
    },
    {
      account_id = "app-frontend-sa"  # Will become: production-app-frontend-sa
      description = "Service account for frontend application"
      project_roles = [
        "roles/storage.objectViewer"
      ]
      labels = {
        application = "frontend"
        team        = "ui"
      }
    }
  ]
  
  # Pass labels from commons module as global labels
  global_labels = module.commons.labels
}
```

### Service Accounts with Keys and Workload Identity

```hcl
module "workload_service_accounts" {
  source = "./modules/service_account"

  project_id  = "my-project-id"
  environment = "production"
  
  service_accounts = [
    {
      account_id   = "k8s-app-sa"
      display_name = "Kubernetes Application SA"
      description  = "Service account for Kubernetes workloads"
      
      project_roles = [
        "roles/storage.admin",
        "roles/secretmanager.secretAccessor"
      ]
      
      workload_identity_bindings = {
        "app-binding" = {
          namespace = "default"
          ksa_name  = "app-ksa"
        },
        "worker-binding" = {
          namespace = "workers"
          ksa_name  = "worker-ksa"
        }
      }
      
      labels = {
        application = "my-app"
        component   = "workload"
      }
    },
    {
      account_id = "external-sa"
      description = "Service account for external systems"
      
      create_key = true
      key_algorithm = "KEY_ALG_RSA_2048"
      
      project_roles = [
        "roles/storage.objectCreator"
      ]
      
      labels = {
        usage = "external-system"
      }
    }
  ]
}
```

### Service Accounts with Custom IAM Bindings

```hcl
module "custom_iam_service_accounts" {
  source = "./modules/service_account"

  project_id = "my-project-id"
  
  service_accounts = [
    {
      account_id = "restricted-sa"
      description = "Service account with time-based access"
      
      custom_iam_bindings = {
        "roles/storage.objectViewer" = {
          members = [
            "user:admin@example.com"
          ]
          condition = {
            title       = "Business hours only"
            description = "Access restricted to business hours"
            expression  = "request.time.getHours() >= 9 && request.time.getHours() < 17"
          }
        }
      }
      
      labels = {
        access_type = "restricted"
      }
    }
  ]
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | GCP project ID | `string` | n/a | yes |
| environment | Environment name (dev, staging, production) | `string` | `null` | no |
| service_accounts | List of service account configurations | `list(object)` | n/a | yes |
| global_labels | Global labels to apply to all service accounts | `map(string)` | `{}` | no |
| global_tags | Global tags to apply to all service accounts | `list(string)` | `[]` | no |

### Service Account Object Structure

Each service account in the `service_accounts` list supports:

| Field | Description | Type | Default | Required |
|-------|-------------|------|---------|:--------:|
| account_id | Service account ID (unique within project) | `string` | n/a | yes |
| display_name | Display name for the service account | `string` | `null` | no |
| description | Description of the service account | `string` | `"Service account created by Terraform"` | no |
| create_key | Whether to create a service account key | `bool` | `false` | no |
| key_algorithm | Algorithm for key generation | `string` | `null` | no |
| private_key_type | Private key output format | `string` | `null` | no |
| project_roles | List of project-level IAM roles | `list(string)` | `[]` | no |
| custom_iam_bindings | Custom IAM bindings with conditions | `map(object)` | `{}` | no |
| workload_identity_bindings | Workload Identity bindings for GKE | `map(object)` | `{}` | no |
| enable_impersonation | Enable service account impersonation | `bool` | `false` | no |
| impersonation_delegates | List of accounts that can impersonate | `list(string)` | `[]` | no |
| labels | Labels specific to this service account | `map(string)` | `{}` | no |
| tags | Tags specific to this service account | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| service_accounts | Map of original service account IDs to their complete details (includes prefixed names) |
| service_account_emails | Map of original service account IDs to their email addresses |
| service_account_members | Map of original service account IDs to their IAM member strings |
| prefixed_service_account_names | Map of original service account IDs to their prefixed names (with environment) |
| service_account_labels | Map of original service account IDs to their merged labels |
| service_account_keys | Map of service account IDs to their private keys (sensitive) |
| service_account_json_keys | Map of service account IDs to their JSON keys (sensitive) |
| workload_identity_pool | Workload Identity pool for the project |
| workload_identity_bindings | Map of all Workload Identity bindings created |
| assigned_roles | Map of original service account IDs to their assigned project roles |

## Output Usage Examples

```hcl
# Access specific service account email (use original account_id as key)
email = module.service_accounts.service_account_emails["app-backend-sa"]
# Actual email will be: production-app-backend-sa@project-id.iam.gserviceaccount.com

# Access prefixed service account name
prefixed_name = module.service_accounts.prefixed_service_account_names["app-backend-sa"]
# Returns: "production-app-backend-sa"

# Access all service account details
backend_sa = module.service_accounts.service_accounts["app-backend-sa"]
# Includes: email, prefixed_name, original_name, labels, etc.

# Access merged labels for a service account
labels = module.service_accounts.service_account_labels["app-backend-sa"]
# Returns all merged labels including environment, global, and individual labels

# Access service account key (if created)
private_key = module.service_accounts.service_account_keys["external-sa"].private_key
```

## Environment-Specific Defaults

The module supports environment-specific configurations:

- **dev**: Basic key settings, no key rotation
- **staging**: Enhanced key settings, key rotation enabled  
- **production**: Full security settings, key rotation enabled

## Validation Rules

- Service account IDs must be 6-30 characters, start with lowercase letter, contain only lowercase letters, numbers, and hyphens
- Environment must be one of: dev, staging, production (if specified)
- Key algorithms must be valid Google Cloud values
- Private key types must be supported formats

## Security Considerations

1. **Service Account Keys**: Only create keys when absolutely necessary. Use Workload Identity for GKE workloads instead.
2. **Least Privilege**: Only assign the minimum required IAM roles to each service account.
3. **Key Rotation**: Enable key rotation for staging and production environments.
4. **Sensitive Outputs**: Service account keys are marked as sensitive and should be handled securely.
5. **Individual Permissions**: Each service account can have different roles and permissions based on its specific needs.

## Examples

For multiple service accounts with different roles:

```hcl
service_accounts = [
  {
    account_id = "app-api-sa"
    project_roles = ["roles/storage.admin", "roles/cloudsql.client"]
    labels = { component = "api" }
  },
  {
    account_id = "app-worker-sa" 
    project_roles = ["roles/pubsub.subscriber", "roles/storage.objectViewer"]
    labels = { component = "worker" }
  },
  {
    account_id = "monitoring-sa"
    project_roles = ["roles/monitoring.metricWriter", "roles/logging.logWriter"]
    labels = { component = "monitoring" }
  }
]
```

## Requirements

- Terraform >= 0.14
- Google Cloud Provider >= 4.0