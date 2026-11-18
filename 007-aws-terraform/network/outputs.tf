output "vpc_id" {
  description = "ID of the provisioned VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_id" {
  description = "ID of the primary public subnet"
  value       = module.vpc.public_subnet_id
}

output "public_subnet_2_id" {
  description = "ID of the secondary public subnet"
  value       = module.vpc.public_subnet_2_id
}

output "public_subnet_ids" {
  description = "List of all public subnet IDs (for Multi-AZ ALB)"
  value       = module.vpc.public_subnet_ids
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

# AWS Budgets Outputs
output "budget_name" {
  description = "Name of the provisioned AWS monthly cost budget"
  value       = length(aws_budgets_budget.this) > 0 ? aws_budgets_budget.this[0].name : "disabled"
}
