variable "region" {
  type        = "string"
  description = "AWS provider region"
}

variable "is_bucket_exist" {
  default     = false
  description = "Indiation if the bucket is already exist"
}

variable "s3_bucket_name" {
  type        = "string"
  description = "The S3 bucket name"
}

variable "cloudtrail_template_path" {
  type        = "string"
  description = "The cloud formation base template file path. The path is relative to the current directory"
  default     = "cf_cloudtrails_sensor_template.json"
}

variable "config_template_path" {
  type        = "string"
  description = "The cloud formation base template file path. The path is relative to the current directory"
  default     = "cf_cloudtrails_sensor_template.json"
}

variable "s3_access_template_path" {
  type        = "string"
  description = "The cloud formation base template file path. The path is relative to the current directory"
  default     = "cf_s3_access_template.json"
}

variable "template_object_name" {
  type        = "string"
  description = "The name of the template s3 object"
  default     = "cloud-formation-template.json"
}

variable "sns_topic_name" {
  type        = "string"
  description = "the sns arn to update in the template file"
}

variable "monitor" {
  type = "map"

  default = {
    enable               = false
    sns_topic_error_name = ""
  }
}

variable "unique_tag" {
  type        = "string"
  description = "A unique name to identify all the resources created by this run"
}
