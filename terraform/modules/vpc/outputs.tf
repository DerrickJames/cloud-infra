output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr" {
  value       = aws_vpc.vpc.cidr_block
}

output "public_subnets" {
  value = {
    for subnet in aws_subnet.public_subnet : subnet.id => subnet.cidr_block
  }
}

output "private_subnets" {
  value = {
    for subnet in aws_subnet.private_subnet : subnet.id => subnet.cidr_block
  }
}

output "public_security_group_id" {
  value = aws_security_group.public_sg.id
}

output "private_security_group_id" {
  value = aws_security_group.private_sg.id
}