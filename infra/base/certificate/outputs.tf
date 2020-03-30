output "certificate_arn" {
  value = var.turbo_mode ? "" : aws_acm_certificate_validation.cert_validation[0].certificate_arn
}

output "certificate_resource_record_name" {
  value = var.turbo_mode ? "" : aws_acm_certificate.cert[0].domain_validation_options[0].resource_record_name
}

output "certificate_resource_record_value" {
  value = var.turbo_mode ? "" : aws_acm_certificate.cert[0].domain_validation_options[0].resource_record_value
}

output "certificate_resource_record_type" {
  value = var.turbo_mode ? "" : aws_acm_certificate.cert[0].domain_validation_options[0].resource_record_type
}
