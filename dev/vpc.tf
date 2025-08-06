module "vpc" {
  source                  = "../modules/vpc"
  name                    = "dev-vpc"
  project_id              = module.globals.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  subnets = [
    {
      name          = "dev-subnet-1"
      ip_cidr_range = "10.0.0.0/24"
      region        = module.globals.region
    },
    {
      name          = "dev-subnet-2"
      ip_cidr_range = "10.0.1.0/24"
      region        = module.globals.region
      secondary_ip_ranges = [
        {
          range_name    = "pods"
          ip_cidr_range = "10.4.0.0/16"
        },
        {
          range_name    = "services"
          ip_cidr_range = "10.5.0.0/20"
        }
      ]
    }
  ]
}
