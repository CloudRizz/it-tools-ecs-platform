# Name of the project used when naming ALB resources
variable "project_name" {
  description = "Name of the project"
  type        = string
}

# VPC where the ALB target group will be created
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

# Public subnets where the internet-facing ALB will be deployed
variable "public_subnet_ids" {
  description = "IDs of the public subnets"
  type        = list(string)
}

# Security group attached to the Application Load Balancer
variable "alb_security_group_id" {
  description = "ID of the ALB security group"
  type        = string
}

# ACM certificate used by the HTTPS listener
variable "certificate_arn" {
  description = "ARN of the validated ACM certificate"
  type        = string
}

# Common tags applied consistently across the infrastructure
variable "common_tags" {
  description = "Common tags applied to resources"
  type        = map(string)
}