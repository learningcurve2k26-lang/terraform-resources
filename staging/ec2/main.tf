# Remote state for network (VPC, subnets)
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "sathish-terraform-state"
    key    = "staging/vpc/terraform.tfstate"
    region = "ap-south-1"
  }
}

# Remote state for platform (security groups, load balancers)
data "terraform_remote_state" "platform" {
  backend = "s3"
  config = {
    bucket = "sathish-terraform-state"
    key    = "staging/platform/security_lb.tfstate"
    region = "ap-south-1"
  }
}

# SSH Key Pair for EC2 instances
resource "aws_key_pair" "k8s_cluster" {
  key_name   = "staging-k8s-cluster-key"
  public_key = file("~/.ssh/myself.pub")

  tags = {
    Environment = data.terraform_remote_state.network.outputs.environment
    ManagedBy   = "Terraform"
  }
}

# Control Plane Instances
module "single_node_cluster" {
  source = "../../modules/ec2"

  environment          = data.terraform_remote_state.network.outputs.environment
  instance_name_prefix = "staging-single-node-cluster"

  # Define instances with specific AZ placement
  instances = {
    single-1 = {
      availability_zone   = "ap-south-1c"
      instance_type       = "t3.large"
      name                = "staging-single-node-cluster-1"
      associate_public_ip = false # Using Elastic IP instead
      # Using on-demand (not spot) for manual stop/start control
      use_spot = false
    }
  }


  # Ubuntu 22.04 LTS
  ami_name_pattern = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  ami_owner        = "099720109477" # Canonical

  # Network configuration
  subnet_map = data.terraform_remote_state.network.outputs.public_subnet_map

  # Security
  security_group_id = [data.terraform_remote_state.platform.outputs.control_plane_sg_id, data.terraform_remote_state.platform.outputs.worker_sg_id]
  key_pair_name     = aws_key_pair.k8s_cluster.key_name

  # IAM (optional - create IAM role separately if needed)
  iam_instance_profile = "" # Leave empty for now or create IAM role

  # Storage
  root_volume_size = 60
  root_volume_type = "gp3"

  # Tags
  tags = {
    Environment = data.terraform_remote_state.network.outputs.environment
    Role        = "control-plane"
    ManagedBy   = "Terraform"
  }
}

# Elastic IP for single node cluster (static IP for DNS)
resource "aws_eip" "single_node" {
  domain = "vpc"

  tags = {
    Name        = "staging-single-node-eip"
    Environment = data.terraform_remote_state.network.outputs.environment
    ManagedBy   = "Terraform"
  }
}

# Associate Elastic IP with single node instance
resource "aws_eip_association" "single_node" {
  instance_id   = module.single_node_cluster.instance_ids["single-1"]
  allocation_id = aws_eip.single_node.id
}

# Worker Instances
# module "workers" {
#   source = "../../modules/ec2"

#   environment          = data.terraform_remote_state.network.outputs.environment
#   instance_name_prefix = "staging-worker"

#   # Define instances with specific AZ placement
#   instances = {
#     worker-1 = {
#       availability_zone   = "ap-south-1a"
#       instance_type       = "t3.large"
#       name                = "staging-worker-1"
#       associate_public_ip = true
#       use_spot            = true    # Use spot instance for cost savings
#       spot_max_price      = "0.025" # Max $0.025/hour (current t3.large spot ~$0.018/hr)
#     }
#   }

#   # Ubuntu 22.04 LTS
#   ami_name_pattern = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
#   ami_owner        = "099720109477" # Canonical

#   # Network configuration
#   subnet_map = data.terraform_remote_state.network.outputs.public_subnet_map

#   # Security
#   security_group_id = data.terraform_remote_state.platform.outputs.worker_sg_id
#   key_pair_name     = aws_key_pair.k8s_cluster.key_name

#   # IAM (optional - create IAM role separately if needed)
#   iam_instance_profile = "" # Leave empty for now or create IAM role

#   # Storage
#   root_volume_size = 50
#   root_volume_type = "gp3"

#   # Auto-register to Traefik ALB
#   # target_group_arns = [
#   #   data.terraform_remote_state.platform.outputs.gateway_https_target_group_arn
#   # ]

#   # Tags
#   tags = {
#     Environment = data.terraform_remote_state.network.outputs.environment
#     Role        = "worker"
#     ManagedBy   = "Terraform"
#   }
# }
