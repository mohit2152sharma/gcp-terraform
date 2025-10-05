# GKE Module

This module creates a Google Kubernetes Engine (GKE) cluster with environment-specific configurations. It integrates with the commons module for consistent labeling and environment-aware resource sizing.

## Features

- Environment-aware cluster configurations (dev, staging, production)
- VPC-native networking with secondary IP ranges
- Private cluster support with configurable endpoints
- Workload Identity integration
- Flexible node pool configurations
- Auto-scaling and auto-healing capabilities
- Network policy support
- Master authorized networks
- Environment-specific resource sizing
- Comprehensive logging with Cloud Logging integration
- Advanced monitoring with Cloud Monitoring and managed Prometheus
- GKE Backup for Applications support
- Config Connector for Infrastructure as Code
- Per-namespace Workload Identity mappings with automated GSA creation, IAM binding, and optional KSA provisioning

## Usage

### Basic Usage with Commons Module
```hcl
module "commons" {
  source      = "../commons"
  environment = "dev"
}

module "gke" {
  source = "../modules/gke"
  
  environment = module.commons.environment
  project_id  = module.commons.project_id
  
  name     = "${module.commons.name_prefix}-gke-cluster"
  location = module.commons.region
  
  network    = "projects/${module.commons.project_id}/global/networks/vpc-network"
  subnetwork = "projects/${module.commons.project_id}/regions/${module.commons.region}/subnetworks/subnet"
  
  labels = module.commons.labels
}
```

### Advanced Configuration with Custom Node Pools
```hcl
module "gke" {
  source = "../modules/gke"
  
  environment = "production"
  project_id  = "your-project-id"
  
  name     = "production-gke-cluster"
  location = "us-central1"
  
  network    = "vpc-network"
  subnetwork = "subnet"
  
  node_locations = ["us-central1-a", "us-central1-b", "us-central1-c"]
  
  # Custom node pools
  node_pools = [
    {
      name           = "system-pool"
      machine_type   = "e2-standard-2"
      min_node_count = 1
      max_node_count = 3
      disk_size_gb   = 30
      preemptible    = false
      labels = {
        role = "system"
      }
    },
    {
      name           = "workload-pool"
      machine_type   = "e2-standard-4"
      min_node_count = 2
      max_node_count = 10
      disk_size_gb   = 50
      preemptible    = false
      labels = {
        role = "workload"
      }
    }
  ]
  
  # Master authorized networks
  master_authorized_networks = [
    {
      cidr_block   = "10.0.0.0/8"
      display_name = "VPC"
    }
  ]
  
  labels = {
    environment = "production"
    team        = "platform"
  }
}
```

## Environment Configurations

The module provides different default configurations for each environment:

### Development (dev)
- Machine type: `e2-medium`
- Min/Max nodes: 1-3
- Disk size: 20GB
- Preemptible: `true` (cost savings)
- Logging: System Components, Workloads
- Monitoring: System Components only
- Managed Prometheus: Disabled
- GKE Backup: Disabled
- Config Connector: Disabled

### Staging (staging)
- Machine type: `e2-standard-2`
- Min/Max nodes: 2-5
- Disk size: 30GB
- Preemptible: `false`
- Logging: System Components, Workloads, API Server
- Monitoring: System Components, Workloads
- Managed Prometheus: Enabled
- GKE Backup: Disabled
- Config Connector: Enabled

