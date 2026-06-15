# GitHub Actions IAM Role for Staging Environment
module "github_actions_staging_role" {
  source = "../../modules/iam/github-actions-role"

  project = var.project
  env     = var.env
  role    = var.role

  github_org                = var.github_org
  github_repo               = var.github_repo
  github_actions_policy_arn = var.github_actions_policy_arn
}
