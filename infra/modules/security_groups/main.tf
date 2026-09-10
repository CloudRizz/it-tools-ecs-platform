# Looks up the AWS-managed S3 prefix list for this region
# so ECS can access S3 privately over HTTPS
data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${var.aws_region}.s3"
}

# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for application load balancer"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-alb-sg"
    }
  )
}

# Allows public HTTP traffic to the ALB
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

# Allows public HTTPS traffic to the ALB
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

# ECS Security Group
resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-ecs-sg"
    }
  )
}

# Allows traffic to ECS only from the ALB on port 8080
resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id = aws_security_group.ecs.id

  referenced_security_group_id = aws_security_group.alb.id

  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"
}

# VPC Endpoint Security Group
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project_name}-vpc-endpoints-sg"
  description = "Security group for interface VPC endpoints"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-vpc-endpoints-sg"
    }
  )
}

# Allows HTTPS traffic to interface endpoints only from ECS tasks
resource "aws_vpc_security_group_ingress_rule" "vpce_from_ecs" {
  security_group_id = aws_security_group.vpc_endpoints.id

  referenced_security_group_id = aws_security_group.ecs.id

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

# Allows ECS tasks to communicate with the interface VPC endpoints over HTTPS
resource "aws_vpc_security_group_egress_rule" "ecs_to_vpc_endpoints" {
  security_group_id = aws_security_group.ecs.id

  referenced_security_group_id = aws_security_group.vpc_endpoints.id

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

# Allows the ALB to forward traffic to ECS tasks on port 8080
resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id = aws_security_group.alb.id

  referenced_security_group_id = aws_security_group.ecs.id

  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"
}

# Allows ECS tasks to communicate with S3 over HTTPS
# using the AWS-managed S3 prefix list
resource "aws_vpc_security_group_egress_rule" "ecs_to_s3" {
  security_group_id = aws_security_group.ecs.id

  prefix_list_id = data.aws_prefix_list.s3.id

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}