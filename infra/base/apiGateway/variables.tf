variable "region" {
  type        = "string"
  description = "The region in which the stack will be deployed"
}

variable "apigw_name" {
  type        = "string"
  description = "The name of the api gateway"
}

variable "stage" {
  type        = "string"
  description = "The AapiGW deployment stage"
}

variable "certificate_arn" {
  type        = "string"
  description = "The certificate arn"
}

variable "domain" {
  type = "string"
}

variable "sub_domain" {
  type = "string"
}

variable "unique_tag" {
  description = "A unique name to identify all the resources created by this run. Must be a single word, no '-' or '_'"
  type        = "string"
}

variable "monitor" {
  type = "map"

  default = {
    enable               = false
    sns_topic_error_name = ""
  }
}

variable "turbo_mode" {
  description = "A flag that indicate wether to create route53 domain and cerficate or use AWS auto-generate domains"
}

variable "jira_function_names" {
  type        = "list"
  description = "jira lambda names"
}

variable "integrations_handler_function_name" {
  type        = "list"
  description = "integration lambda function names"
}

variable "swagger_file_path" {
  description = "The path to the swagger file"
  default     = "../../swagger/swagger.yml"
}

variable "user_pool_arn" {
  description = "The BridgeCrew user pool ARN"
  type        = "string"
}

variable "remediation_function_arns" {
  type        = "list"
  description = "The ARNs of the remediation functions, ordered by controller first and remote remediation afterwards"
}

variable "violations_function_names" {
  type        = "list"
  description = "violation API lambda names"
}

variable "customers_function_names" {
  type        = "list"
  description = "customer API lambda names"
}
variable "logstash_function_name" {
  description = "The name of the logstash handler"
  type        = "list"
}

variable "cloudmapper_api_function_name" {
  description = "the name of the cloudmapper api handler"
  type        = "list"
}

variable "authorization_functions_names" {
  description = "authorization lambda names"
  type        = "list"
}

variable "snapshots_api_function_name" {
  description = "the name of the snapshots api handler"
  type        = "list"
}

variable "github_api_function_name" {
  description = "The name of the github api manager"
  type        = "list"
}

variable "benchmarks_function_names" {
  type        = "list"
  description = "benchmarks API lambda names"
}