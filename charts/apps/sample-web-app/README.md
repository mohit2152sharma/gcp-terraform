# Sample Web App Chart

A sample web application chart demonstrating the usage of the common library chart.

## Installation

```bash
# Add the dependency
helm dependency update

# Install for development
helm install my-sample-app . -f values-dev.yaml

# Install for staging
helm install my-sample-app . -f values-staging.yaml

# Install for production
helm install my-sample-app . -f values-prod.yaml
```

## Configuration

This chart supports all configuration options from the common library. See the main [charts README](../../README.md) for detailed configuration options.

### Key Configuration Sections

- `global.*` - Global settings (environment, registry, etc.)
- `app.*` - Application-specific settings
- `image.*` - Container image configuration
- `service.*` - Kubernetes service configuration
- `ingress.*` - Ingress/load balancer configuration
- `resources.*` - CPU/memory limits and requests
- `autoscaling.*` - Horizontal Pod Autoscaler settings
- `env.*` - Environment variables
- `configMap.*` - Configuration data
- `secrets.*` - Sensitive data

### Environment-Specific Values

- `values-dev.yaml` - Development environment (1 replica, debug logging)
- `values-staging.yaml` - Staging environment (2 replicas, autoscaling)
- `values-prod.yaml` - Production environment (3+ replicas, production optimizations)

## Customization

To customize this chart for your application:

1. Update `Chart.yaml` with your application details
2. Modify `values.yaml` with your default configuration
3. Adjust environment-specific values files
4. Add any application-specific templates if needed