### Production (production)
- Machine type: `e2-standard-4`
- Min/Max nodes: 3-10
- Disk size: 50GB
- Preemptible: `false`
- Logging: System Components, Workloads, API Server
- Monitoring: System Components, Workloads, DaemonSet
- Managed Prometheus: Enabled
- GKE Backup: Enabled
- Config Connector: Enabled

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | The environment name (dev, staging, production) | `string` | n/a | yes |
| project_id | GCP project ID | `string` | n/a | yes |
| name | Name of the GKE cluster | `string` | n/a | yes |
| location | Location (zone or region) for the cluster | `string` | n/a | yes |
| network | VPC network name | `string` | n/a | yes |
| subnetwork | Subnetwork name | `string` | n/a | yes |
| node_locations | List of zones where nodes should be located | `list(string)` | `[]` | no |
| secondary_range_name_pods | Name of secondary IP range for pods | `string` | `"pods"` | no |
| secondary_range_name_services | Name of secondary IP range for services | `string` | `"services"` | no |
| initial_node_count | Initial number of nodes in the default node pool | `number` | `1` | no |
| remove_default_node_pool | Remove default node pool | `bool` | `true` | no |
| node_pools | List of node pools to create | `list(object)` | `[]` | no |
| master_authorized_networks | List of master authorized networks | `list(object)` | `[]` | no |
| enable_private_nodes | Enable private nodes | `bool` | `true` | no |
| enable_private_endpoint | Enable private endpoint | `bool` | `false` | no |
| master_ipv4_cidr_block | CIDR block for the master network | `string` | `"172.16.0.0/28"` | no |
| enable_network_policy | Enable network policy addon | `bool` | `true` | no |
| enable_http_load_balancing | Enable HTTP load balancing addon | `bool` | `true` | no |
| enable_horizontal_pod_autoscaling | Enable horizontal pod autoscaling addon | `bool` | `true` | no |
| enable_vertical_pod_autoscaling | Enable vertical pod autoscaling addon | `bool` | `false` | no |
| kubernetes_version | Kubernetes version | `string` | `"latest"` | no |
| labels | Labels to apply to the cluster | `map(string)` | `{}` | no |
| resource_labels | Resource labels to apply to the cluster | `map(string)` | `{}` | no |
| logging_components | List of logging components to enable | `list(string)` | Environment-specific defaults | no |
| monitoring_components | List of monitoring components to enable | `list(string)` | Environment-specific defaults | no |
| enable_managed_prometheus | Enable managed Prometheus for monitoring | `bool` | Environment-specific defaults | no |
| enable_backup_agent | Enable GKE Backup for Applications | `bool` | Environment-specific defaults | no |
| enable_config_connector | Enable Config Connector | `bool` | Environment-specific defaults | no |
| create_workload_identity_sa | Create a GSA for workloads and bind to KSA via Workload Identity | `bool` | `true` | no |
| workload_gsa_name | Account ID for workload GSA (prefixed by environment) | `string` | `"gke-workload"` | no |
| workload_gsa_display_name | Display name for workload GSA | `string` | `null` | no |
| workload_gsa_description | Description for workload GSA | `string` | `"GKE Workload Identity service account for accessing Google APIs"` | no |
| workload_sa_roles | Project roles for workload GSA | `list(string)` | `["roles/secretmanager.secretAccessor", "roles/logging.logWriter", "roles/monitoring.metricWriter"]` | no |
| workload_k8s_service_account_name | KSA name to map | `string` | `"workload"` | no |
| workload_k8s_service_account_namespace | KSA namespace | `string` | `"default"` | no |
| create_k8s_service_account | Create the KSA with proper annotation (requires kubernetes provider) | `bool` | `false` | no |
| workload_identity_mappings | List of WI mappings across namespaces (overrides single mapping vars) | `list(object)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_name | GKE cluster name |
| cluster_id | GKE cluster ID |
| cluster_endpoint | GKE cluster endpoint |
| cluster_ca_certificate | GKE cluster CA certificate |
| cluster_location | GKE cluster location |
| cluster_zones | List of zones in which the cluster resides |
| cluster_master_version | Current master kubernetes version |
| cluster_min_master_version | Minimum master kubernetes version |
| node_pools | Map of node pool names to their details |
| kubeconfig | Kubernetes configuration |
| workload_identity_pool | Workload Identity pool for the cluster |
| logging_components | Enabled logging components |
| monitoring_components | Enabled monitoring components |
| managed_prometheus_enabled | Whether managed Prometheus is enabled |
| cluster_addons | Status of all enabled cluster addons |
| workload_identity_mappings | Map of namespace/KSA to resolved GSA email and roles |

## Examples

### Minimal Configuration
```hcl
module "gke" {
  source = "../modules/gke"
  
  environment = "dev"
  project_id  = "my-project-123"
  name        = "dev-cluster"
  location    = "us-central1"
  network     = "default"
  subnetwork  = "default"
}
```

### Private Cluster with Custom Network
```hcl
module "gke" {
  source = "../modules/gke"
  
  environment = "production"
  project_id  = "my-project-123"
  name        = "prod-cluster"
  location    = "us-central1"
  
  network    = "custom-vpc"
  subnetwork = "gke-subnet"
  
  enable_private_nodes    = true
  enable_private_endpoint = true
  master_ipv4_cidr_block  = "172.16.0.0/28"
  
  master_authorized_networks = [
    {
      cidr_block   = "10.0.0.0/8"
      display_name = "Internal VPC"
    }
  ]
}
```

### Custom Logging and Monitoring Configuration
```hcl
module "gke" {
  source = "../modules/gke"
  
  environment = "production"
  project_id  = "my-project-123"
  name        = "production-gke-cluster"
  location    = "us-central1"
  
  network    = "vpc-network"
  subnetwork = "gke-subnet"
  
  # Custom logging configuration
  logging_components = ["SYSTEM_COMPONENTS", "WORKLOADS", "APISERVER"]
  
  # Custom monitoring configuration
  monitoring_components = ["SYSTEM_COMPONENTS", "WORKLOADS", "DAEMONSET"]
  enable_managed_prometheus = true
  
  # Enable additional features
  enable_backup_agent     = true
  enable_config_connector = true
}
```

### Workload Identity: GSA↔KSA mapping (Secret Manager + Logs + Metrics)
```hcl
module "gke" {
  source = "../modules/gke"

  environment = "dev"
  project_id  = "my-project"
  name        = "dev-cluster"
  location    = "us-central1"
  network     = "default"
  subnetwork  = "default"

