# Kubernetes and Helm provider configuration
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Get cluster info from remote state or data sources
data "terraform_remote_state" "infrastructure" {
  backend = "gcs"
  config = {
    bucket = "apna-terraform-state"
    prefix = "terraform/dev"
  }
}

# Configure Kubernetes provider
provider "kubernetes" {
  host                   = data.terraform_remote_state.infrastructure.outputs.gke_cluster_endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.terraform_remote_state.infrastructure.outputs.gke_cluster_ca_certificate)
}

# Configure Helm provider
provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.infrastructure.outputs.gke_cluster_endpoint
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.terraform_remote_state.infrastructure.outputs.gke_cluster_ca_certificate)
  }
}

data "google_client_config" "default" {}
