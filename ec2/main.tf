module "ec2" {
  source     = "../terraform/modules/ec2/"
  public_sub = module.vpc.public_subnet
}  