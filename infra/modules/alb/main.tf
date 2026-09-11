# Retrieves the current AWS account ID.
# Used to restrict ALB log delivery to resources belonging to this AWS account.
data "aws_caller_identity" "current" {}


# ---------------------------------------------------------------------------
# ALB ACCESS LOGGING
# ---------------------------------------------------------------------------

# S3 bucket used to store Application Load Balancer access logs.
# bucket_prefix allows AWS to generate a globally unique bucket name.
# force_destroy allows Terraform to delete the bucket and its logs
# during project teardown.

resource "aws_s3_bucket" "alb_logs" {
  # checkov:skip=CKV_AWS_18:This bucket stores ALB access logs; enabling server access logging would require an additional destination bucket solely to log access to the logging bucket.
  # checkov:skip=CKV_AWS_21:Versioning is not required for disposable ALB access logs that are automatically expired by lifecycle policy.
  # checkov:skip=CKV_AWS_144:Cross-region replication is not required for short-lived ALB access logs in this portfolio environment.
  # checkov:skip=CKV_AWS_145:ALB access logs use SSE-S3 encryption; customer-managed KMS encryption is intentionally not used for this low-cost environment.
  # checkov:skip=CKV2_AWS_62:No event-driven processing is required for ALB access logs in this portfolio environment.
  bucket_prefix = "${var.project_name}-alb-logs-"
  force_destroy = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-alb-logs"
    }
  )
}


# Blocks all public access to the ALB logging bucket.
# The ALB receives access through the dedicated bucket policy below.
resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# Enables server-side encryption for ALB access logs stored in S3.
# AES256 uses Amazon S3-managed encryption keys (SSE-S3).
resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Automatically manages ALB access-log storage to prevent
# unnecessary S3 storage growth in this short-lived environment.
resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "manage-alb-logs"
    status = "Enabled"

    # Applies the lifecycle rule to all objects in the bucket.
    filter {}

    # Deletes ALB access logs after 30 days.
    expiration {
      days = 30
    }

    # Removes incomplete multipart uploads after 7 days.
    # This prevents abandoned uploads from consuming S3 storage.
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}


# Allows the AWS Elastic Load Balancing log delivery service
# to write access logs into the dedicated S3 bucket.
#
# Permissions are restricted to:
# - s3:PutObject only
# - the ALB access-log path
# - this AWS account
# - load balancers belonging to this AWS account
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowALBLogDelivery"
        Effect = "Allow"

        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }

        Action = "s3:PutObject"

        # Restricts log delivery to this account's ALB log path.
        Resource = "${aws_s3_bucket.alb_logs.arn}/alb-access/AWSLogs/${data.aws_caller_identity.current.account_id}/*"

        Condition = {
          ArnLike = {
            # Only load balancers belonging to this AWS account
            # can deliver logs to the bucket.
            "aws:SourceArn" = "arn:aws:elasticloadbalancing:*:${data.aws_caller_identity.current.account_id}:loadbalancer/*"
          }
        }
      }
    ]
  })

  # Ensures the public-access restrictions are configured
  # before Terraform applies the bucket policy.
  depends_on = [
    aws_s3_bucket_public_access_block.alb_logs
  ]
}


# ---------------------------------------------------------------------------
# APPLICATION LOAD BALANCER
# ---------------------------------------------------------------------------

# Internet-facing Application Load Balancer for the IT Tools application.
# Receives public HTTP/HTTPS traffic and forwards HTTPS requests to ECS.

resource "aws_lb" "app" {
  # checkov:skip=CKV_AWS_150:Deletion protection is intentionally disabled so the portfolio environment can be fully destroyed and recreated with Terraform.
  # checkov:skip=CKV2_AWS_28:AWS WAF is omitted from this low-cost portfolio environment; a production deployment would attach a managed WAF policy.
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"

  # Drops malformed HTTP headers rather than forwarding them
  # to the ECS application.
  drop_invalid_header_fields = true

  # Sends ALB request/access logs to the dedicated S3 bucket.
  # These logs support troubleshooting, traffic analysis
  # and security investigations.
  access_logs {
    bucket  = aws_s3_bucket.alb_logs.id
    prefix  = "alb-access"
    enabled = true
  }

  # Dedicated ALB security group controls inbound and outbound traffic.
  security_groups = [
    var.alb_security_group_id
  ]

  # Deploys the ALB across two public subnets for high availability.
  subnets = var.public_subnet_ids

  # Ensures the S3 bucket policy is applied before the ALB
  # attempts to deliver access logs to the bucket.
  depends_on = [
    aws_s3_bucket_policy.alb_logs
  ]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-alb"
    }
  )
}


# ---------------------------------------------------------------------------
# TARGET GROUP
# ---------------------------------------------------------------------------

# Target group used by the ALB to route requests to ECS Fargate tasks.
# target_type = "ip" is required because Fargate tasks use awsvpc networking
# and are registered using their private IP addresses.
resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  # ALB checks the application's /health endpoint to determine
  # whether an ECS task is healthy and should receive traffic.
  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-tg"
    }
  )
}


# ---------------------------------------------------------------------------
# HTTP LISTENER
# ---------------------------------------------------------------------------

# Listens for public HTTP traffic on port 80.
# Requests are not forwarded to ECS over HTTP.
# Instead, all HTTP requests are permanently redirected to HTTPS.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


# ---------------------------------------------------------------------------
# HTTPS LISTENER
# ---------------------------------------------------------------------------

# Terminates TLS at the ALB using the ACM certificate.
# Valid HTTPS requests are then forwarded to the ECS target group.
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"

  # Modern TLS policy supporting TLS 1.2 and TLS 1.3.
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = var.certificate_arn

  # Forwards HTTPS requests to healthy ECS Fargate tasks.
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}