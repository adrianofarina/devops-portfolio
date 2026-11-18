output "vpc_id" {
  description = "ID of the provisioned VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  description = "ID of the private application subnet"
  value       = module.vpc.private_subnet_id
}

output "secure_subnet_id" {
  description = "ID of the secure database subnet"
  value       = module.vpc.secure_subnet_id
}

output "nat_gateway_public_ip" {
  description = "Elastic IP address attached to the NAT Gateway"
  value       = module.vpc.nat_gateway_public_ip
}
