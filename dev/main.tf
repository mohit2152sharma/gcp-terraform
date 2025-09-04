# Create gcr repositories, pass the names of repo in the list
module "globals" {
  source = "../modules/commons"
}

module "gcr" {
  source     = "../modules/gcr"
  repo_names = ["service-a", "service-b", "frontend-app"]
  location   = module.globals.region
  project_id = module.globals.project_id
  labels     = module.globals.labels
}

module "gke" {
  source = "../modules/gke"

  name       = "dev-gke-cluster"
  project_id = module.globals.project_id
  location   = module.globals.region

  # Use VPC created in vpc.tf
  network                       = module.vpc.vpc_network_id
  subnetwork                   = "projects/${module.globals.project_id}/regions/${module.globals.region}/subnetworks/dev-subnet-2"
  secondary_range_name_pods     = "pods"
  secondary_range_name_services = "services"

  # Private cluster configuration
  enable_private_nodes     = true
  enable_private_endpoint  = false
  master_ipv4_cidr_block  = "172.16.0.0/28"

  # Allow access from the VPC subnet
  master_authorized_networks = [
    {
      cidr_block   = "10.0.0.0/16"
      display_name = "VPC CIDR"
    }
  ]

  # Node pool configuration
  node_pools = [
    {
      name           = "default-pool"
      machine_type   = "e2-standard-2"
      min_node_count = 1
      max_node_count = 3
      disk_size_gb   = 30
      disk_type      = "pd-standard"
      preemptible    = false
      oauth_scopes   = ["https://www.googleapis.com/auth/cloud-platform"]
      
      labels = merge(module.globals.labels, {
        environment = "dev"
        node-pool   = "default"
      })
      
      tags = ["dev", "gke-node"]
    }
  ]

  # Addons
  enable_network_policy              = true
  enable_http_load_balancing        = true
  enable_horizontal_pod_autoscaling = true
  enable_vertical_pod_autoscaling   = false

  labels = module.globals.labels
}
