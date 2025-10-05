# Create gcr repositories, pass the names of repo in the list
locals {
  env = "dev"
}


module "globals" {
  source      = "../modules/commons"
  environment = local.env
}

module "gcr" {
  source     = "../modules/gcr"
  repo_names = ["opentelemetry", "voice-agent"]
  location   = module.globals.region
  project_id = module.globals.project_id
  labels     = module.globals.labels
  env_prefix = local.env
}

# Service Accounts for Dev Environment
module "service_accounts" {
  source = "../modules/service_account"
  
  project_id  = module.globals.project_id
  environment = local.env
  
  service_accounts = [
    {
      account_id   = "github-actions"
      display_name = "GitHub Actions Service Account"
      description  = "Service account for GitHub Actions CI/CD pipelines"
      
      project_roles = [
        "roles/container.admin",           # Container/GKE management
        "roles/artifactregistry.writer"    # Push images to Artifact Registry
      ]
      
      # Service-specific labels merged with commons labels
      labels = {
        purpose        = "ci-cd"
        system         = "github-actions"
        component      = "automation"
        access_type    = "service"
        deployment     = "github-workflow"
      }
    }
  ]
  
  # Pass commons module labels as global labels
  global_labels = module.globals.labels
}

# GKE Cluster for Dev Environment
module "gke" {
  source = "../modules/gke"
  
  # Environment and basic configuration
  environment = local.env
  project_id  = module.globals.project_id
  name        = "${local.env}-gke-cluster"
  location    = module.globals.region
  
  # Network configuration - using the VPC and subnet with secondary ranges
  network    = module.vpc.vpc_network_name
  subnetwork = module.vpc.subnet_self_links["dev-subnet-2"]
  
  # Node locations for multi-zone deployment
  node_locations = ["${module.globals.region}-a", "${module.globals.region}-b"]
  
  # Secondary IP ranges for pods and services (defined in vpc.tf)
  secondary_range_name_pods     = "pods"
  secondary_range_name_services = "services"
  
  # Use environment-specific defaults for logging/monitoring (dev environment)
  # This will automatically use basic logging and monitoring suitable for dev
  
  # Workload Identity: map different namespaces KSAs -> GSAs
  workload_identity_mappings = [
    {
      namespace  = "default"
      ksa_name   = "workload"
      create_gsa = true
      gsa_name   = "gke-default-workload"
      roles      = [
        "roles/secretmanager.secretAccessor",
        "roles/logging.logWriter",
        "roles/monitoring.metricWriter",
      ]
      create_ksa = false
    },
    {
      namespace  = "observability"
      ksa_name   = "collector"
      create_gsa = true
      gsa_name   = "gke-observability-collector"
      roles      = [
        "roles/logging.logWriter",
        "roles/monitoring.metricWriter",
        "roles/cloudtrace.agent",
      ]
      create_ksa = false
    }
  ]

  # Labels from commons module
  labels = module.globals.labels
  
  # Dependencies
  depends_on = [module.vpc]
}

