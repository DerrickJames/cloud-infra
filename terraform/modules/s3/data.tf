data "aws_iam_policy_document" "bucket_policy_document" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.s3_bucket.arn,
      "${aws_s3_bucket.s3_bucket.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # Second statement - Allow GitHub OIDC Role access to the bucket
  # statement {
  #   sid    = "AllowTerraformStateBucketRead"
  #   effect = "Allow"

  #   principals {
  #     type        = "AWS"
  #     identifiers = compact([var.github_oidc_role_arn])
  #   }

  #   actions = [
  #     "s3:ListBucket",
  #     "s3:GetBucketLocation",
  #   ]

  #   resources = [
  #     aws_s3_bucket.s3_bucket.arn
  #   ]
  # }

  # statement {
  #   sid    = "AllowTerraformStateObjectReadWriteDelete"
  #   effect = "Allow"

  #   principals {
  #     type        = "AWS"
  #     identifiers = compact([var.github_oidc_role_arn])
  #   }

  #   actions = [
  #     "s3:GetObject",
  #     "s3:PutObject",
  #     "s3:DeleteObject"
  #   ]

  #   resources = ["${aws_s3_bucket.s3_bucket.arn}/*"]
  # }
}
