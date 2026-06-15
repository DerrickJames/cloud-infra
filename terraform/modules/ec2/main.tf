resource "random_shuffle" "subnet_ids" {
  input = var.subnets
  result_count = 1
}

resource "aws_instance" "ec2_instance" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  # key_name                    = var.key_name
  ebs_optimized               = var.ebs_optimized
  associate_public_ip_address = var.associate_public_ip_address
  # subnet_id                   = var.subnet_id
  subnet_id = random_shuffle.subnet_ids.result[0]
  vpc_security_group_ids      = var.security_group_ids
  iam_instance_profile        = var.iam_instance_profile_name

  root_block_device {
    encrypted   = var.encrypted_root_block_device
    volume_size = var.volume_size
    volume_type = var.volume_type

    tags = {
      Name        = "${var.project}-${var.env}-${var.role}-root-block-device"
      Role        = var.role
      Project     = var.project
      Environment = var.env
      ManagedBy   = "terraform"
    }
  }

  tags = {
    Name        = "${var.project}-${var.env}-${var.role}"
    Role        = var.role
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}
