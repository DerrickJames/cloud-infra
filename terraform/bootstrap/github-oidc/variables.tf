variable "env" {
  description = "The deployment environment (dev|staging|prod)."
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "Environment must be one of 'dev', 'staging', or 'prod'."
  }
}

variable "project" {
  description = "The name of the project."
  type        = string
  default     = "appName"
}

variable "role" {
  description = "The name of the role."
  type        = string
  default     = "api"
}

variable "github_org" {
  description = "The GitHub organization name."
  type        = string
}

variable "github_repo" {
  description = "The GitHub repository name."
  type        = string
}

variable "github_actions_policy_arn" {
  description = "The ARN of the IAM policy to attach to the GitHub Actions role."
  type        = string
}
