variable "ami_name_pattern" {
  description = "AMI name pattern to search for"
  type        = string
}

variable "ami_owner" {
  description = "Owner ID for the AMI"
  type        = string
  default     = "099720109477" # Canonical
}

variable "availability_zone" {
  description = "Availability zone to launch the instance in (not needed when using instances variable)"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_type" {
  description = "Default EC2 instance type (used as fallback if not specified per instance)"
  type        = string
  default     = "t3.medium"
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
  validation {
    condition     = var.instance_count > 0
    error_message = "Instance count must be greater than 0."
  }
}

variable "instance_name_prefix" {
  description = "Prefix for instance names"
  type        = string
}

variable "subnet_id" {
  description = "List of subnet IDs where instances will be launched (not needed when using instances variable with subnet_map)"
  type        = list(string)
  default     = []
}

variable "security_group_id" {
  description = "Security group ID"
  type        = list(string)
}

variable "iam_instance_profile" {
  description = "IAM instance profile name"
  type        = string
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
  validation {
    condition     = var.root_volume_size >= 20
    error_message = "Root volume size must be at least 20 GB."
  }
}

variable "root_volume_type" {
  description = "Root volume type (gp2, gp3, io1, etc.)"
  type        = string
  default     = "gp3"
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2", "st1", "sc1"], var.root_volume_type)
    error_message = "Invalid volume type."
  }
}

variable "key_pair_name" {
  description = "EC2 Key Pair name"
  type        = string
}

variable "associate_public_ip" {
  description = "Whether to associate public IP"
  type        = list(bool)
  default     = []
}

variable "tags" {
  description = "Tags to apply to instances"
  type        = map(string)
  default     = {}
}

variable "instances" {
  description = <<-EOT
  Optional map of per-instance configuration. When provided, the module will
  create one EC2 instance per map entry using the settings below. Each map
  value should be an object with optional keys:
    - subnet_id (string)
    - availability_zone (string)
    - associate_public_ip (bool)
    - key_name (string)
    - instance_type (string)
    - use_spot (bool) - Whether to request a spot instance
    - spot_max_price (string) - Maximum price for spot instance (per hour)
    - spot_interruption_behavior (string) - "terminate" or "stop" (default: "terminate")
  EOT
  type = map(object({
    subnet_id                    = optional(string)
    availability_zone            = optional(string)
    associate_public_ip          = optional(bool)
    instance_type                = optional(string)
    name                         = optional(string)
    use_spot                     = optional(bool)
    spot_max_price               = optional(string)
    spot_interruption_behavior   = optional(string)
  }))
  default = {}
}

variable "subnet_map" {
  description = "Optional map of availability_zone -> subnet_id for selecting subnets by AZ"
  type        = map(string)
  default     = {}
}

variable "target_group_arns" {
  description = "List of target group ARNs to attach instances to"
  type        = list(string)
  default     = []
}
