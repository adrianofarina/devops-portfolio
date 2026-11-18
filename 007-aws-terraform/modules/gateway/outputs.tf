output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.this.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "Public DNS hostname of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Canonical hosted zone ID of the Application Load Balancer"
  value       = aws_lb.this.zone_id
}

output "security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.this.id
}

output "target_group_arn" {
  description = "ARN of the target group for instance/ASG registration"
  value       = aws_lb_target_group.this.arn
}

output "target_group_id" {
  description = "ID of the target group"
  value       = aws_lb_target_group.this.id
}

output "target_group_name" {
  description = "Name of the target group"
  value       = aws_lb_target_group.this.name
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.this.arn
}
