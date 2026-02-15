output "control_plane_sg_id" {
  description = "Control plane security group ID"
  value       = module.security_group.control_plane_sg_id
}

output "control_plane_sg_name" {
  description = "Control plane security group name"
  value       = module.security_group.control_plane_sg_name
}

output "worker_sg_id" {
  description = "Worker security group ID"
  value       = module.security_group.worker_sg_id
}

output "worker_sg_name" {
  description = "Worker security group name"
  value       = module.security_group.worker_sg_name
}

# ========================================
# Load Balancer Outputs
# ========================================

# output "gateway_alb_dns_name" {
#   description = "DNS name of the Traefik ALB"
#   value       = module.load_balancers.gateway_alb_dns_name
# }

# output "gateway_alb_arn" {
#   description = "ARN of the Traefik ALB"
#   value       = module.load_balancers.gateway_alb_arn
# }

# output "gateway_https_target_group_arn" {
#   description = "ARN of the Traefik HTTPS target group"
#   value       = module.load_balancers.gateway_https_target_group_arn
# }

# output "api_server_nlb_dns_name" {
#   description = "DNS name of the API Server NLB"
#   value       = module.load_balancers.api_server_nlb_dns_name
# }

# output "api_server_nlb_arn" {
#   description = "ARN of the API Server NLB"
#   value       = module.load_balancers.api_server_nlb_arn
# }

# output "api_server_target_group_arn" {
#   description = "ARN of the API Server target group"
#   value       = module.load_balancers.api_server_target_group_arn
# }

# output "gateway_alb_security_group_id" {
#   description = "Security group ID for Traefik ALB"
#   value       = module.load_balancers.gateway_alb_security_group_id
# }

# output "api_server_nlb_security_group_id" {
#   description = "Security group ID for API Server NLB"
#   value       = module.load_balancers.api_server_nlb_security_group_id
# }
