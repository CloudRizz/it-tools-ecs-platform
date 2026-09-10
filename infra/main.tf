# Creates the core networking layer for the IT Tools platform
module "vpc" {
  source = "./modules/vpc"

  project_name = local.project_name
  aws_region   = var.aws_region
  common_tags  = local.common_tags
}

# Creates the security groups used by the ALB, ECS tasks,
# and interface VPC endpoints
module "security_groups" {
  source = "./modules/security_groups"

  project_name = local.project_name
  aws_region   = var.aws_region
  vpc_id       = module.vpc.vpc_id
  common_tags  = local.common_tags
}

# Creates private interface endpoints for ECR and CloudWatch Logs
# so ECS tasks can operate without requiring a NAT Gateway
module "vpc_endpoints" {
  source = "./modules/vpc_endpoints"

  project_name                   = local.project_name
  aws_region                     = var.aws_region
  vpc_id                         = module.vpc.vpc_id
  private_subnet_ids             = module.vpc.private_subnet_ids
  vpc_endpoint_security_group_id = module.security_groups.vpc_endpoint_security_group_id
  common_tags                    = local.common_tags
}

# Creates and validates the TLS certificate for the application domain
module "acm" {
  source = "./modules/acm"

  project_name     = local.project_name
  domain_name      = var.domain_name
  hosted_zone_name = var.hosted_zone_name
  common_tags      = local.common_tags
}

# Creates the internet-facing Application Load Balancer
# and routes HTTPS traffic to the ECS target group
module "alb" {
  source = "./modules/alb"

  project_name          = local.project_name
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_security_group_id
  certificate_arn       = module.acm.certificate_arn
  common_tags           = local.common_tags
}

# Routes the public application domain to the Application Load Balancer
module "route53" {
  source = "./modules/route53"

  hosted_zone_id = module.acm.hosted_zone_id
  domain_name    = var.domain_name
  alb_dns_name   = module.alb.alb_dns_name
  alb_zone_id    = module.alb.alb_zone_id
}

# Creates the IAM execution role used by ECS tasks
module "iam" {
  source = "./modules/iam"

  project_name = local.project_name
  common_tags  = local.common_tags
}

# Creates the CloudWatch log group used by ECS containers
module "cloudwatch" {
  source = "./modules/cloudwatch"

  project_name      = local.project_name
  retention_in_days = 7
  common_tags       = local.common_tags
}

# Runs the IT Tools application on ECS Fargate in the private subnets
module "ecs" {
  source = "./modules/ecs"

  project_name          = local.project_name
  aws_region            = var.aws_region
  image_tag             = var.image_tag
  desired_count         = var.desired_count
  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_security_group_id = module.security_groups.ecs_security_group_id
  execution_role_arn    = module.iam.ecs_task_execution_role_arn
  log_group_name        = module.cloudwatch.log_group_name
  target_group_arn      = module.alb.target_group_arn
  common_tags           = local.common_tags

  # Ensures the ALB listeners and private service endpoints exist
  # before the ECS service is created
  depends_on = [
    module.alb,
    module.vpc_endpoints
  ]
}