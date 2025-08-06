terraform {
  backend "gcs" {
    bucket = "apna-terraform-state"
    prefix = "terraform/dev"
  }
}
