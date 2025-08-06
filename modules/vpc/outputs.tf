
output "vpc_network_id" {
  value       = google_compute_network.vpc_network.id
  description = "ID of the created VPC"
}

output "subnet_ids" {
  value = {
    for k, v in google_compute_subnetwork.subnets :
    k => v.id
  }
  description = "Map of subnet names to their IDs"
}
