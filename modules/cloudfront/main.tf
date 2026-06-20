locals {
  name_prefix   = "${var.project}-${var.environment}"
  origin_domain = "origin.${var.domain_name}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "cloudfront"
    Owner       = "FleetOps-Team"
  }
}

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "FleetOps CloudFront CDN"
  aliases             = [var.domain_name, "www.${var.domain_name}"]
  web_acl_id          = var.waf_web_acl_arn

  origin {
    domain_name = local.origin_domain
    origin_id   = "ALBOrigin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ALBOrigin"

    viewer_protocol_policy = "redirect-to-https"
    
    # Forward all headers, cookies, and query strings to the ALB (disable caching for API)
    # Note: In a real prod setup, you'd have a separate cache behavior for /static/*
    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = local.common_tags
}

# Create the Alias record pointing the root domain to CloudFront
resource "aws_route53_record" "cf_alias" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}




