resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = aws_s3_bucket.webapplicationbucket.bucket_regional_domain_name
}

resource "aws_cloudfront_distribution" "bucket_cloudfront" {
  enabled = true

  origin {
    domain_name = aws_s3_bucket.webapplicationbucket.bucket_regional_domain_name
    origin_id   = "origin_oic"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }

  }
  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https" #"allow-all"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id       = "origin_oic"

    forwarded_values {

      query_string = false

      cookies {
        forward = "none"
      }
    }

  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
  logging_config {
    include_cookies = false
    bucket          = "cloudfront-logs-challenge.s3.amazonaws.com"
    prefix          = aws_s3_bucket.webapplicationbucket.bucket_regional_domain_name
  }

  is_ipv6_enabled = false
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}