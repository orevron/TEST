provider "aws" {
  region  = "us-east-1"
  profile = "route53"
}

resource "aws_route53_record" "auth_record" {
  count   = var.turbo_mode ? 0 : 1
  name    = "${var.cognito_subdomain}.${var.domain}"
  type    = "A"
  zone_id = var.hosted_zone_id

  alias {
    evaluate_target_health = false
    name                   = var.cognito_cloudfront_distribution_arn

    // The cloudfront Zone ID is constant, and therefore can be hardcoded
    zone_id = "Z2FDTNDATAQYW2"
  }
}

resource "aws_route53_record" "app_record" {
  count   = var.turbo_mode ? 0 : 1
  name    = "${var.app_subdomain}.${var.domain}"
  type    = "A"
  zone_id = var.hosted_zone_id

  alias {
    evaluate_target_health = false
    name                   = var.app_cloudfront_dist_arn

    // The cloudfront Zone ID is constant, and therefore can be hardcoded
    zone_id = "Z2FDTNDATAQYW2"
  }
}

module "consts" {
  source = "../../../../utils/terraform/consts"
}

resource "aws_route53_record" "logstash_record" {
  count   = var.turbo_mode ? 0 : 1
  name    = "logs.${var.domain}"
  type    = "A"
  zone_id = module.consts.bridgecrew_zone_id

  alias {
    evaluate_target_health = false
    name                   = var.accelerator_dns_name.result.dnsName

    // The accelerator Zone ID is constant, and therefore can be hardcoded
    zone_id = module.consts.accelerator_zone_id
  }
}

resource "aws_route53_record" "domain_record" {
  count   = var.turbo_mode ? 0 : 1
  name    = var.domain
  type    = "A"
  zone_id = var.hosted_zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_route53_record.app_record.*.name[0]
    zone_id                = aws_route53_record.app_record.*.zone_id[0]
  }
}

resource "aws_route53_record" "cert_validation_record" {
  count   = var.turbo_mode ? 0 : 1
  name    = var.certificate_record_name
  type    = var.certificate_record_type
  zone_id = var.hosted_zone_id
  records = [var.certificate_record_value]
  ttl     = 300
}
