output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs across both AZs"
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs across both AZs"
  value       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

output "nat_gateway_public_ip" {
  description = "Elastic IP attached to the NAT Gateway"
  value       = aws_eip.this.public_ip
}
