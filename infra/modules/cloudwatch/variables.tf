# Name of the project used when naming CloudWatch resources
variable "project_name" {
  description = "Name of the project"
  type        = string
}

# Number of days CloudWatch should retain ECS container logs
variable "retention_in_days" {
  description = "Number of days to retain ECS logs"
  type        = number
  default     = 7
}

# Common tags applied consistently across the infrastructure
variable "common_tags" {
  description = "Common tags applied to resources"
  type        = map(string)
}