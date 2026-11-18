# IAM Role for EC2 Systems Manager (SSM) Access
resource "aws_iam_role" "this" {
  name_prefix = "${var.environment}-app-ssm-role-"
  description = "IAM role allowing EC2 instances to communicate with AWS Systems Manager"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-app-ssm-role"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Attach AWS Managed Policy for SSM
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile (Bridge to attach IAM Role to EC2 / Launch Template)
resource "aws_iam_instance_profile" "this" {
  name_prefix = "${var.environment}-app-ssm-profile-"
  role        = aws_iam_role.this.name

  tags = {
    Name        = "${var.environment}-app-ssm-profile"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
