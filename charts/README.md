# Helm Charts

This directory contains modular and composable Helm charts for deploying applications to Kubernetes.

## Structure

```
charts/
├── library/
│   └── common/           # Reusable library chart with common templates
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
└── apps/
    └── sample-web-app/   # Example application using the common library
        ├── Chart.yaml
        ├── values.yaml
        ├── values-dev.yaml
        ├── values-staging.yaml
        ├── values-prod.yaml
        └── templates/
```

## Library Chart (`library/common`)

The common library provides reusable templates for:

- **Deployment** - Configurable deployment with health checks, resources, etc.
- **Service** - Standard Kubernetes service
- **Ingress** - Flexible ingress configuration
- **HPA** - Horizontal Pod Autoscaler
- **ConfigMap** - Application configuration
- **Secret** - Sensitive data management
- **ServiceAccount** - RBAC configuration

## Usage

### Installing the Sample App

```bash
# Development environment
helm install sample-web-app charts/apps/sample-web-app -f charts/apps/sample-web-app/values-dev.yaml

# Staging environment
helm install sample-web-app charts/apps/sample-web-app -f charts/apps/sample-web-app/values-staging.yaml

# Production environment
helm install sample-web-app charts/apps/sample-web-app -f charts/apps/sample-web-app/values-prod.yaml
```

### Creating a New Application

1. Create a new directory under `charts/apps/your-app/`
2. Copy the structure from `sample-web-app`
3. Update `Chart.yaml` with your app details
4. Customize `values.yaml` for your application
5. Create environment-specific values files as needed

### Template Usage

In your application templates, simply include the common templates:

```yaml
# templates/deployment.yaml
{{- include "common.deployment" . }}

# templates/service.yaml
{{- include "common.service" . }}

# templates/ingress.yaml
{{- include "common.ingress" . }}
```

## Features

### ✅ Modular Design
- Library chart with reusable templates
- Application charts with minimal boilerplate
- Environment-specific configuration

### ✅ Production Ready
- Health checks and probes
- Resource management
- Horizontal Pod Autoscaling
- Security contexts
- Topology spread constraints

### ✅ Multi-Environment Support
- Separate values files for dev/staging/prod
- Environment-specific configurations
- Flexible overrides

### ✅ Best Practices
- Proper labeling and annotations
- ConfigMaps and Secrets management
- Service accounts with RBAC
- Rolling updates with zero downtime

## Available Templates

| Template | Description | Usage |
|----------|-------------|-------|
| `common.deployment` | Kubernetes Deployment | `{{- include "common.deployment" . }}` |
| `common.service` | Kubernetes Service | `{{- include "common.service" . }}` |
| `common.ingress` | Kubernetes Ingress | `{{- include "common.ingress" . }}` |
| `common.hpa` | Horizontal Pod Autoscaler | `{{- include "common.hpa" . }}` |
| `common.configmap` | ConfigMap | `{{- include "common.configmap" . }}` |
| `common.secret` | Secret | `{{- include "common.secret" . }}` |
| `common.serviceaccount` | ServiceAccount | `{{- include "common.serviceaccount" . }}` |

## Configuration Examples

### Basic Web App
```yaml
app:
  name: "my-web-app"
  port: 3000
  healthCheck: "/health"

image:
  repository: "my-app"
  tag: "1.0.0"

service:
  port: 80
  targetPort: 3000

ingress:
  enabled: true
  hosts:
    - host: my-app.example.com
      paths:
        - path: /
```

### With Autoscaling
```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

### With ConfigMap and Secrets
```yaml
configMap:
  enabled: true
  data:
    DATABASE_HOST: "db.example.com"
    CACHE_TTL: "3600"

secrets:
  enabled: true
  data:
    DATABASE_PASSWORD: "base64-encoded-password"
    API_KEY: "base64-encoded-key"
```

## Development

### Testing Charts
```bash
# Lint the charts
helm lint charts/apps/sample-web-app/

# Template and validate
helm template sample-web-app charts/apps/sample-web-app/

# Dry run
helm install --dry-run sample-web-app charts/apps/sample-web-app/
```

### Dependencies
```bash
# Update chart dependencies
helm dependency update charts/apps/sample-web-app/
```
