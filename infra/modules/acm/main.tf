# Looks up the existing public Route 53 hosted zone
# without Terraform taking ownership of the hosted zone itself
data "aws_route53_zone" "main" {
  name         = var.hosted_zone_name
  private_zone = false
}

# Requests a TLS certificate for the IT Tools application
resource "aws_acm_certificate" "app" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-certificate"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Creates the DNS record required by ACM to prove ownership
# of the application domain
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

  records = [
    each.value.record
  ]
}

# Waits until ACM confirms that DNS validation has completed
resource "aws_acm_certificate_validation" "app" {
  certificate_arn = aws_acm_certificate.app.arn

  validation_record_fqdns = [
    for record in aws_route53_record.acm_validation :
    record.fqdn
  ]
}