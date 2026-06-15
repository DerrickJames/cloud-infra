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

variable "ec2_ssm_managed_policy_arn" {
  type        = string
  description = "The ARN of the managed policy to attach to the EC2 SSM role."
}
