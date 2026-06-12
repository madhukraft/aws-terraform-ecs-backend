output "frontend_cdn_domain" {
  value       = var.create_cloudfront_frontend ? aws_cloudfront_distribution.frontend[0].domain_name : null
  description = "CloudFront domain for the frontend distribution"
}

output "api_cdn_domain" {
  value       = var.create_cloudfront_api ? aws_cloudfront_distribution.api[0].domain_name : null
  description = "CloudFront domain for the API distribution"
}

output "frontend_bucket_id" {
  value       = var.create_frontend_bucket ? aws_s3_bucket.frontend[0].id : null
  description = "Frontend S3 bucket ID"
}

output "name_servers" {
  value       = var.create_route53_zone ? aws_route53_zone.this[0].name_servers : null
  description = "Route53 name servers for NS record setup at registrar"
}

output "zone_id" {
  value       = local.zone_id
  description = "Route53 zone ID"
}

output "ci_cd_access_key_id" {
  value       = var.create_ci_cd_user ? aws_iam_access_key.ci_cd[0].id : null
  description = "CI/CD IAM user access key ID"
}

output "ci_cd_secret_access_key" {
  value       = var.create_ci_cd_user ? aws_iam_access_key.ci_cd[0].secret : null
  sensitive   = true
  description = "CI/CD IAM user secret access key"
}

output "ci_cd_user_name" {
  value       = var.create_ci_cd_user ? aws_iam_user.ci_cd[0].name : null
  description = "CI/CD IAM user name"
}

output "certificate_arn" {
  value       = local.certificate_arn
  description = "ACM certificate ARN"
}
