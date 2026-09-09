# Look up the existing Route 53 hosted zone without taking ownership of it
# data reads and looks for existing resources, but does not create or modify them. 
data "aws_route53_zone" "main" {
  name         = "twrz.co.uk"
  private_zone = false
}

# TLS certificate for it tools application
resource "aws_acm_certificate" "app" {
  domain_name       = "it-tools.twrz.co.uk"
  validation_method = "DNS"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-certificate"
    }
  )

  lifecycle {
    create_before_destroy = true # Ensures a new certificate is created before the old one is destroyed to avoid downtime
  }
}

# DNS record used by ACM to validate ownership of the domain
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.app.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

# Wait for ACM DNS validation to complete
resource "aws_acm_certificate_validation" "app" {
  certificate_arn = aws_acm_certificate.app.arn

  validation_record_fqdns = [
    for record in aws_route53_record.acm_validation :
    record.fqdn
  ]
}

/*
Existing Route 53 zone
        │
        ▼
ACM certificate request
        │
        ▼
DNS validation record
        │
        ▼
Certificate validated
*/

# Route application traffic to the Application Load Balancer
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "it-tools.twrz.co.uk"
  type    = "A"

  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = true # Ensures Route 53 checks the health of the ALB
  }
}

