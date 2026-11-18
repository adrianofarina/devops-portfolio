# Dynamic AWS Resource Discovery
data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-vpc"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  filter {
    name   = "tag:Tier"
    values = ["public"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  filter {
    name   = "tag:Tier"
    values = ["private"]
  }
}

# External Ingress Gateway: Application Load Balancer
module "ext_gateway" {
  source = "../modules/gateway"

  # Resource Naming & Environment
  name        = "${var.environment}-ext-gateway"
  environment = var.environment

  # Network Placement (Multi-AZ Public Subnets from AWS Data Discovery)
  vpc_id            = data.aws_vpc.this.id
  public_subnet_ids = data.aws_subnets.public.ids

  # Routing & Target Configuration
  backend_port      = 8080
  health_check_path = "/"
}

# Application Compute Tier: EC2 Workload via Auto Scaling Group
module "ec2_instance" {
  source = "../modules/ec2-instance"

  # Resource Naming & Environment
  name        = "${var.environment}-app-server"
  environment = var.environment

  # Network Placement (Private Subnets from AWS Data Discovery)
  vpc_id     = data.aws_vpc.this.id
  subnet_ids = data.aws_subnets.private.ids

  # Compute Sizing & Image Resolution
  instance_type        = "t3.micro"
  ami_id               = null # Resolves dynamically to latest official Amazon Linux 2023
  iam_instance_profile = aws_iam_instance_profile.this.name

  # Ingress & Security Filtering (Least Privilege from External Gateway)
  app_port                   = 8080
  allowed_ingress_cidrs      = []
  allowed_security_group_ids = [module.ext_gateway.security_group_id]

  # Auto Scaling Configuration & Target Group Attachment
  enable_autoscaling   = true
  asg_min_size         = 1
  asg_max_size         = 2
  asg_desired_capacity = 1
  target_group_arns    = [module.ext_gateway.target_group_arn]

  # User Data Scripting
  custom_user_data = null # Defaults to parameterized Nginx web server template
}
