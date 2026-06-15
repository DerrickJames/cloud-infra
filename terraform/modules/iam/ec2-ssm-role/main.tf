# IAM Role for EC2 with SSM Access
resource "aws_iam_role" "ec2_ssm_role" {
  name               = "${var.project}-${var.env}-ec2-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_ssm_assume_role.json

  tags = {
    Name = "${var.project}-${var.env}-ec2-ssm-role"
    Role = var.role
    Project = var.project
    Environment = var.env
    ManagedBy = "terraform"
  }
}

# Attach Managed Policy to the Role
resource "aws_iam_role_policy_attachment" "ec2_ssm_managed" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = var.ec2_ssm_managed_policy_arn
}

# IAM Instance Profile for EC2 SSM Role
resource "aws_iam_instance_profile" "ec2_ssm_instance_profile" {
  name = "${var.project}-${var.env}-ec2-ssm-instance-profile"
  role = aws_iam_role.ec2_ssm_role.name

  tags = {
    Name = "${var.project}-${var.env}-ec2-ssm-instance-profile"
    Role = var.role
    Project = var.project
    Environment = var.env
    ManagedBy = "terraform"
  }
}

# IAM User for SSM only Access
resource "aws_iam_user" "ssm-user" {
  name = "${var.project}-${var.env}-ssm-user"

  tags = {
    Name = "${var.project}-${var.env}-ssm-user"
    Project = var.project
    Environment = var.env
    ManagedBy = "terraform"
  }
}

# Attach Inline Policy to SSM User
resource "aws_iam_user_policy" "ssm_user_policy" {
  name   = "${var.project}-${var.env}-ssm-user-policy"
  user   = aws_iam_user.ssm-user.name
  policy = data.aws_iam_policy_document.ssm_user_policy.json
}

# IAM Access Key for SSM User
resource "aws_iam_access_key" "ssm_user_access_key" {
  user = aws_iam_user.ssm-user.name
}