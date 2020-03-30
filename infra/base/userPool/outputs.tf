output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.pool.id
}

output "cognito_user_pool_domain" {
  value = var.certificate_arn == "" ? local.cognito_aws_generated_domain : local.cognito_route53_domain
}

output "cognito_cloudfront_distribution_arn" {
  value = var.certificate_arn == "" ? local.cognito_aws_generated_domain_cf_dist : local.cognito_route53_domain_cf_dist
}

output "app_users_client_id" {
  value = aws_cognito_user_pool_client.app_client.id
}

output "app_client_id" {
  value = aws_cognito_user_pool_client.app_client.id
}

output "cognito_user_pool_arn" {
  value = aws_cognito_user_pool.pool.arn
}
