# ECR API Interface Endpoint
# Allows ECS tasks in private subnets to communicate with the ECR API
# without requiring internet access or a NAT Gateway
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = var.private_subnet_ids

  security_group_ids = [
    var.vpc_endpoint_security_group_id
  ]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-ecr-api-endpoint"
    }
  )
}

# ECR Docker Interface Endpoint
# Allows ECS tasks to privately pull Docker image layers from ECR
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = var.private_subnet_ids

  security_group_ids = [
    var.vpc_endpoint_security_group_id
  ]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-ecr-dkr-endpoint"
    }
  )
}

# CloudWatch Logs Interface Endpoint
# Allows ECS tasks in private subnets to send container logs to CloudWatch
# without using a NAT Gateway or public internet access
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = var.private_subnet_ids

  security_group_ids = [
    var.vpc_endpoint_security_group_id
  ]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-logs-endpoint"
    }
  )
}