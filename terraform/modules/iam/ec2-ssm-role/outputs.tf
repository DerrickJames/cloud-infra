output "iam_instance_profile_name" {
  value       = aws_iam_instance_profile.ec2_ssm_instance_profile.name
  description = "The name of the EC2 SSM IAM instance profile."
}

output "ssm_user_name" {
  value       = aws_iam_user.ssm-user.name
  description = "The name of the SSM IAM user."
}

output "ssm_user_access_key_id" {
  value       = aws_iam_access_key.ssm_user_access_key.id
  description = "The access key ID for the SSM IAM user."
}

output "ssm_user_secret_access_key" {
  value       = aws_iam_access_key.ssm_user_access_key.secret
  description = "The secret access key for the SSM IAM user."
  sensitive   = true
}
