output "cert_validation_record_fqdn" {
  value = "${element(concat(aws_route53_record.cert_validation_record.*.fqdn, list("")), 0)}"
}

output "route53_cognito_record" {
  value = "${element(concat(aws_route53_record.auth_record.*.name, list("")), 0)}"
}

output "route53_domain_record" {
  value = "${element(concat(aws_route53_record.domain_record.*.name, list("")), 0)}"
}
