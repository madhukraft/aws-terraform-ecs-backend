terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.us-east-1]
    }
  }
}

data "aws_region" "current" {}

locals {
  root_domain     = var.domain_name
  api_domain      = "api.${var.domain_name}"
  backend_domain  = "backend.${var.domain_name}"
  wildcard_domain = "*.${var.domain_name}"

  frontend_bucket_name = var.frontend_bucket_name != "" ? var.frontend_bucket_name : replace(var.domain_name, ".", "-")

  use_default_function = var.cloudfront_function_path == ""
}

resource "aws_acm_certificate" "this" {
  count    = var.acm_certificate_arn == "" ? 1 : 0
  provider = aws.us-east-1

  domain_name               = var.domain_name
  subject_alternative_names = [local.wildcard_domain]
  validation_method         = "DNS"

  tags = merge(var.tags, { Name = "${var.name_prefix}-cert" })
}

data "aws_acm_certificate" "existing" {
  count  = var.acm_certificate_arn != "" ? 1 : 0
  domain = var.domain_name
}

locals {
  certificate_arn = var.acm_certificate_arn != "" ? var.acm_certificate_arn : aws_acm_certificate.this[0].arn
}

resource "aws_s3_bucket" "frontend" {
  count  = var.create_frontend_bucket ? 1 : 0
  bucket = local.frontend_bucket_name

  tags = merge(var.tags, { Name = local.frontend_bucket_name })
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  count  = var.create_frontend_bucket ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "frontend" {
  count  = var.create_frontend_bucket ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id

  versioning_configuration {
    status = var.s3_versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "frontend" {
  count  = var.create_frontend_bucket && var.s3_versioning_enabled && var.s3_lifecycle_expiration_days > 0 ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = var.s3_lifecycle_expiration_days
    }
  }
}

resource "aws_cloudfront_origin_access_control" "frontend" {
  count = var.create_cloudfront_frontend ? 1 : 0

  name                              = "${var.name_prefix}-oac"
  description                       = "Origin Access Control for CloudFront to S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "root_rewrite" {
  count   = var.create_cloudfront_frontend && local.use_default_function ? 1 : 0
  name    = "${var.name_prefix}-root-rewrite"
  runtime = "cloudfront-js-2.0"
  comment = "Rewrite / -> /index.html for SPA routing"
  publish = true
  code    = file("${path.module}/cloudfront_functions/root_rewrite.js")
}

data "aws_cloudfront_function" "custom" {
  count = var.create_cloudfront_frontend && !local.use_default_function ? 1 : 0
  name  = var.cloudfront_function_path
  stage = "LIVE"
}

locals {
  frontend_function_arn = local.use_default_function ? aws_cloudfront_function.root_rewrite[0].arn : data.aws_cloudfront_function.custom[0].arn
}

resource "aws_s3_bucket_policy" "frontend" {
  count  = var.create_frontend_bucket && var.create_cloudfront_frontend ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id

  depends_on = [aws_s3_bucket_public_access_block.frontend[0]]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend[0].arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend[0].arn
          }
        }
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "frontend" {
  count = var.create_cloudfront_frontend ? 1 : 0

  enabled         = true
  is_ipv6_enabled = true
  aliases         = [var.domain_name]
  comment         = "Frontend - ${var.domain_name}"
  price_class     = var.cloudfront_price_class

  origin {
    domain_name              = aws_s3_bucket.frontend[0].bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend[0].id
    origin_id                = "frontend"
  }

  default_cache_behavior {
    target_origin_id       = "frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    function_association {
      event_type   = "viewer-request"
      function_arn = local.frontend_function_arn
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  viewer_certificate {
    acm_certificate_arn      = local.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-frontend-cdn" })
}

resource "aws_cloudfront_distribution" "api" {
  count = var.create_cloudfront_api ? 1 : 0

  enabled         = true
  is_ipv6_enabled = true
  aliases         = [local.api_domain]
  comment         = "API proxy - ${local.api_domain}"
  price_class     = var.cloudfront_price_class

  origin {
    domain_name = var.compute_endpoint
    origin_id   = "backend"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "backend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Host", "Origin", "Referer", "X-Forwarded-For", "X-Forwarded-Proto"]
      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  viewer_certificate {
    acm_certificate_arn      = local.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-api-cdn" })
}

resource "aws_route53_zone" "this" {
  count = var.create_route53_zone ? 1 : 0
  name  = var.domain_name

  tags = merge(var.tags, { Name = "${var.name_prefix}-zone" })
}

locals {
  zone_id = var.create_route53_zone ? aws_route53_zone.this[0].zone_id : var.zone_id
}

resource "aws_route53_record" "cert_validation" {
  for_each = var.create_route53_zone && var.acm_certificate_arn == "" ? {
    for dvo in aws_acm_certificate.this[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  zone_id         = local.zone_id
  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
}

resource "aws_acm_certificate_validation" "this" {
  count = var.acm_certificate_arn == "" ? 1 : 0

  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.this[0].arn
  validation_record_fqdns = var.create_route53_zone ? [for record in aws_route53_record.cert_validation : record.fqdn] : []
}

resource "aws_route53_record" "frontend" {
  count   = var.create_route53_zone && var.create_cloudfront_frontend ? 1 : 0
  zone_id = local.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend[0].domain_name
    zone_id                = aws_cloudfront_distribution.frontend[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api" {
  count   = var.create_route53_zone && var.create_cloudfront_api ? 1 : 0
  zone_id = local.zone_id
  name    = local.api_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.api[0].domain_name
    zone_id                = aws_cloudfront_distribution.api[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "backend_origin" {
  count   = var.create_route53_zone && var.compute_endpoint != "" ? 1 : 0
  zone_id = local.zone_id
  name    = local.backend_domain
  type    = "A"
  ttl     = 300
  records = [var.compute_endpoint]
}

resource "aws_iam_user" "ci_cd" {
  count = var.create_ci_cd_user ? 1 : 0
  name  = "${var.name_prefix}-ci-cd"

  tags = merge(var.tags, { Name = "${var.name_prefix}-ci-cd" })
}

resource "aws_iam_policy" "ci_cd" {
  count       = var.create_ci_cd_user ? 1 : 0
  name        = "${var.name_prefix}-ci-cd-policy"
  description = "Permissions for CI/CD deployments"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      var.create_frontend_bucket && var.create_ci_cd_user ? [
        {
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject",
            "s3:ListBucket"
          ]
          Resource = [
            aws_s3_bucket.frontend[0].arn,
            "${aws_s3_bucket.frontend[0].arn}/*"
          ]
        }
      ] : [],
      var.create_cloudfront_frontend && var.create_ci_cd_user ? [
        {
          Effect   = "Allow"
          Action   = "cloudfront:CreateInvalidation"
          Resource = aws_cloudfront_distribution.frontend[0].arn
        }
      ] : []
    )
  })
}

resource "aws_iam_user_policy_attachment" "ci_cd" {
  count      = var.create_ci_cd_user ? 1 : 0
  user       = aws_iam_user.ci_cd[0].name
  policy_arn = aws_iam_policy.ci_cd[0].arn
}

resource "aws_iam_access_key" "ci_cd" {
  count = var.create_ci_cd_user ? 1 : 0
  user  = aws_iam_user.ci_cd[0].name
}
