output "application_url" {
  description = "Public HTTPS URL for IT Tools"
  value       = "https://it-tools.twrz.co.uk"
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.app.dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster running the IT Tools service"
  value       = aws_ecs_cluster.main.name
}