resource "aws_route53_record" "record_name" {
  zone_id = data.aws_route53_zone.primary_hosted_zone.zone_id
  name    = var.subdomain_name
  type    = "A"

  alias {
    name                   = aws_lb.application_load_balancer.dns_name
    zone_id                = aws_lb.application_load_balancer.zone_id
    evaluate_target_health = true
  }
}

resource "aws_lb" "application_load_balancer" {
  name               = "${var.project}-${var.env}-${var.role}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = var.security_group_ids

  tags = {
    Name        = "${var.project}-${var.env}-${var.role}-alb"
    Role        = var.role
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "${var.project}-${var.env}-${var.role}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/api-tools/swagger"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.project}-${var.env}-${var.role}-tg"
    Role        = var.role
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = {
    Name        = "${var.project}-${var.env}-${var.role}-http-listener"
    Role        = var.role
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  tags = {
    Name        = "${var.project}-${var.env}-${var.role}-https-listener"
    Role        = var.role
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

resource "aws_lb_target_group_attachment" "target_group_attachment" {
  for_each         = var.instance_ids
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = each.value
  port             = 80
}

resource "aws_security_group" "alb_security_group" {
  name   = "${var.project}-${var.env}-${var.role}-alb-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic from the internet"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from the internet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all traffic to the internet"
  }

  tags = {
    Name        = "${var.project}-${var.env}-${var.role}-alb-sg"
    Role        = var.role
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group_rule" "instance_ingress_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  security_group_id        = var.instance_security_group_id
  source_security_group_id = aws_security_group.alb_security_group.id
}
