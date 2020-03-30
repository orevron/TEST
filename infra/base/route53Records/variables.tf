variable "profile" {
  type        = "string"
  description = "The profile to be selected from the ~/.aws/credentials file to be used in the creation of the stack"
  default     = "root"
}

variable "hosted_zone_id" {
  type    = "string"
  default = "Z2CCHMURZOJZR6"
}

variable "app_cloudfront_dist_arn" {
  type = "string"
}

variable "cognito_cloudfront_distribution_arn" {}

variable "certificate_record_name" {}

variable "certificate_record_type" {}

variable "certificate_record_value" {}

variable "domain" {}

variable "cognito_subdomain" {}
variable "app_subdomain" {}

variable "accelerator_dns_name" {}

variable "turbo_mode" {
  description = "A flag that indicate wether to create route53 domain and cerficate or use AWS auto-generate domains"
}
