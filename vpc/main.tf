terraform {
  required_version = ">= 0.14"
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source      = "../terraform/modules/vpc/"
  name_prefix = var.name_prefix
  cidr_block  = "10.100.0.0/16"

  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e"]


  public_subnet_cidrs = [
    "10.100.0.0/20",
    "10.100.16.0/20",
    "10.100.32.0/20",
  ]

  tags = {
    terraform = "True"
  }
}

module "ec2" {
  source         = "../terraform/modules/ec2/"
  public_sub     = module.vpc.public_subnet
  key_name       = module.ssh.key_name
  security_group = module.vpc.security_group_id
}

module "ssh" {
  source = "../terraform/modules/ssh_key/"
}

module "autoscaling" {
  source         = "../terraform/modules/autoscaling/"
  security_group = module.vpc.security_group_id
  name_prefix    = var.name_prefix
  public_sub     = module.vpc.public_subnet
}