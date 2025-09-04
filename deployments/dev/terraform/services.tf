# Deploy services using the common helm chart
resource "helm_release" "services" {
  for_each = { for k, v in var.services : k => v if v.enabled }

  name      = each.key
  chart     = "../../../helm charts/helm_chart/common"
  namespace = var.namespace

  # Override default values with GCP/GKE specific configurations
  values = [
    yamlencode({
      # Global configuration adapted for GCP
      global = {
        gcpProjectId = var.project_id
        gcpRegion    = var.region
        env          = var.environment
      }

      # Service configuration
      image = "${each.value.image}:${each.value.tag}"
      
      # Replica configuration
      replicaCount = each.value.replicas

      # Service ports
      service = {
        type       = "ClusterIP"
        port       = each.value.port
        targetPort = each.value.target_port
      }

      # Resources
      resources = each.value.resources

      # Autoscaling
      autoscaling = each.value.autoscaling

      # Environment variables
      env = each.value.env_vars

      # Config maps
      configMap = length(each.value.config_maps) > 0 ? each.value.config_maps : null

      # Health checks
      healthCheck = each.value.health_check_path

      # Ingress configuration for GKE
      ingress = {
        enabled = true
        className = "nginx"
        annotations = merge(
          {
            "nginx.ingress.kubernetes.io/rewrite-target" = "/"
            "nginx.ingress.kubernetes.io/ssl-redirect"   = "true"
          },
          var.domain_name != "" ? {
            "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
          } : {}
        )
        
        hosts = [
          for host in each.value.hosts : {
            host = host
            paths = [
              for path in each.value.paths : {
                path     = path
                pathType = "Prefix"
                backend = {
                  service = {
                    name = "${each.key}-service"
                    port = {
                      number = each.value.port
                    }
                  }
                }
              }
            ]
          }
        ]

        tls = var.domain_name != "" ? [
          {
            secretName = "${each.key}-tls"
            hosts      = each.value.hosts
          }
        ] : []
      }

      # Namespace
      namespaceOverride = var.namespace

      # Secrets (if any)
      secrets = length(each.value.secrets) > 0 ? each.value.secrets : null

      # Probes configuration
      probes = {
        readiness = {
          initialDelaySeconds = 30
        }
        liveness = {
          initialDelaySeconds = 15
        }
      }

      # Node selector and tolerations for GKE
      nodeSelector = {
        "cloud.google.com/gke-nodepool" = "default-pool"
      }

      # Pod disruption budget
      podDisruptionBudget = {
        enabled      = true
        minAvailable = 1
      }
    })
  ]

  depends_on = [
    helm_release.nginx_ingress,
    kubernetes_namespace.app_namespace
  ]
}
