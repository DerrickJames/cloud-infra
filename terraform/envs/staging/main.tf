# resource "aws_key_pair" "ssh_key" {
#   key_name   = "appName-staging-key"
#   public_key = file(var.public_key_location)

#   tags = {
#     Name        = "${var.project}-${var.env}-ssh-key"
#     Role        = var.role
#     Project     = var.project
#     Environment = var.env
#     ManagedBy   = "terraform"
#   }
# }

# resource "aws_instance" "appName_api" {
#   ami = data.aws_ami.app.id
#   instance_type = var.instance_type
#   key_name = var.key_name
#   ebs_optimized = var.ebs_optimized
#   associate_public_ip_address = var.associate_public_ip_address
#   subnet_id = data.aws_subnets.private.ids[0]
#   security_groups = data.aws_security_groups.public.ids
#   iam_instance_profile = module.iam_ec2_ssm.iam_instance_profile_name

#   root_block_device {
#     encrypted = var.encrypted_root_block_device
#     volume_size = var.volume_size
#     volume_type = var.volume_type
#   }

#   tags = {
#     Name = "${var.project}-${var.env}-${var.role}"
#     Role = var.role
#     Project = var.project
#     Environment = var.env
#     ManagedBy = "terraform"
#   }
# }

module "vpc" {
  source = "../../modules/vpc"

  env      = var.env
  role     = var.role
  project  = var.project
  vpc_cidr = var.vpc_cidr
}

module "appName_api" {
  source = "../../modules/ec2"

  project = var.project
  env     = var.env
  role    = var.role

  # ami_id                      = data.aws_ami.app.id
  ami_id        = var.ami_id
  instance_type = var.instance_type
  # key_name                    = aws_key_pair.ssh_key.key_name
  ebs_optimized               = var.ebs_optimized
  associate_public_ip_address = var.associate_public_ip_address
  # subnet_id                   = data.aws_subnets.private.ids[0]
  subnets = keys(module.vpc.private_subnets)
  # security_group_ids          = [data.aws_security_group.public.id]
  security_group_ids        = [module.vpc.public_security_group_id]
  iam_instance_profile_name = module.iam_ec2_ssm.iam_instance_profile_name

  encrypted_root_block_device = var.encrypted_root_block_device
  volume_size                 = var.volume_size
  volume_type                 = var.volume_type
}

module "application_load_balancer" {
  source = "../../modules/alb"

  project = var.project
  env     = var.env
  role    = var.role

  domain_name                = var.domain_name
  subdomain_name             = var.subdomain_name
  vpc_id                     = data.aws_vpc.vpc.id
  public_subnet_ids          = data.aws_subnets.public.ids
  security_group_ids         = [data.aws_security_group.public.id]
  instance_security_group_id = data.aws_security_group.public.id
  instance_ids = {
    api1 = module.appName_api.ec2_instance_id
  }
}

# module "github_oidc" {
#   source = "../../modules/iam/github-actions-role"

#   project = var.project
#   env     = var.env
#   role    = var.role

#   github_org                = var.github_org
#   github_repo               = var.github_repo
#   github_actions_policy_arn = var.github_actions_policy_arn
# }

module "iam_ec2_ssm" {
  source = "../../modules/iam/ec2-ssm-role"

  project = var.project
  env     = var.env
  role    = var.role

  ec2_ssm_managed_policy_arn = var.ec2_ssm_managed_policy_arn
}

# module "s3_bucket" {
#   source = "../../modules/s3"

#   project = var.project
#   env     = var.env
#   role    = var.role

#   bucket_name          = var.s3_bucket_name
#   github_oidc_role_arn = module.github_oidc.github_oidc_role_arn
# }
