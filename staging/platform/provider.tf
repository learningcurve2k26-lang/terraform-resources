terraform {
  backend "s3" {
    # Configure using: terraform init -backend-config=../bootstrap/backend.tfvars
    # Or manually set: bucket, dynamodb_table, key, region, encrypt
    bucket = "sathish-terraform-state"
    key = "staging/platform/security_lb.tfstate"
    region = "ap-south-1"
    encrypt = true
    use_lockfile = true
  }
}

terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}