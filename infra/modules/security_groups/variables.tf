# Name of the project used when naming security groups
variable "project_name" {
  description = "Name of the project"
  type        = string
}

# AWS region used to look up the S3 managed prefix list
variable "aws_region" {
  description = "AWS region"
  type        = string
}

# VPC where the security groups will be created
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

# Common tags applied consistently across the infrastructure
variable "common_tags" {
  description = "Common tags applied to resources"
  type        = map(string)
}