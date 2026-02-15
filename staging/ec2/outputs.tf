# Single Node Cluster Outputs
output "single_node_instance_id" {
  description = "Instance ID of the single node cluster"
  value       = module.single_node_cluster.instance_ids["single-1"]
}

output "single_node_private_ip" {
  description = "Private IP address of the single node cluster"
  value       = module.single_node_cluster.private_ips["single-1"]
}

output "single_node_public_ip" {
  description = "Elastic IP address of the single node cluster (static)"
  value       = aws_eip.single_node.public_ip
}

output "single_node_availability_zone" {
  description = "Availability zone of the single node cluster"
  value       = module.single_node_cluster.availability_zones["single-1"]
}

# Worker Outputs (commented out)
# output "worker_instance_ids" {
#   description = "Map of worker instance keys to instance IDs"
#   value       = module.workers.instance_ids
# }

# output "worker_private_ips" {
#   description = "Map of worker instance keys to private IP addresses"
#   value       = module.workers.private_ips
# }

# output "worker_public_ips" {
#   description = "Map of worker instance keys to public IP addresses"
#   value       = module.workers.public_ips
# }

# output "worker_availability_zones" {
#   description = "Map of worker instance keys to availability zones"
#   value       = module.workers.availability_zones
# }

# output "worker_instances" {
#   description = "Complete worker instance details"
#   value       = module.workers.instances
# }