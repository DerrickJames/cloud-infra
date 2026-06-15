data "aws_route53_zone" "primary_hosted_zone" {
  name         = var.domain_name
  private_zone = false
}

data "aws_acm_certificate" "certificate" {
  domain      = "*.${var.domain_name}"
  statuses    = ["ISSUED"]
  most_recent = true
}
