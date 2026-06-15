module "s3_bucket" {
  source = "../../modules/s3"

  project = var.project
  env     = var.env
  role    = var.role

  bucket_name          = var.s3_bucket_name
  github_oidc_role_arn = var.github_oidc_role_arn
}

module "dynamodb_table" {
  source = "../../modules/dynamodb"

  project = var.project
  env     = var.env
  role    = var.role
}
