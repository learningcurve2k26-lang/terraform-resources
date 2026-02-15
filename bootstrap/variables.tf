variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.state_bucket_name)) && length(var.state_bucket_name) >= 3 && length(var.state_bucket_name) <= 63
    error_message = "Bucket name must be between 3-63 characters, lowercase alphanumeric with hyphens, and cannot start or end with hyphen."
  }
}

variable "aws_external_id" {
  description = "External ID for assuming the AWS role"
  type        = string
  sensitive = true
}
