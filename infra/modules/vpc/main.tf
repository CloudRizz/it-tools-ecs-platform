# Building Main VPC + tags allow to be used across the project to refer to the project name and managed by terraform
# i.e it-tools-vpc, it-tools-subnet, it-tools-ecs-cluster, etc

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-vpc"
    }
  )
}

# Restricts the default VPC security group.
# Project resources use dedicated least-privilege security groups instead.
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  ingress = []
  egress  = []

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-default-sg-restricted"
    }
  )
}

# CloudWatch log group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  # checkov:skip=CKV_AWS_158:CloudWatch default encryption is accepted for this portfolio environment; a customer-managed KMS key would add unnecessary cost and complexity.
  name              = "/aws/vpc/${var.project_name}-flow-logs"
  retention_in_days = 365

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-vpc-flow-logs"
    }
  )
}

# IAM role assumed by the VPC Flow Logs service
resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.project_name}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.common_tags
}

# Allows VPC Flow Logs to write records to CloudWatch
resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.project_name}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
      }
    ]
  })
}

# Records accepted and rejected network traffic across the VPC
resource "aws_flow_log" "main" {
  vpc_id = aws_vpc.main.id

  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-vpc-flow-log"
    }
  )
}

# Public Subnet - eu-west-2a
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = false # Do not automatically assign public IPs to resources launched in this subnet

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-public-a"
    }
  )
}

# Public Subnet - eu-west-2b
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = false

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-public-b"
    }
  )
}

# Private subnet - eu-west-2a
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "eu-west-2a"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-private-a"
    }
  )
}

# Private subnet - eu-west-2b
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "eu-west-2b"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-private-b"
    }
  )
}

# Internet Gateway - Gives VPC access to the internet for public subnets, 
# allowing instances in public subnets to communicate with the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-igw"
    }
  )
}

# Public route table - routing for public subnets to the internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-public-rt"
    }
  )
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Route table for private subnets 
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-private-rt"
    }
  )
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# S3 Gateway Endpoint - Provides private S3 connectivity through the private route table without NAT or an Internet Gateway
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-s3-endpoint"
    }
  )
}

