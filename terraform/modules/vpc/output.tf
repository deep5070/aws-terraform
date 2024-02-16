output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnet" {
  value = aws_subnet.public[0].id
}


output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.main.id
}
