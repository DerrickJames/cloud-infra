output "github_oidc_role_arn" {
  value       = aws_iam_role.github_actions_role.arn
  description = "The ARN of the GitHub OIDC IAM Role."
}

output "github_oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.github_oidc.arn
  description = "The ARN of the GitHub OIDC IAM Provider."
}
