output "repositories" {
  description = "Map of repository names to full repository URLs"
  value = {
    for name, repo in google_artifact_registry_repository.gcr_repos :
    name => repo.name
  }
}
