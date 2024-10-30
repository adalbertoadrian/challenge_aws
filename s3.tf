# storage bucket
resource "aws_s3_bucket" "webapplicationbucket" {
  bucket = var.webapplication_bucket
}

resource "aws_s3_bucket_versioning" "webapplicationbucket_versioning" {
  bucket = aws_s3_bucket.webapplicationbucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# bucket lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "webapplicationbucket_lifecycle" {
  bucket = aws_s3_bucket.webapplicationbucket.id

  rule {
    id     = "MoveToGlacier"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

# policy definition
data "aws_iam_policy_document" "webapplicationbucket_s3_policy" {
  statement {
    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.webapplicationbucket.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.bucket_cloudfront.arn]
    }
  }
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.webapplicationbucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = aws_s3_bucket.webapplicationbucket.id
  policy = data.aws_iam_policy_document.webapplicationbucket_s3_policy.json
}


# cloudwatch alert
resource "aws_cloudwatch_metric_alarm" "s3_storage_alarm" {
  alarm_name          = "S3StorageAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period              = "86400" # 1 day
  statistic           = "Average"
  threshold           = 1000000000 # 1 GB
  alarm_description   = "alert storage > 1 GB"
  dimensions = {
    BucketName  = aws_s3_bucket.webapplicationbucket.bucket
    StorageType = "StandardStorage"
  }

  alarm_actions = [var.sns_topic]
}