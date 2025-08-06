resource "google_artifact_registry_repository" "gcr_repos" {
  for_each      = toset(var.repo_names)
  project       = var.project_id
  location      = var.location
  repository_id = each.value
  format        = "DOCKER"
  description   = "GCR Docker repository: ${each.value}"
  labels        = var.labels
}
