output "bucket_name" {
  value = aws_s3_bucket.app_bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.app_bucket.arn
}

output "bucket_regional_domain_name" {
  value = aws_s3_bucket.app_bucket.bucket_regional_domain_name
}

// Will have value only in non-turbo mode
output "cf_distribution_domain_name" {
  value = element(concat(aws_cloudfront_distribution.distribution.*.domain_name, list("")), 0)
}

output "bucket_distribution_domain_name" {
  value = element(concat(aws_s3_bucket.app_bucket.*.website_endpoint, list("")), 0)
}
