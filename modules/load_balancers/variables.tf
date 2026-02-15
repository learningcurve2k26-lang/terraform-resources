variable "environment" {
  description = "Environment name"
  type        = string
}

variable "create_alb" {
  description = "Whether to create the Gateway ALB for application traffic"
  type        = bool
  default     = false
}

variable "create_nlb" {
  description = "Whether to create the API Server NLB for control plane"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID where load balancers will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for load balancer (should span public and private subnets)"
  type        = list(string)
}

variable "worker_security_group_id" {
  description = "Worker nodes security group ID"
  type        = string
}

variable "control_plane_security_group_id" {
  description = "Control plane nodes security group ID (required only if create_nlb = true)"
  type        = string
  default     = null
}

variable "api_server_allowed_cidrs" {
  description = "CIDR blocks allowed to access API Server NLB (e.g., your local IP, CI/CD)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "gateway_certificate_arn" {
  description = "ARN of ACM certificate for HTTPS listener (optional)"
  type        = string
  default     = ""
}
