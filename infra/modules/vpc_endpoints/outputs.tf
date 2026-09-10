# Exposes the ECR API endpoint ID for reference by other infrastructure
output "ecr_api_endpoint_id" {
  description = "ID of the ECR API VPC endpoint"
  value       = aws_vpc_endpoint.ecr_api.id
}

# Exposes the ECR Docker endpoint ID for reference by other infrastructure
output "ecr_dkr_endpoint_id" {
  description = "ID of the ECR Docker VPC endpoint"
  value       = aws_vpc_endpoint.ecr_dkr.id
}

# Exposes the CloudWatch Logs endpoint ID for reference by other infrastructure
output "logs_endpoint_id" {
  description = "ID of the CloudWatch Logs VPC endpoint"
  value       = aws_vpc_endpoint.logs.id
}