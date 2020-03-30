variable "profile" {
  type        = "string"
  description = "The profile used by the AWS provider, as written in ~/.aws/credentials"
}

variable "region" {
  type    = "string"
  default = "us-east-1"
}

variable "domain" {
  type        = "string"
  description = "The domain, to be used as a suffix for the joker of the certificate. Example: dev.bridgecrew.com"
}

variable "cert_validation_record_fqdn" {
  type        = "string"
  description = "The certificate validation record fqdn"
}

variable "turbo_mode" {
  description = "A flag that indicate wether to create route53 domain and cerficate or use AWS auto-generate domains"
}
