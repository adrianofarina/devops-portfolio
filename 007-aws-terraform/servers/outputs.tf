# Gateway (ALB) Outputs
output "gateway_dns_name" {
  description = "Public DNS hostname of the external Application Load Balancer"
  value       = module.ext_gateway.alb_dns_name
}

output "gateway_arn" {
  description = "ARN of the external Application Load Balancer"
  value       = module.ext_gateway.alb_arn
}

output "gateway_security_group_id" {
  description = "Security group ID of the external gateway"
  value       = module.ext_gateway.security_group_id
}

output "gateway_target_group_arn" {
  description = "ARN of the gateway target group"
  value       = module.ext_gateway.target_group_arn
}

# Application Compute Tier Outputs
output "app_security_group_id" {
  description = "Security group ID for the application tier"
  value       = module.ec2_instance.security_group_id
}

output "app_asg_name" {
  description = "Name of the application Auto Scaling Group"
  value       = module.ec2_instance.autoscaling_group_name
}

output "app_launch_template_id" {
  description = "ID of the application Launch Template"
  value       = module.ec2_instance.launch_template_id
}

output "app_instance_id" {
  description = "ID of the standalone application instance (if standalone mode is used)"
  value       = module.ec2_instance.instance_id
}

output "app_instance_private_ip" {
  description = "Private IP of the standalone application instance (if standalone mode is used)"
  value       = module.ec2_instance.private_ip
}

# IAM & Security Profile Outputs
output "iam_role_arn" {
  description = "ARN of the IAM role for SSM session manager access"
  value       = aws_iam_role.this.arn
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile attached to EC2 instances"
  value       = aws_iam_instance_profile.this.name
}
