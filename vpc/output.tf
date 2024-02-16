output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet" {
  value = module.vpc.public_subnet
}

output "key_name" {
  value = module.ssh.key_name
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = module.vpc.security_group_id
}

output "ec2_ip" {
  value = module.ec2.ec2_ip
}