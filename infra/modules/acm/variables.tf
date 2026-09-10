# Name of the project used when naming the ACM certificate
variable "project_name" {
  description = "Name of the project"
  type        = string
}

# Domain name that the TLS certificate will secure
variable "domain_name" {
  description = "Domain name for the ACM certificate"
  type        = string
}

# Existing Route 53 hosted zone containing the application domain
variable "hosted_zone_name" {
  description = "Name of the existing Route 53 hosted zone"
  type        = string
}

# Common tags applied consistently across the infrastructure
variable "common_tags" {
  description = "Common tags applied to resources"
  type        = map(string)
}