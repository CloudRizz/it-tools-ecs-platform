# Building Main VPC + tags allow to be used across the project to refer to the project name and managed by terraform
# i.e it-tools-vpc, it-tools-subnet, it-tools-ecs-cluster, etc

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-vpc"
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
    local.common_tags,
    {
      Name = "${local.project_name}-public-a"
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
    local.common_tags,
    {
      Name = "${local.project_name}-public-b"
    }
  )
}

# Private subnet - eu-west-2a
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "eu-west-2a"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-private-a"
    }
  )
}

# Private subnet - eu-west-2b
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "eu-west-2b"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-private-b"
    }
  )
}

# Internet Gateway - Gives VPC access to the internet for public subnets, 
# allowing instances in public subnets to communicate with the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-igw"
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
    local.common_tags,
    {
      Name = "${local.project_name}-public-rt"
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
    local.common_tags,
    {
      Name = "${local.project_name}-private-rt"
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
    local.common_tags,
    {
      Name = "${local.project_name}-s3-endpoint"
    }
  )
}

# creates private entrypoint for ECR API inside VPC, allowing private subnets to access ECR without going through the internet
# referencing subnets tells AWS to create network interfaces in the specified subnets for private connectivity to the service
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface" # Creates endpoint ENIs in the selected private subnets
  private_dns_enabled = true        #  Resolves the standard ECR API hostname to the endpoint's private IPs inside the VPC

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-ecr-api-endpoint"
    }
  )
}

# ECR Docker endpoint - Provides private access for ECS to pull container images from ECR
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-ecr-dkr-endpoint"
    }
  )
}

# CloudWatch Logs endpoint - Allows private ECS tasks to send container logs to CloudWatch without NAT
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-logs-endpoint"
    }
  )
}

data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${var.aws_region}.s3"
}