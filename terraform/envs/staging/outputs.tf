output "subnet_id_value" {
  value = data.aws_subnets.private.ids[0]
}

output "ec2_private_ip" {
  value = module.appName_api.ec2_private_ip
}

output "ec2_instance_id" {
  value = module.appName_api.ec2_instance_id
}

output "iam_instance_profile_name" {
  value       = module.iam_ec2_ssm.iam_instance_profile_name
  description = "The name of the EC2 SSM IAM instance profile."
}

output "ssm_user_name" {
  value       = module.iam_ec2_ssm.ssm_user_name
  description = "The name of the SSM IAM user."
}

output "ssm_user_access_key_id" {
  value       = module.iam_ec2_ssm.ssm_user_access_key_id
  description = "The access key ID for the SSM IAM user."
}

output "ssm_user_access_key_secret" {
  value       = module.iam_ec2_ssm.ssm_user_secret_access_key
  description = "The secret access key for the SSM IAM user."
  sensitive   = true
}

# output "terraform_state_bucket" {
#   value       = module.s3_bucket.s3_bucket_name
#   description = "The name of the S3 bucket for Terraform state."
# } 
