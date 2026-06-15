output "terraform_state_bucket" {
  value       = module.s3_bucket.s3_bucket_name
  description = "The name of the S3 bucket for Terraform state."
}
