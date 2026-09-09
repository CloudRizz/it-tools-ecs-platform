# ALB Security Group

resource "aws_security_group" "alb" {
  name        = "${local.project_name}-alb-sg"
  description = "Security group for application load balancer"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-alb-sg"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

# ECS Security Group

resource "aws_security_group" "ecs" {
  name        = "${local.project_name}-ecs-sg"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-ecs-sg"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id = aws_security_group.ecs.id

  referenced_security_group_id = aws_security_group.alb.id # Allow traffic from the ALB security group only 

  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"
}

# VPC Endpoints

resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.project_name}-vpc-endpoints-sg"
  description = "Security group for interface VPC endpoints"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-vpc-endpoints-sg"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "vpce_from_ecs" {
  security_group_id = aws_security_group.vpc_endpoints.id

  referenced_security_group_id = aws_security_group.ecs.id # Allow traffic from the ECS security group only 

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_vpc_endpoints" {
  security_group_id = aws_security_group.ecs.id

  referenced_security_group_id = aws_security_group.vpc_endpoints.id # Allow traffic to the VPC endpoints security group only

  to_port     = 443
  from_port   = 443
  ip_protocol = "tcp"

}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id = aws_security_group.alb.id

  referenced_security_group_id = aws_security_group.ecs.id # Allow traffic from ALB to the ECS 

  to_port     = 8080
  from_port   = 8080
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_s3" {
  security_group_id = aws_security_group.ecs.id

  prefix_list_id = data.aws_prefix_list.s3.id # Allow traffic to S3 prefix list only

  to_port     = 443
  from_port   = 443
  ip_protocol = "tcp"
}