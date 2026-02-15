output "instance_ids" {
  description = "Map of instance keys to instance IDs"
  value       = { for k, v in aws_instance.main : k => v.id }
}

output "private_ips" {
  description = "Map of instance keys to private IP addresses"
  value       = { for k, v in aws_instance.main : k => v.private_ip }
}

output "public_ips" {
  description = "Map of instance keys to public IP addresses"
  value       = { for k, v in aws_instance.main : k => v.public_ip }
}

output "availability_zones" {
  description = "Map of instance keys to availability zones"
  value       = { for k, v in aws_instance.main : k => v.availability_zone }
}

output "instances" {
  description = "Complete instance details"
  value = {
    for k, v in aws_instance.main : k => {
      id                = v.id
      private_ip        = v.private_ip
      public_ip         = v.public_ip
      availability_zone = v.availability_zone
      instance_type     = v.instance_type
      subnet_id         = v.subnet_id
    }
  }
}
