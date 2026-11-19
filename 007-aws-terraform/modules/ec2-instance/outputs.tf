output "instance_id" {
  description = "ID of the standalone EC2 instance (null if ASG enabled)"
  value       = var.enable_autoscaling ? null : aws_instance.this[0].id
}

output "private_ip" {
  description = "Private IP of the standalone EC2 instance (null if ASG enabled)"
  value       = var.enable_autoscaling ? null : aws_instance.this[0].private_ip
}

output "launch_template_id" {
  description = "ID of the Launch Template (null if standalone instance)"
  value       = var.enable_autoscaling ? aws_launch_template.this[0].id : null
}

output "launch_template_arn" {
  description = "ARN of the Launch Template (null if standalone instance)"
  value       = var.enable_autoscaling ? aws_launch_template.this[0].arn : null
}

output "autoscaling_group_id" {
  description = "ID of the Auto Scaling Group (null if standalone instance)"
  value       = var.enable_autoscaling ? aws_autoscaling_group.this[0].id : null
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group (null if standalone instance)"
  value       = var.enable_autoscaling ? aws_autoscaling_group.this[0].name : null
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group (null if standalone instance)"
  value       = var.enable_autoscaling ? aws_autoscaling_group.this[0].arn : null
}

output "security_group_id" {
  description = "ID of the security group created for the compute workload"
  value       = aws_security_group.this.id
}
