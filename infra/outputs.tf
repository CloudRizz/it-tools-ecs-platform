output "application_url" {
  description = "Public HTTPS URL for IT Tools"
  value       = "https://${var.domain_name}"
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster running the IT Tools service"
  value       = module.ecs.ecs_cluster_name
}
