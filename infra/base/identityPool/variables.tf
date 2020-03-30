variable "user_pool_id" {
  type        = "string"
  description = "the id of bc user pool id"
}

variable "app_client_id" {
  type        = "string"
  description = "the app client id of bc user pool"
}

variable "region" {
  type = "string"
}

variable "api_gateway_id" {
  type        = "string"
  description = "the api gatway id of the app"
}

variable "unique_tag" {
  type = "string"
}

variable "aws_profile" {
  type        = "string"
  description = "AWS provider profile"
}