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

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "cf_logs" {
  #checkov:skip=CKV2_AWS_62:Event notifications not required for CloudFront access logs
  #checkov:skip=CKV_AWS_144:Cross-region replication not required for access logs
  #checkov:skip=CKV_AWS_18:Recursive access logging not applicable for the log destination bucket
  #checkov:skip=CKV_AWS_145:CloudFront log delivery requires SSE-S3; CMK not supported by the service
  bucket        = "${local.name_prefix}-cf-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  tags          = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "cf_logs" {
  bucket                  = aws_s3_bucket.cf_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "cf_logs" {
  #checkov:skip=CKV2_AWS_65:BucketOwnerPreferred required for CloudFront log delivery which uses ACL-based delivery mechanism
  bucket = aws_s3_bucket.cf_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cf_logs" {
  #checkov:skip=CKV_AWS_145:CloudFront log delivery requires SSE-S3; KMS CMK not supported for this delivery mechanism
  bucket = aws_s3_bucket.cf_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  rule {
    id     = "expire-old-cf-logs"
    status = "Enabled"
    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_versioning" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "${local.name_prefix}-security-headers"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
    referrer_policy {
      referrer_policy = "same-origin"
      override        = true
    }
  }
}

resource "aws_cloudfront_distribution" "main" {
  #checkov:skip=CKV_AWS_374:Geo-restriction not required for this training project
  #checkov:skip=CKV_AWS_310:Origin failover not required for this training project
  #checkov:skip=CKV2_AWS_47:WAF includes AWSManagedRulesKnownBadInputsRuleSet (Log4j protection); cross-module reference not visible to checkov
  #checkov:skip=CKV2_AWS_46:CloudFront uses ALB as origin (not S3); S3 Origin Access Control not applicable
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "FleetOps CloudFront CDN"
  aliases             = [var.domain_name, "www.${var.domain_name}"]
  web_acl_id          = var.waf_web_acl_arn
  default_root_object = "index.html"

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
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "ALBOrigin"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }
  }

  logging_config {
    bucket          = aws_s3_bucket.cf_logs.bucket_domain_name
    include_cookies = false
    prefix          = "cf-logs/"
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

  depends_on = [aws_s3_bucket_ownership_controls.cf_logs]
}

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
