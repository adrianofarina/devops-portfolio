# Dynamic AMI resolution for latest official Amazon Linux 2023
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

locals {
  ami_id = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux_2023.id

  # Render parameterized user data template unless custom user data is explicitly provided
  user_data_rendered = var.custom_user_data != null ? var.custom_user_data : templatefile(
    "${path.module}/user_data.sh",
    {
      server_name = var.name
      environment = var.environment
      app_port    = tostring(var.app_port)
    }
  )
}

# Dedicated security group for compute workload
resource "aws_security_group" "this" {
  name_prefix = "${var.name}-sg-"
  description = "Security group for ${var.name}"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Application port ingress"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    cidr_blocks     = length(var.allowed_ingress_cidrs) > 0 ? var.allowed_ingress_cidrs : null
    security_groups = length(var.allowed_security_group_ids) > 0 ? var.allowed_security_group_ids : null
  }

  egress {
    description = "Full outbound egress via NAT gateway"
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

# Mode A: Standalone EC2 Instance (when enable_autoscaling = false)
resource "aws_instance" "this" {
  count = var.enable_autoscaling ? 0 : 1

  ami                    = local.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.this.id]
  iam_instance_profile   = var.iam_instance_profile
  user_data              = local.user_data_rendered

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name        = "${var.name}-root-volume"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }

  tags = {
    Name        = var.name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Mode B: Launch Template & Auto Scaling Group (when enable_autoscaling = true)
resource "aws_launch_template" "this" {
  count = var.enable_autoscaling ? 1 : 0

  name_prefix   = "${var.name}-lt-"
  description   = "Launch template for ${var.name}"
  image_id      = local.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.this.id]

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile != null ? [var.iam_instance_profile] : []
    content {
      name = iam_instance_profile.value
    }
  }

  user_data = base64encode(local.user_data_rendered)

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 8
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = var.name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  count = var.enable_autoscaling ? 1 : 0

  name_prefix         = "${var.name}-asg-"
  vpc_zone_identifier = var.subnet_ids
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  target_group_arns   = var.target_group_arns

  health_check_type         = length(var.target_group_arns) > 0 ? "ELB" : "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.this[0].id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = var.name
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "Terraform"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}
