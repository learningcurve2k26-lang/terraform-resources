output "gateway_alb_dns_name" {
  description = "DNS name of the Gateway ALB"
  value       = var.create_alb ? aws_lb.gateway[0].dns_name : null
}

output "gateway_alb_arn" {
  description = "ARN of the Gateway ALB"
  value       = var.create_alb ? aws_lb.gateway[0].arn : null
}

output "gateway_alb_zone_id" {
  description = "Zone ID of the Gateway ALB"
  value       = var.create_alb ? aws_lb.gateway[0].zone_id : null
}

output "gateway_https_target_group_arn" {
  description = "ARN of the Gateway HTTPS target group"
  value       = var.create_alb ? aws_lb_target_group.gateway_https[0].arn : null
}

output "api_server_nlb_dns_name" {
  description = "DNS name of the API Server NLB"
  value       = var.create_nlb ? aws_lb.api_server[0].dns_name : null
}

output "api_server_nlb_arn" {
  description = "ARN of the API Server NLB"
  value       = var.create_nlb ? aws_lb.api_server[0].arn : null
}

output "api_server_nlb_zone_id" {
  description = "Zone ID of the API Server NLB"
  value       = var.create_nlb ? aws_lb.api_server[0].zone_id : null
}

output "api_server_target_group_arn" {
  description = "ARN of the API Server target group"
  value       = var.create_nlb ? aws_lb_target_group.api_server[0].arn : null
}

output "gateway_alb_security_group_id" {
  description = "Security group ID for Gateway ALB"
  value       = var.create_alb ? aws_security_group.gateway_alb[0].id : null
}

output "api_server_nlb_security_group_id" {
  description = "Security group ID for API Server NLB"
  value       = var.create_nlb ? aws_security_group.api_server_nlb[0].id : null
}
