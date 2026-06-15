# DynamoDB table for Terraform state locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "${var.project}-terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "${var.project}-terraform-state-locks"
    Role        = var.role
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}
