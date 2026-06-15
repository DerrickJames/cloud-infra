# S3 Bucket
resource "aws_s3_bucket" "s3_bucket" {
  bucket = "${var.project}-${var.env}-${var.bucket_name}"

  tags = {
    Name        = "${var.project}-${var.env}-${var.bucket_name}"
    Role        = var.role
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket                  = aws_s3_bucket.s3_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "ownership_controls" {
  bucket = aws_s3_bucket.s3_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# KMS key to encrypt objects in the S3 bucket
# Specify key policy:
# - Account root has full admin of the key
# - GitHub OIDC Role can use kms:Encrypt/Decrypt/GenerateDataKey
resource "aws_kms_key" "kms_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "${var.project}-${var.env}-${var.bucket_name}-s3-kms-key"
    Role        = var.role
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

# KMS key alias
resource "aws_kms_alias" "kms_alias" {
  name          = "alias/${var.project}-${var.env}-${var.bucket_name}-s3-kms-alias"
  target_key_id = aws_kms_key.kms_key.key_id
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "server_side_encryption" {
  bucket = aws_s3_bucket.s3_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Versioning configuration for the S3 bucket
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.s3_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle configuration to expire old versions
resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  bucket = aws_s3_bucket.s3_bucket.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# Bucket policy to restrict access to specific IAM roles and enforce secure transport
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.s3_bucket.id

  policy = data.aws_iam_policy_document.bucket_policy_document.json
}
