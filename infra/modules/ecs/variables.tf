# Name of the project used when naming ECS resources
variable "project_name" {
  description = "Name of the project"
  type        = string
}

# AWS region used by the CloudWatch logging configuration
variable "aws_region" {
  description = "AWS region"
  type        = string
}

# Docker image tag to deploy from ECR
variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
}

# Desired number of ECS tasks
variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
}

# Private subnets used by ECS Fargate tasks
variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

# Security group attached to ECS tasks
variable "ecs_security_group_id" {
  description = "ID of the ECS security group"
  type        = string
}

# IAM execution role used by ECS
variable "execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

# CloudWatch log group used by the container
variable "log_group_name" {
  description = "Name of the CloudWatch log group"
  type        = string
}

# Target group used by the ECS service
variable "target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

# Common tags applied consistently across the infrastructure
variable "common_tags" {
  description = "Common tags applied to resources"
  type        = map(string)
}