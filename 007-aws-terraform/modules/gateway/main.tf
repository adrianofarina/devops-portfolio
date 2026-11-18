# Gateway (ALB) Security Group
resource "aws_security_group" "this" {
  name_prefix = "${var.name}-sg-"
  description = "Security group for ${var.name} Application Load Balancer"
  vpc_id      = var.vpc_id

  # Inbound HTTP (port 80) from public internet
  ingress {
    description = "Allow inbound HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound egress to backend instances
  egress {
    description = "Allow all outbound traffic to targets"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.name}-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Internet-Facing Application Load Balancer
resource "aws_lb" "this" {
  name_prefix                = "gw-"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.this.id]
  subnets                    = var.public_subnet_ids
  enable_deletion_protection = false

  tags = {
    Name        = var.name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Target Group for Backend Compute Workloads
resource "aws_lb_target_group" "this" {
  name_prefix          = "tg-"
  port                 = var.backend_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    matcher             = "200"
  }

  tags = {
    Name        = "${var.name}-tg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# HTTP Listener (Port 80)
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
