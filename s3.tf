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