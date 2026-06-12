output "state_bucket" {
  value       = try(module.state[0].state_bucket, null)
  description = "S3 bucket for Terraform state"
}

output "dynamodb_lock_table" {
  value       = try(module.state[0].lock_table, null)
  description = "DynamoDB table for state locking"
}

output "vpc_id" {
  value       = local.vpc_id
  description = "VPC ID"
}

output "public_subnet_ids" {
  value       = local.public_subnet_ids
  description = "Public subnet IDs"
}

output "private_subnet_ids" {
  value       = local.private_subnet_ids
  description = "Private subnet IDs"
}

output "ecs_security_group_id" {
  value       = local.ecs_security_group_id
  description = "ECS security group ID"
}

output "rds_endpoint" {
  value       = try(module.database[0].endpoint, null)
  description = "RDS endpoint"
}

output "ecs_cluster_name" {
  value       = try(module.compute[0].cluster_name, null)
  description = "ECS cluster name"
}

output "ecs_app_service" {
  value       = try(module.compute[0].app_service_name, null)
  description = "ECS app service name"
}

output "alb_dns_name" {
  value       = try(module.compute[0].alb_dns_name, null)
  description = "ALB DNS name (if create_alb is true)"
}

output "compute_endpoint" {
  value       = try(module.compute[0].endpoint, null)
  description = "Public endpoint (EIP or ALB DNS)"
}

output "name_servers" {
  value       = try(module.delivery[0].name_servers, null)
  description = "Route53 NS records to set at the domain registrar"
}

output "frontend_cdn_domain" {
  value       = try(module.delivery[0].frontend_cdn_domain, null)
  description = "CloudFront domain for the frontend"
}

output "api_cdn_domain" {
  value       = try(module.delivery[0].api_cdn_domain, null)
  description = "CloudFront domain for the API"
}

output "frontend_s3_bucket" {
  value       = try(module.delivery[0].frontend_bucket_id, null)
  description = "Frontend S3 bucket name"
}

output "ci_cd_access_key_id" {
  value       = try(module.delivery[0].ci_cd_access_key_id, null)
  description = "CI/CD IAM access key ID"
}

output "ci_cd_secret_access_key" {
  value       = try(module.delivery[0].ci_cd_secret_access_key, null)
  sensitive   = true
  description = "CI/CD IAM secret access key"
}
