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

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_numbers" {
  description = "Map of AZ to a number to be used for public subnets."
  type        = map(number)
  default = {
    "us-west-2a" = 1
    "us-west-2b" = 2
    "us-west-2c" = 3
  }
}

variable "private_subnet_numbers" {
  description = "Map of AZ to a number to be used for private subnets."
  type        = map(number)
  default = {
    "us-west-2a" = 4
    "us-west-2b" = 5
    "us-west-2c" = 6
  }
}
