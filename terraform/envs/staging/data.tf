# data "aws_ami" "app" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["al2023-ami-2023.*-x86_64"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   filter {
#     name   = "architecture"
#     values = ["x86_64"]
#   }
# }

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Environment"
    values = ["development"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "tag:Environment"
    values = ["development"]
  }

  filter {
    name   = "tag:Role"
    values = ["public"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "tag:Environment"
    values = ["development"]
  }

  filter {
    name   = "tag:Role"
    values = ["private"]
  }
}

data "aws_security_group" "public" {
  filter {
    name   = "tag:Environment"
    values = ["development"]
  }

  filter {
    name   = "tag:Role"
    values = ["default-public"]
  }
}
