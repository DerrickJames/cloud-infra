variable "instance_type" {
  description = "The type of instance to use."
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "The AMI ID to use for the instances."
  type        = string
}

# variable "key_name" {
#   description = "The name of the key pair to use for the instances."
#   type        = string
# }

# TODO: remove this once subnets are shuffled
# variable "subnet_id" {
#   description = "A list of subnet IDs where the instances will be launched."
#   type        = string
# }

variable "subnets" {
  description = "A list of subnet IDs."
  type        = list(string)
  validation {
    condition     = length(var.subnets) > 0
    error_message = "Subnets must be a list of at least one subnet ID."
  }
}

variable "security_group_ids" {
  description = "A list of security group IDs to associate with the instances."
  type        = list(string)
}

variable "iam_instance_profile_name" {
  description = "The name of the IAM instance profile to associate with the instances."
  type        = string
}

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
