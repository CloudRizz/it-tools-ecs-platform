# AWS region used to deploy the infrastructure
variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "eu-west-2"
}

# Public domain used to access the IT Tools application
variable "domain_name" {
  description = "Fully qualified domain name for the IT Tools application"
  type        = string
  default     = "it-tools.twrz.co.uk"
}

# Existing Route 53 hosted zone containing the application domain
variable "hosted_zone_name" {
  description = "Name of the existing Route 53 hosted zone"
  type        = string
  default     = "twrz.co.uk"
}

# Docker image tag deployed from the existing ECR repository
variable "image_tag" {
  description = "Docker image tag to deploy for the IT Tools application"
  type        = string
  default     = "bootstrap"
}

# Number of ECS Fargate tasks to run
variable "desired_count" {
  description = "Desired number of ECS tasks to run"
  type        = number
  default     = 0
}
