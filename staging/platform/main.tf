data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "sathish-terraform-state"
    key    = "staging/vpc/terraform.tfstate"
    region = "ap-south-1"
  }
}

locals {
    vpc_outputs = data.terraform_remote_state.vpc.outputs
}

module "security_group" {
  source = "../../modules/security_groups"

  environment = local.vpc_outputs.environment
  vpc_id      = local.vpc_outputs.vpc_id
}

# module "load_balancers" {
#   source = "../../modules/load_balancers"

#   environment                     = local.vpc_outputs.environment
#   vpc_id                          = local.vpc_outputs.vpc_id
#   subnet_ids                      = local.vpc_outputs.public_subnet_ids
#   worker_security_group_id        = module.security_group.worker_sg_id
#   control_plane_security_group_id = module.security_group.control_plane_sg_id
#   create_alb                      = true
#   create_nlb                      = true
  
#   depends_on = [ module.security_group ]
# }