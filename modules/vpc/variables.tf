variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnet_prefix" {
  description = "Desired prefix length for subnets (for example 24 for /24 subnets)"
  type        = number
  default     = 24
  validation {
    condition     = var.subnet_prefix > tonumber(split("/", var.vpc_cidr)[1])
    error_message = "subnet_prefix must be a longer mask (larger number) than the VPC CIDR prefix."
  }
}

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access"
  type        = bool
  default     = false
}

variable "public_subnet_availability_zones" {
  description = "List of availability zones for public subnets"
  type        = list(string)
}

variable "private_subnet_availability_zones" {
  description = "List of availability zones for private subnets"
  type        = list(string)
  default = [ ]
}