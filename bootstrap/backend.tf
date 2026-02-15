terraform {
  backend "s3" {
    # Configure using: terraform init -backend-config=../bootstrap/backend.tfvars
    # Or manually set: bucket, dynamodb_table, key, region, encrypt
    bucket = "sathish-terraform-state"
    key = "bootstrap/terraform.tfstate"
    region = "ap-south-1"
    encrypt = true
    use_lockfile = true
  }
}