# Exposes the validated certificate ARN for use by the ALB HTTPS listener
output "certificate_arn" {
  description = "ARN of the validated ACM certificate"
  value       = aws_acm_certificate_validation.app.certificate_arn
}

# Exposes the existing Route 53 hosted zone ID
# for use when creating application DNS records
output "hosted_zone_id" {
  description = "ID of the existing Route 53 hosted zone"
  value       = data.aws_route53_zone.main.zone_id
}