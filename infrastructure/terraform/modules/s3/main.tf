data "aws_caller_identity" "current" {}


resource "aws_s3_bucket" "this" {
  bucket = "${data.aws_caller_identity.current.account_id}-mongo-db-backup-buckets"
  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  # Reference your existing bucket
  bucket = aws_s3_bucket.this.bucket


  rule {
    id     = "backups-delete"
    status = "Enabled"

    expiration {
      days = 1
    }
  }
}


resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "public_read" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.this.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.public_read.json
}