output "github_oidc_role_arn" {
  value       = module.github_actions_staging_role.github_oidc_role_arn
  description = "The ARN of the GitHub OIDC IAM Role for the Staging Environment."
}

output "github_oidc_provider_arn" {
  value       = module.github_actions_staging_role.github_oidc_provider_arn
  description = "The ARN of the GitHub OIDC IAM Provider for the AWS account."
}
