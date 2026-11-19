# VPC Module - Core Network

# 1. VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true # Activates the built-in AWS DNS resolver
  enable_dns_hostnames = true # Determines whether EC2 instances launched in this VPC automatically receive human-readable DNS hostnames

  tags = {
    Name = "${var.environment}-vpc"
  }
}

# 2. Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

# 3. Subnets across 3 Functional Tiers
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-subnet"
    Tier = "public"
  }
}

resource "aws_subnet" "public_2" {
  count                   = var.availability_zone_2 != null ? 1 : 0
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = var.availability_zone_2
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-subnet-2"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.environment}-private-subnet"
    Tier = "private"
  }
}

resource "aws_subnet" "secure" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.secure_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.environment}-secure-subnet"
    Tier = "secure"
  }
}

# 4. Elastic IP & NAT Gateway (for Private Subnet Egress)
resource "aws_eip" "this" {
  domain = "vpc"

  tags = {
    Name = "${var.environment}-nat-eip"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${var.environment}-nat-gw"
  }

  depends_on = [aws_internet_gateway.this]
}

# 5. Route Tables
# Public Route Table: Routes 0.0.0.0/0 to the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

# Private Route Table: Routes 0.0.0.0/0 to the NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${var.environment}-private-rt"
  }
}

# Secure Route Table: Local VPC routing only (No internet route)
resource "aws_route_table" "secure" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.environment}-secure-rt"
  }
}

# 6. Route Table Associations
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  count          = var.availability_zone_2 != null ? 1 : 0
  subnet_id      = aws_subnet.public_2[0].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "secure" {
  subnet_id      = aws_subnet.secure.id
  route_table_id = aws_route_table.secure.id
}

# 7. Stateless Network Access Control Lists (NACLs)

# Public Subnet NACL
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = concat([aws_subnet.public.id], var.availability_zone_2 != null ? [aws_subnet.public_2[0].id] : [])

  # Inbound Rules: HTTP, HTTPS, and Ephemeral return ports for public endpoints (e.g. ALB)
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound Rules
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.environment}-public-nacl"
  }
}

# Private App Subnet NACL
resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = [aws_subnet.private.id]

  # Inbound Rules: HTTP, HTTPS, and app ports from public subnet (ALB traffic)
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.public_subnet_cidr
    from_port  = 80
    to_port    = 80
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.public_subnet_cidr
    from_port  = 443
    to_port    = 443
  }

  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.public_subnet_cidr
    from_port  = 8080
    to_port    = 8080
  }

  # Stateless return traffic for outbound requests via NAT Gateway
  ingress {
    rule_no    = 130
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound Rules: Allow egress via NAT Gateway and to local VPC
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.environment}-private-nacl"
  }
}

# Secure Database Subnet NACL (Zero internet routing)
resource "aws_network_acl" "secure" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = [aws_subnet.secure.id]

  # Inbound Rules: Strictly database ports from Private App Subnet only
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.private_subnet_cidr
    from_port  = 5432
    to_port    = 5432
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.private_subnet_cidr
    from_port  = 3306
    to_port    = 3306
  }

  # Outbound Rules: Ephemeral return traffic to Private App Subnet only
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.private_subnet_cidr
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "${var.environment}-secure-nacl"
  }
}
