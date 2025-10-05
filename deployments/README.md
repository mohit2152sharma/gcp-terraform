# GKE Deployments

This directory contains the deployment configurations for deploying applications to Google Kubernetes Engine (GKE) using Helm charts adapted for GCP.

## Structure

```
deployments/
├── dev/
│   └── terraform/
│       ├── main.tf           # Provider and remote state configuration
│       ├── variables.tf      # Variable definitions
│       ├── infrastructure.tf # NGINX Ingress, Cert-manager setup
│       ├── services.tf       # Service deployments using Helm
│       ├── outputs.tf        # Outputs
│       └── terraform.tfvars  # Environment-specific values
└── README.md
```

## Prerequisites

1. **Infrastructure Setup**: Ensure your GKE cluster is deployed using the terraform configuration in the `dev/` directory
2. **Terraform Backend**: Configure remote state storage in GCS
3. **Domain Name**: Update `terraform.tfvars` with your actual domain name
4. **Container Images**: Ensure your application images are pushed to Google Artifact Registry

## Quick Start

### 1. Deploy Infrastructure (GKE Cluster)

```bash
cd dev/
terraform init
terraform plan -var-file="../globals.tfvars"
terraform apply -var-file="../globals.tfvars"
```

### 2. Configure Backend State

Update `deployments/dev/terraform/main.tf` with your GCS bucket for remote state:

```hcl
data "terraform_remote_state" "infrastructure" {
  backend = "gcs"
  config = {
    bucket = "your-project-terraform-state"  # Update this
    prefix = "dev"
  }
}
```

### 3. Update Service Configuration

Edit `deployments/dev/terraform/terraform.tfvars` to configure your services:

```hcl
services = {
  your-service = {
    enabled     = true
    image       = "gcr.io/your-project/your-service"
    tag         = "v1.0.0"
    replicas    = 2
    # ... other configuration
  }
}
```

### 4. Deploy Services

```bash
cd deployments/dev/terraform/
terraform init
terraform plan
terraform apply
```

## Features

### Infrastructure Components

- **NGINX Ingress Controller**: Manages external access to services
- **Cert-Manager**: Automatic SSL certificate management with Let's Encrypt
- **Namespaces**: Organized application deployment

### Service Configuration

Each service supports:

- **Autoscaling**: Horizontal Pod Autoscaler (HPA) configuration
- **Resource Management**: CPU and memory requests/limits
- **Health Checks**: Readiness, liveness, and startup probes
- **Environment Variables**: Configuration via env vars and config maps
- **Secrets Management**: Kubernetes secrets integration
- **Ingress**: Automatic ingress rules with SSL termination

### Helm Chart Adaptations

The original AWS EKS-focused helm charts have been adapted for GKE:

- **Ingress**: Switched from AWS ALB to NGINX Ingress Controller
- **Load Balancing**: Uses GCP Load Balancer instead of AWS ALB
- **SSL**: Cert-manager with Let's Encrypt instead of AWS ACM
- **Container Registry**: Google Artifact Registry/Container Registry support
- **Node Selection**: GKE-specific node selectors

## Configuration Reference

### Service Configuration

```hcl
service-name = {
  enabled     = bool           # Enable/disable service deployment
  image       = string         # Container image path
  tag         = string         # Image tag
  replicas    = number         # Initial replica count
  port        = number         # Service port
  target_port = number         # Container port
  paths       = list(string)   # Ingress paths
  hosts       = list(string)   # Ingress hosts
  
  resources = {
    requests = {
      cpu    = string
      memory = string
    }
    limits = {
      cpu    = string
      memory = string
    }
  }
  
  autoscaling = {
    enabled                   = bool
    min_replicas             = number
    max_replicas             = number
    target_cpu_utilization   = number
    target_memory_utilization = number
  }
  
  env_vars       = map(string)  # Environment variables
  config_maps    = map(string)  # Config map references
  secrets        = map(string)  # Secret references
  health_check_path = string    # Health check endpoint
}
```

## Monitoring and Observability

The deployment includes:

- **Prometheus Annotations**: Services are annotated for Prometheus scraping
- **Health Checks**: Comprehensive probe configuration
- **Resource Monitoring**: CPU and memory monitoring for autoscaling

## Security

- **Private Cluster**: GKE cluster with private nodes
- **Network Policies**: Calico network policies enabled
- **Workload Identity**: Google Cloud IAM integration
- **Shielded Nodes**: Enhanced security features
- **SSL/TLS**: Automatic certificate management

## Troubleshooting

### Check Cluster Status
```bash
kubectl get nodes
kubectl get pods -A
```

### Check Ingress
```bash
kubectl get ingress -A
kubectl describe ingress <ingress-name> -n <namespace>
```

### Check Services
```bash
kubectl get svc -A
kubectl get endpoints -A
```

### View Logs
```bash
kubectl logs -f deployment/<service-name> -n <namespace>
```

## Scaling

### Manual Scaling
```bash
kubectl scale deployment <deployment-name> --replicas=5 -n <namespace>
```

### Check HPA Status
```bash
kubectl get hpa -A
kubectl describe hpa <hpa-name> -n <namespace>
```

## Domain and DNS

1. Get the NGINX Ingress Controller external IP:
   ```bash
   kubectl get svc -n ingress-nginx
   ```

2. Create DNS A records pointing your domains to this IP

3. Cert-manager will automatically provision SSL certificates

## Environment Management

Create additional environments by:

1. Copying the `dev/` directory structure
2. Updating variable values for the new environment
3. Ensuring separate GCS state buckets or prefixes

## Cost Optimization

- Use preemptible/spot instances for development
- Configure appropriate resource requests/limits
- Enable cluster autoscaler
- Use regional persistent disks for cost savings


