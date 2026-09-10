# Project name used when naming VPC endpoint resources
variable "project_name" {
  description = "Name of the project"
  type        = string
}

# AWS region used to construct the AWS service endpoint names
variable "aws_region" {
  description = "AWS region where the VPC endpoints are created"
  type        = string
}

# ID of the VPC where the interface endpoints will be deployed
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

# Private subnet IDs where the interface endpoint network interfaces are created
variable "private_subnet_ids" {
  description = "IDs of the private subnets used by the VPC interface endpoints"
  type        = list(string)
}

# Security group controlling HTTPS traffic to the VPC interface endpoints
variable "vpc_endpoint_security_group_id" {
  description = "Security group ID attached to the VPC interface endpoints"
  type        = string
}

# Common tags applied consistently across the infrastructure
variable "common_tags" {
  description = "Common tags applied to resources"
  type        = map(string)
}