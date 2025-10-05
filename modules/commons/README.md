# Commons Module

This module provides common configurations and values that are shared across different environments in the GCP Terraform project. It includes predefined project ID (`saral-458210`) and region (`asia-south1`) settings.

## Features

- Environment-specific configurations for `dev`, `staging`, and `production`
- Standardized labeling with environment awareness
- Environment-specific naming conventions
- Configurable zone counts and instance sizes per environment

## Usage

```hcl
module "commons" {
  source = "../modules/commons"
  
  environment = "dev"  # or "staging" or "production"
  
  # Optional: Add additional labels
  additional_labels = {
    team        = "platform"
    cost_center = "engineering"
  }
}
```

## Environment Configurations

The module provides different configurations for each environment:

### Development (dev)
- Name suffix: `dev`
- Zone count: 1
- Instance size: `small`

### Staging (stg)
- Name suffix: `stg` 
- Zone count: 2
- Instance size: `medium`

### Production (prod)
- Name suffix: `prod`
- Zone count: 3
- Instance size: `large`

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | The environment name (dev, staging, production) | `string` | n/a | yes |
| additional_labels | Additional labels to merge with default labels | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| project_id | The GCP project ID |
| region | The GCP region |
| labels | Common labels including environment |
| environment | The current environment |
| name_prefix | Environment-specific name prefix for resources |
| environment_config | Environment-specific configuration settings |
| zone_count | Number of zones for the current environment |
| instance_size | Instance size for the current environment |
| name_suffix | Environment-specific name suffix |

## Examples

### Basic Usage
```hcl
module "commons" {
  source      = "../modules/commons"
  environment = "dev"
}

# Use the outputs in other resources
resource "google_compute_instance" "example" {
  name = "${module.commons.name_prefix}web-server"
  
  labels = module.commons.labels
  
  machine_type = module.commons.instance_size == "small" ? "e2-micro" : 
                 module.commons.instance_size == "medium" ? "e2-standard-2" : 
                 "e2-standard-4"
}
```

### With Additional Labels
```hcl
module "commons" {
  source      = "../modules/commons"
  environment = "production"
  
  additional_labels = {
    team        = "backend"
    cost_center = "engineering"
    compliance  = "required"
  }
}
```

### Basic Staging Environment
```hcl
module "commons" {
  source      = "../modules/commons"
  environment = "staging"
}
```

## Integration with Other Modules

This commons module is designed to be used by other modules in the project:

```hcl
# In your main.tf
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
  
  environment   = module.commons.environment
  project_id    = module.commons.project_id
  region        = module.commons.region
  labels        = module.commons.labels
  zone_count    = module.commons.zone_count
  instance_size = module.commons.instance_size
}
```
