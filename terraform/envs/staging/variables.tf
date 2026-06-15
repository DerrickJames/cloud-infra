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

variable "domain_name" {
  description = "The domain name to use for the ALB DNS record."
  type        = string
}

variable "subdomain_name" {
  description = "The subdomain name to use for the ALB DNS record."
  type        = string
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

variable "ec2_ssm_managed_policy_arn" {
  type        = string
  description = "The ARN of the managed policy to attach to the EC2 SSM role."
}

# variable "public_key_location" {
#   description = "The file path to the public SSH key."
#   type        = string
# }

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "ami_id" {
  description = "The AMI ID to use for the instances."
  type        = string
}

variable "instance_type" {
  description = "The type of AWS EC2 instance to use."
  type        = string
}

# variable "key_name" {
#   description = "The name of the SSH key pair."
#   type        = string
#   default     = "ssh-key-pair"
# }

variable "ebs_optimized" {
  description = "Whether the instance is EBS optimized."
  type        = bool
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with the instance."
  type        = bool
}

variable "encrypted_root_block_device" {
  description = "Whether the root volume should be encrypted."
  type        = bool
}

variable "volume_size" {
  description = "The size of the root block device in GB."
  type        = number
}

variable "volume_type" {
  description = "The type of volume for the root block device."
  type        = string
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket to create."
  type        = string
}
