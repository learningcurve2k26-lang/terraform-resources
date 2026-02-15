output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "subnet_az" {
  description = "Map of public subnet IDs to their availability zones"
  value       = { for subnet in aws_subnet.public : subnet.id => subnet.availability_zone }
}

output "public_subnet_map" {
  description = "Map of availability zones to public subnet IDs"
  value       = { for subnet in aws_subnet.public : subnet.availability_zone => subnet.id }
}

output "private_subnet_map" {
  description = "Map of availability zones to private subnet IDs"
  value       = { for subnet in aws_subnet.private : subnet.availability_zone => subnet.id }
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_az_map" {
  description = "List of objects with public subnet id and availability zone"
  value = [for s in aws_subnet.public : {
    id                = s.id
    availability_zone = s.availability_zone
    type              = "public"
  }]
}

output "private_subnet_az_map" {
  description = "List of objects with private subnet id and availability zone"
  value = [for s in aws_subnet.private : {
    id                = s.id
    availability_zone = s.availability_zone
    type              = "private"
  }]
}

output "subnet_az_map" {
  description = "Combined list of public and private subnets with their AZs and type"
  value = concat(
    [for s in aws_subnet.public : { id = s.id, availability_zone = s.availability_zone, type = "public" }],
    [for s in aws_subnet.private : { id = s.id, availability_zone = s.availability_zone, type = "private" }]
  )
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "private_route_table_ids" {
  value = aws_route_table.private[*].id
}

output "public_route_table_ids" {
  value = aws_route_table.public[*].id
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}