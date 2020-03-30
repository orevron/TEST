provider "aws" {
  region  = var.region
  profile = var.profile
}

locals {
  cert_arn = var.turbo_mode ? "cert" : aws_acm_certificate.cert.*.arn[0]
}

// Since it is impossible to set count on module, we set it on all module resources.
// The count prevent these resources from being created in case the "turbo_mode" is enabled

resource "aws_acm_certificate" "cert" {
  count             = var.turbo_mode ? 0 : 1
  domain_name       = "*.${var.domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert_validation" {
  count           = var.turbo_mode ? 0 : 1
  certificate_arn = aws_acm_certificate.cert.*.arn[0]

  validation_record_fqdns = [
    var.cert_validation_record_fqdn,
  ]
}

// This resource creates a delay for the certificate deletion, since aws_acm_certificate has a
// non-configurable timeout of 10 minutes.
// It is needed because the base stack creates cloudfront distributions in the background, and so cannot wait
// on their destruction.
resource "null_resource" "wait_until_certificate_is_not_in_use" {
  count = var.turbo_mode ? 0 : 1

  triggers = {
    build = local.cert_arn
  }

  provisioner "local-exec" {
    when = "destroy"

    command = <<BASH
#!/usr/bin/env bash

i=0
while [ $i -lt 60 ]
do
  i=$(( $i + 1 ))
  usage=$(aws acm describe-certificate --profile ${var.profile} --region us-east-1 --certificate-arn ${local.cert_arn} --output json | jq -r .Certificate.InUseBy | jq length)
  if [ $usage -gt 0 ]
  then
    echo "In use by $usage, waiting 1 more minute"
	sleep 60
  	echo "Waited $i minutes"
  else
  	echo "not in use"
    break
  fi
done
BASH
  }
}
