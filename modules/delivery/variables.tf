variable "name_prefix" {
  type        = string
  description = "Prefix used for naming all resources"
}

variable "domain_name" {
  type        = string
  description = "Domain name for the application (e.g., example.com)"
}

variable "compute_endpoint" {
  type        = string
  default     = ""
  description = "Public endpoint for the API origin (EIP or ALB DNS)"
}

variable "create_route53_zone" {
  type        = bool
  default     = true
  description = "Whether to create a Route53 hosted zone"
}

variable "zone_id" {
  type        = string
  default     = ""
  description = "Existing Route53 zone ID (if create_route53_zone is false)"
}

variable "acm_certificate_arn" {
  type        = string
  default     = ""
  description = "Existing ACM certificate ARN (if not creating one)"
}

variable "create_frontend_bucket" {
  type        = bool
  default     = true
  description = "Whether to create an S3 bucket for frontend hosting"
}

variable "frontend_bucket_name" {
  type        = string
  default     = ""
  description = "Override the frontend S3 bucket name (auto-generated from domain if empty)"
}

variable "s3_versioning_enabled" {
  type        = bool
  default     = true
  description = "Enable versioning on the frontend S3 bucket"
}

variable "s3_lifecycle_expiration_days" {
  type        = number
  default     = 90
  description = "Days after which to expire old noncurrent versions in the frontend bucket (0 to disable)"
}

variable "create_cloudfront_frontend" {
  type        = bool
  default     = true
  description = "Whether to create a CloudFront distribution for the frontend"
}

variable "create_cloudfront_api" {
  type        = bool
  default     = false
  description = "Whether to create a CloudFront distribution for the API"
}

variable "cloudfront_function_path" {
  type        = string
  default     = ""
  description = "Path to a custom CloudFront function JS file (uses default SPA rewrite if empty)"
}

variable "cloudfront_price_class" {
  type        = string
  default     = "PriceClass_100"
  description = "CloudFront price class (PriceClass_100, PriceClass_200, PriceClass_All)"
}

variable "geo_restriction_type" {
  type        = string
  default     = "none"
  description = "CloudFront geo restriction type (none, whitelist, blacklist)"
}

variable "geo_restriction_locations" {
  type        = list(string)
  default     = []
  description = "List of country codes for geo restriction"
}

variable "create_ci_cd_user" {
  type        = bool
  default     = true
  description = "Whether to create an IAM user for CI/CD deployments"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}
