# state-bucket.tf
provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "tf_state" {
  name          = var.bucket_name
  location      = var.region
  force_destroy = true

  versioning {
    enabled = true
  }
}

variable "project_id" {
  type    = string
  default = "saral-458210"
}
variable "region" {
  type    = string
  default = "asia-south1"
}

variable "bucket_name" {
  type    = string
  default = "apna-terraform-state"
}
