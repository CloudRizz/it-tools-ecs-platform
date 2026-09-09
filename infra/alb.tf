# Internet facing Application Load Balancer (ALB) for it tools application
resource "aws_lb" "app" {
  name               = "${local.project_name}-alb"
  internal           = false # makes the alb internet facing, allowing it to receive traffic from the internet
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-alb"
    }
  )
}

# Target group used by the ALB to route traffic to ECS tasks
resource "aws_lb_target_group" "app" {
  name        = "${local.project_name}-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # Use IP addresses of ECS tasks as targets instead of instance IDs

  health_check {
    enabled             = true
    path                = "/health" # Health check endpoint for ECS tasks
    protocol            = "HTTP"
    matcher             = "200" # Consider healthy if response is in the 200
    interval            = 30    # Check every 30 seconds
    timeout             = 5     # Timeout after 5 seconds
    healthy_threshold   = 2     # Consider healthy after 2 consecutive successes
    unhealthy_threshold = 2     # Consider unhealthy after 2 consecutive failures
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-tg"
    }
  )
}

# HTTP listener redirects all requests to HTTPS for secure communication
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

# HTTPS listener terminates TLS and forwards traffic to the ECS target group
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.app.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

