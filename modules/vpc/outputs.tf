
output "vpc_network_id" {
  value       = google_compute_network.vpc_network.id
  description = "ID of the created VPC"
}

output "vpc_network_name" {
  value       = google_compute_network.vpc_network.name
  description = "Name of the created VPC"
}

output "vpc_network_self_link" {
  value       = google_compute_network.vpc_network.self_link
  description = "Self-link of the created VPC"
}

output "subnet_ids" {
  value = {
    for k, v in google_compute_subnetwork.subnets :
    k => v.id
  }
  description = "Map of subnet names to their IDs"
}

output "subnet_self_links" {
  value = {
    for k, v in google_compute_subnetwork.subnets :
    k => v.self_link
  }
  description = "Map of subnet names to their self-links"
}

output "subnet_ip_cidr_ranges" {
  value = {
    for k, v in google_compute_subnetwork.subnets :
    k => v.ip_cidr_range
  }
  description = "Map of subnet names to their CIDR ranges"
}

output "subnet_secondary_ranges" {
  value = {
    for k, v in google_compute_subnetwork.subnets :
    k => v.secondary_ip_range
  }
  description = "Map of subnet names to their secondary IP ranges"
}
