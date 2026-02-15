output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "subnet_az" {
  description = "Map of public subnet IDs to their availability zones"
  value       = module.vpc.subnet_az
}

output "public_subnet_map" {
  description = "Map of availability zones to public subnet IDs"
  value       = module.vpc.public_subnet_map
}

output "private_subnet_map" {
  description = "Map of availability zones to private subnet IDs"
  value       = module.vpc.private_subnet_map
}

output "public_subnet_az_map" {
  description = "List of objects with public subnet id and availability zone"
  value       = module.vpc.public_subnet_az_map
}

output "private_subnet_az_map" {
  description = "List of objects with private subnet id and availability zone"
  value       = module.vpc.private_subnet_az_map
}

output "subnet_az_map" {
  description = "Combined list of public and private subnets with their AZs and type"
  value       = module.vpc.subnet_az_map
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.nat_gateway_ids
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = module.vpc.internet_gateway_id
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = module.vpc.private_route_table_ids
}

output "public_route_table_ids" {
  description = "List of public route table IDs"
  value       = module.vpc.public_route_table_ids
}

output "environment" {
  description = "Environment name"
  value       = module.vpc.environment
}