  create_workload_identity_sa             = true
  workload_gsa_name                       = "gke-workload"
  workload_sa_roles                       = [
    "roles/secretmanager.secretAccessor",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter"
  ]
  workload_k8s_service_account_name       = "workload"
  workload_k8s_service_account_namespace  = "default"
  create_k8s_service_account              = false # set true if kubernetes provider configured
}

# In your workload manifest, set the serviceAccountName to the KSA name:
# apiVersion: apps/v1
# kind: Deployment
# spec:
#   template:
#     spec:
#       serviceAccountName: workload
```

### Multi-namespace Workload Identity mappings
```hcl
module "gke" {
  source = "../modules/gke"

  environment = "dev"
  project_id  = "my-project"
  name        = "dev-cluster"
  location    = "us-central1"
  network     = "default"
  subnetwork  = "default"

  workload_identity_mappings = [
    {
      namespace  = "default"
      ksa_name   = "workload"
      create_gsa = true
      gsa_name   = "gke-default-workload"
      roles      = [
        "roles/secretmanager.secretAccessor",
        "roles/logging.logWriter",
        "roles/monitoring.metricWriter"
      ]
      create_ksa = false
    },
    {
      namespace  = "platform"
      ksa_name   = "jobs"
      create_gsa = true
      gsa_name   = "gke-platform-jobs"
      roles      = [
        "roles/secretmanager.secretAccessor",
        "roles/logging.logWriter"
      ]
      create_ksa = true
    }
  ]
}
```

### Multi-Zone with Custom Node Pools
```hcl
module "gke" {
  source = "../modules/gke"
  
  environment = "staging"
  project_id  = "my-project-123"
  name        = "staging-cluster"
  location    = "us-central1"
  
  network    = "vpc-network"
  subnetwork = "gke-subnet"
  
  node_locations = ["us-central1-a", "us-central1-b"]
  
  node_pools = [
    {
      name           = "general-pool"
      machine_type   = "e2-standard-2"
      min_node_count = 1
      max_node_count = 5
      disk_size_gb   = 30
      labels = {
        workload_type = "general"
      }
    },
    {
      name           = "compute-pool"
      machine_type   = "c2-standard-4"
      min_node_count = 0
      max_node_count = 3
      disk_size_gb   = 50
      preemptible    = true
      labels = {
        workload_type = "compute"
      }
      taints = [
        {
          key    = "compute-intensive"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  ]
}
```

## Integration with Other Modules

This module integrates seamlessly with the commons and VPC modules:

```hcl
module "commons" {
  source      = "./modules/commons"
  environment = var.environment
}

module "vpc" {
  source = "./modules/vpc"
  
  environment = module.commons.environment
  project_id  = module.commons.project_id
  region      = module.commons.region
  labels      = module.commons.labels
}

module "gke" {
  source = "./modules/gke"
  
  environment = module.commons.environment
  project_id  = module.commons.project_id
  
  name     = "${module.commons.name_prefix}-gke"
  location = module.commons.region
  
  network    = module.vpc.network_name
  subnetwork = module.vpc.subnet_name
  
  secondary_range_name_pods     = "pods"
  secondary_range_name_services = "services"
  
  labels = module.commons.labels
}
```

## Logging and Monitoring Features

### Cloud Logging Integration
The module provides comprehensive logging capabilities with environment-specific defaults:

- **SYSTEM_COMPONENTS**: Logs from system components (kubelet, container runtime, etc.)
- **WORKLOADS**: Application container logs from your workloads
- **APISERVER**: Kubernetes API server audit logs (staging/production only)

### Cloud Monitoring Integration
Advanced monitoring with multiple component options:

- **SYSTEM_COMPONENTS**: Cluster infrastructure metrics
- **WORKLOADS**: Application workload metrics
- **DAEMONSET**: DaemonSet metrics (production only)

### Managed Prometheus
- Fully managed Prometheus service for metrics collection
- Enabled by default in staging and production environments
- Integrates with Google Cloud Operations for unified monitoring

### Additional Features
- **GKE Backup for Applications**: Automatic backup and restore capabilities
- **Config Connector**: Manage GCP resources directly from Kubernetes using CRDs
- **Environment-aware defaults**: Optimal configurations for each environment type

## Security Features

- **Workload Identity**: Automatically configured for secure pod-to-GCP service authentication
- **Private Nodes**: Nodes have private IP addresses only
- **Network Policy**: Kubernetes network policies for pod-to-pod traffic control
- **Master Authorized Networks**: Restrict access to the Kubernetes API server
- **Node Auto-upgrade**: Automatic security and bug fixes
- **Resource Labels**: Consistent labeling for security and compliance

## Best Practices

1. **Use Private Clusters**: Enable private nodes for production environments
2. **Configure Master Authorized Networks**: Restrict API server access
3. **Use Workload Identity**: Avoid storing service account keys in pods
4. **Enable Network Policies**: Control pod-to-pod communication
5. **Regular Updates**: Keep Kubernetes version current
6. **Resource Limits**: Set appropriate node pool sizing for your workloads
7. **Environment Separation**: Use different clusters for different environments
