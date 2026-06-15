variable "bucket_name" {
  description = "The name of the S3 bucket to store Terraform state files."
  type        = string
}

# variable "tags" {
#   description = "A map of tags to assign to the S3 bucket."
#   type        = map(string)
#   default     = {}
# }

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

variable "github_oidc_role_arn" {
  description = "The ARN of the GitHub OIDC IAM Role."
  type        = string
}
