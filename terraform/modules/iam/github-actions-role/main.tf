# OIDC Identity Provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github_oidc" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # GitHub OIDC cert thumbprint

  tags = {
    Name = "${var.project}-${var.env}-github-oidc-provider"
    Role = var.role
    Project = var.project
    Environment = var.env
    ManagedBy = "terraform"
  }
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions_role" {
  name = "${var.project}-${var.env}-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role.json

  tags = {
    Name = "${var.project}-${var.env}-github-actions-role"
    Role = var.role
    Project = var.project
    Environment = var.env
    ManagedBy = "terraform"
  }
}

# Attach Policies to the Role
resource "aws_iam_role_policy_attachment" "github_actions_role_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = var.github_actions_policy_arn # TODO: tighten to a more restrictive policy
}