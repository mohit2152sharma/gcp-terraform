output "nginx_ingress_ip" {
  value = var.enable_nginx_ingress ? (
    length(helm_release.nginx_ingress) > 0 ? 
    data.kubernetes_service.nginx_ingress_controller[0].status[0].load_balancer[0].ingress[0].ip : 
    null
  ) : null
  description = "External IP address of the NGINX Ingress Controller"
}

output "services_deployed" {
  value = {
    for k, v in helm_release.services : k => {
      name      = v.name
      namespace = v.namespace
      chart     = v.chart
      version   = v.version
      status    = v.status
    }
  }
  description = "Information about deployed services"
}

output "cluster_info" {
  value = {
    cluster_name     = data.terraform_remote_state.infrastructure.outputs.gke_cluster_name
    cluster_endpoint = data.terraform_remote_state.infrastructure.outputs.gke_cluster_endpoint
    cluster_location = data.terraform_remote_state.infrastructure.outputs.gke_cluster_location
  }
  description = "GKE cluster information"
  sensitive = true
}

output "namespaces_created" {
  value = concat(
    var.enable_nginx_ingress ? ["ingress-nginx"] : [],
    var.enable_cert_manager ? ["cert-manager"] : [],
    var.namespace != "default" ? [var.namespace] : []
  )
  description = "List of namespaces created"
}

# Data source to get NGINX Ingress Controller service info
data "kubernetes_service" "nginx_ingress_controller" {
  count = var.enable_nginx_ingress ? 1 : 0

  metadata {
    name      = "nginx-ingress-ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [
    helm_release.nginx_ingress
  ]
}
