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
