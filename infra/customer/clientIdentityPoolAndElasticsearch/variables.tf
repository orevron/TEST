variable aws_profile {
  type = "string"
}

variable region {
  type = "string"
}

variable "customer_name" {
  type        = "string"
  description = "Customer name, will be part of the elasticsearch domain name."
}

variable "elasticsearch_version" {
  type    = "string"
  default = "6.8"
}

variable "instance_type" {
  description = "The type of instances to be created in the cluster"
  type        = "string"
  default     = "m5.2xlarge.elasticsearch"
}

variable "instance_count" {
  description = "The number of instances in the cluster"
  default     = 2
}

variable "snapshot_time_hour" {
  description = "The hour, in 24 hour format, when a snapshot of the domain is taken"
  default     = 0
}

variable "ebs_volume_size" {
  description = "The storage size of the EBS, in GB."
  default     = 150
}

variable "user_pool_id" {
  description = "The ID of the BridgeCrew user pool"
  type        = "string"
}

variable "encrypt_at_rest_enabled" {
  description = "Indicates whether the es instance has encryption-at-rest."
  default     = true
}


variable "monitor" {
  type = "map"

  default = {
    enable               = false
    sns_topic_error_name = ""
  }
}

variable "master_enable" {
  default = true
}

variable "master_type" {
  description = "The type of master instances to be created in the cluster"
  type        = "string"
  default     = "r5.large.elasticsearch"
}

variable "master_count" {
  description = "The number of master instances in the cluster"
  default     = 3
}

variable "base_stack_unique_tag" {
  type = string
}