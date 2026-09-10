# Name of the project used when naming IAM resources
variable "project_name" {
  description = "Name of the project"
  type        = string
}

# Common tags applied consistently across the infrastructure
variable "common_tags" {
  description = "Common tags applied to resources"
  type        = map(string)
}