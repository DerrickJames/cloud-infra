variable "domain_name" {
  description = "The domain name to use for the ALB DNS record."
  type        = string
}

variable "subdomain_name" {
  description = "The subdomain name to use for the ALB DNS record."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "public_subnet_ids" {
  description = "A list of public subnet IDs."
  type        = list(string)
}

variable "security_group_ids" {
  description = "A list of security group IDs."
  type        = list(string)
}

variable "instance_security_group_id" {
  description = "The ID of the security group for the instances."
  type        = string
}

variable "instance_ids" {
  description = "A Map of stable keys to instance IDs."
  type        = map(string)
}

# variable "tags" {
#   description = "A map of tags to assign to the resources."
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
