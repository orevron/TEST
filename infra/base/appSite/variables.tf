variable "region" {
  type        = "string"
  description = "the aws region"
}

variable "aws_profile" {
  type = "string"
}

variable "path_to_origin_folder" {
  type        = "string"
  description = "the relative path to build folder"
  default     = "../../client/"
}

variable "domain" {
  type = "string"
}

variable "cert_arn" {
  type        = "string"
  description = "the certificate of the stack"
}

variable "api_subdomain" {
  type = "string"
}

variable "unique_tag" {
  description = "A unique name to identify all the resources created by this run. Must be a single word, no '-' or '_'"
  type        = "string"
}

variable "turbo_mode" {
  description = "A flag that indicate wether to create route53 domain and cerficate or use AWS auto-generate domains"
}

variable "monitor" {
  type = "map"

  default = {
    enable               = false
    sns_topic_error_name = ""
  }
}

variable "api_gateway_invoke_url" {
  type = "string"
}

variable "user_pool_id" {
  type        = "string"
  description = "the app user pool id"
}

variable "google_analytics_key" {
  type        = "string"
  description = "The key of google analytics account"
}

variable "app_npm_token" {
  type = "string"
  description = "token for accessing bridgecrew repository on npmjs"
}

variable "cognito_user_pool_domain" {
  type = "string"
  description = "cognito user pool domain name"
}

variable "github_app_id" {
  type = "string"
  description = "Github app client id"
}

variable "scanners_results_bucket" {
  type = "string"
  description = "scanners results bucket name"
}
