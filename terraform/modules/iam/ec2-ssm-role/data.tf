data "aws_iam_policy_document" "ec2_ssm_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "ssm_user_policy" {
  statement {
    sid    = "AllowSSMSession"
    effect = "Allow"

    actions = [
      "ssm:StartSession",
      "ssm:TerminateSession",
      "ssm:ResumeSession",
      "ssm:DescribeSessions",
      "ssm:GetConnectionStatus"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowDescribeInstances"
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowDescribeDBClusters"
    effect = "Allow"

    actions = [
      "rds:DescribeDBClusters"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowListTagsForResource"
    effect = "Allow"

    actions = [
      "rds:ListTagsForResource"
    ]

    resources = ["*"]
  }
}
