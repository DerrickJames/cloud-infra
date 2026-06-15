resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.project}-${var.env}-vpc"
    Project = var.project
    Environment = var.env
    ManagedBy = "terraform"
  }
}

resource "aws_subnet" "public_subnet" {
  for_each = var.public_subnet_numbers
  vpc_id = aws_vpc.vpc.id
  cidr_block = cidrsubnet(aws_vpc.vpc.cidr_block, 4, each.value)

  tags = {
    Name = "${var.project}-${var.env}-public-subnet-${each.value}"
    Role = "public"
    Project = var.project
    Environment = var.env
    ManagedBy = "terraform"
  }
}

resource "aws_subnet" "private_subnet" {
  for_each = var.private_subnet_numbers
  vpc_id = aws_vpc.vpc.id
  cidr_block = cidrsubnet(aws_vpc.vpc.cidr_block, 4, each.value)

  tags = {
    Name = "${var.project}-${var.env}-private-subnet-${each.value}"
    Role = "private"
    Project = var.project
    Environment = var.env
    ManagedBy = "terraform"
  }
}

# Internet Gateway (IGW)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project}-${var.env}-igw"
    Role = "public"
    Project = var.project
    Environment = var.env
    ManagedBy = "terraform"
  }
}

# NAT Gateway (NGW)
resource "aws_eip" "ngw_eip" {
  domain = "vpc"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "${var.project}-${var.env}-ngw-eip"
    Role = "private"
    Project = var.project
    Environment = var.env
    ManagedBy = "terraform"
  }
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ngw_eip.id
  subnet_id = aws_subnet.public_subnet[element(keys(aws_subnet.public_subnet), 0)].id

  tags = {
    Name = "${var.project}-${var.env}-ngw"
    Role = "private"
    Project = var.project
    Environment = var.env
    ManagedBy = "terraform"
  }
}

# Route Tables (RT)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project}-${var.env}-public-rt"
    Role = "public"
    Project = var.project
    Environment = var.env
    ManagedBy = "terraform"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project}-${var.env}-private-rt"
    Role = "private"
    Project = var.project
    Environment = var.env
    ManagedBy = "terraform"
  }
}

# Public Route
resource "aws_route" "public_route" {
  route_table_id = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

# Private Route
resource "aws_route" "private_route" {
  route_table_id = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.ngw.id
}

# Public Route Table Association
resource "aws_route_table_association" "public_rt_association" {
  for_each = aws_subnet.public_subnet
  subnet_id = each.value.id
  route_table_id = aws_route_table.public_rt.id
}

# Private Route Table Association
resource "aws_route_table_association" "private_rt_association" {
  for_each = aws_subnet.private_subnet
  subnet_id = each.value.id
  route_table_id = aws_route_table.private_rt.id
}

# Public security group
resource "aws_security_group" "public_sg" {
  name = "${var.project}-${var.env}-public-sg"
  description = "Public internet access"
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project}-${var.env}-public-sg"
    Role = "public"
    Project = var.project
    Environment = var.env
    ManagedBy = "terraform"
  }
}

# Public outbound security group rule
resource "aws_security_group_rule" "public_egress" {
  type = "egress"
  from_port = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public_sg.id
  description = "Allow all traffic to the internet"
}

# Public inbound security group rule - HTTP(80)
resource "aws_security_group_rule" "public_http_ingress" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "TCP"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public_sg.id
  description = "Allow HTTP traffic from the internet"
}

# Public inbound security group rule - HTTPS(443)
resource "aws_security_group_rule" "public_https_ingress" {
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "TCP"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public_sg.id
  description = "Allow HTTPS traffic from the internet"
}

# Private security group
resource "aws_security_group" "private_sg" {
  name = "${var.project}-${var.env}-private-sg"
  description = "Private network access"
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project}-${var.env}-private-sg"
    Role = "private"
    Project = var.project
    Environment = var.env
    ManagedBy = "terraform"
  }
}

# Private outbound security group rule
resource "aws_security_group_rule" "private_egress" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.private_sg.id
  description = "Allow all traffic to the internet"
}

# Private inbound security group rule - IP range in the VPC
resource "aws_security_group_rule" "private_ingress" {
  type = "ingress"
  from_port = 0
  to_port = 65535
  protocol = "-1"
  cidr_blocks = [aws_vpc.vpc.cidr_block]
  security_group_id = aws_security_group.private_sg.id
  description = "Allow all traffic from the VPC"
}