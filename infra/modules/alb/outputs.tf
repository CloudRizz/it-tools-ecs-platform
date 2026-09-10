# Exposes the ALB DNS name for Route 53 and root outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.app.dns_name
}

# Exposes the ALB hosted zone ID for Route 53 alias records
output "alb_zone_id" {
  description = "Canonical hosted zone ID of the Application Load Balancer"
  value       = aws_lb.app.zone_id
}

# Exposes the target group ARN for the ECS service
output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.app.arn
}

# Exposes the HTTPS listener ARN
output "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = aws_lb_listener.https.arn
}