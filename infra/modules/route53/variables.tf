# Hosted zone where the application DNS record will be created
variable "hosted_zone_id" {
  description = "ID of the Route 53 hosted zone"
  type        = string
}

# Fully qualified domain name for the application
variable "domain_name" {
  description = "Application domain name"
  type        = string
}

# DNS name of the Application Load Balancer
variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  type        = string
}

# Canonical hosted zone ID of the Application Load Balancer
variable "alb_zone_id" {
  description = "Canonical hosted zone ID of the Application Load Balancer"
  type        = string
}