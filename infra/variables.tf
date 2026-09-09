# Region Variable

variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "eu-west-2"
}

variable "image_tag" {
  description = "The Docker image tag to deploy for the IT Tools application"
  type        = string
  default     = "bootstrap"
}

variable "desired_count" {
  description = "The desired number of ECS tasks to run for the IT Tools application"
  type        = number
  default     = 0
}