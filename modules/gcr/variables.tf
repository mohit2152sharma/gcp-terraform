variable "repo_names" {
  description = "List of GCR repository names to create"
  type        = list(string)
}

variable "project_id" {
  description = "The gcp project id"
  type        = string
}

variable "labels" {
  description = "Labels for the resource"
  type        = map(string)
}

variable "location" {
  description = "Location/region for GCR (e.g. us-central1)"
  type        = string
}
