module "vpc" {
  source = "../../modules/vpc"

  environment        = "staging"
  vpc_cidr          = "10.31.0.0/16"
  public_subnet_availability_zones = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}