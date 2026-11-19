output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_id" {
  description = "ID of the primary public subnet"
  value       = aws_subnet.public.id
}

output "public_subnet_2_id" {
  description = "ID of the secondary public subnet (null if not provisioned)"
  value       = var.availability_zone_2 != null ? aws_subnet.public_2[0].id : null
}

output "public_subnet_ids" {
  description = "List of all public subnet IDs (for Multi-AZ ALB)"
  value       = concat([aws_subnet.public.id], var.availability_zone_2 != null ? [aws_subnet.public_2[0].id] : [])
}

output "private_subnet_id" {
  description = "ID of the private application subnet"
  value       = aws_subnet.private.id
}

output "secure_subnet_id" {
  description = "ID of the secure database subnet"
  value       = aws_subnet.secure.id
}

output "nat_gateway_public_ip" {
  description = "Elastic IP address attached to the NAT Gateway"
  value       = aws_eip.this.public_ip
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.this.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.this.id
}
