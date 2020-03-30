data "aws_caller_identity" "current" {}

module consts {
  source = "../../../../utils/terraform/consts"
}

data "template_file" "cloudtrail_template" {
  template = file("${path.module}/cf_cloudtrails_sensor_template.json")
  vars = {
    sns_name   = var.sns_topic_name
    account_id = data.aws_caller_identity.current.account_id
    template_version    = module.consts.cloudtrail_template_version
  }
}

// Read the config template file content
data "local_file" "config_template_file_content" {
  filename = "./${var.config_template_path}"
}

// Read the config template file content
data "local_file" "s3_access_template_file_content" {
  filename = "./${var.s3_access_template_path}"
}

locals {
  config_template_with_sns                    = replace(data.local_file.config_template_file_content.content, "<SNS_NAME>", var.sns_topic_name)
  config_template_with_sns_and_account_id     = replace(local.config_template_with_sns, "<ORGANIZATION_ID>", data.aws_caller_identity.current.account_id)
  config_object_name                          = module.consts.cloudformation_customer_config_template_name
  s3_access_template_with_sns                 = replace(data.local_file.s3_access_template_file_content.content, "<SNS_NAME>", var.sns_topic_name)
  s3_access_template_with_sns_and_account_id  = replace(local.s3_access_template_with_sns, "<ORGANIZATION_ID>", data.aws_caller_identity.current.account_id)
  s3_access_object_name                       = module.consts.cloudformation_customer_s3_access_template_name
}

resource "local_file" "config_template_with_sns" {
  content  = local.config_template_with_sns_and_account_id
  filename = "./${local.config_object_name}-${timestamp()}"
}

resource "local_file" "s3_access_template_with_sns" {
  content  = local.s3_access_template_with_sns_and_account_id
  filename = "./${local.s3_access_object_name}-${timestamp()}"
}

// Put the files in the bucket
resource "aws_s3_bucket_object" "cloudtrail_template_object" {
  bucket  = var.s3_bucket_name
  key     = var.template_object_name
  content = data.template_file.cloudtrail_template.rendered
  acl     = "public-read"
  etag    = md5(data.template_file.cloudtrail_template.rendered)
}

resource "aws_s3_bucket_object" "config_template_object" {
  bucket = var.s3_bucket_name
  key    = local.config_object_name
  source = local_file.config_template_with_sns.filename
  acl    = "public-read"
  etag   = md5(data.local_file.config_template_file_content.content)
}

resource "aws_s3_bucket_object" "s3_access_template_object" {
  bucket = var.s3_bucket_name
  key    = local.s3_access_object_name
  source = local_file.s3_access_template_with_sns.filename
  acl    = "public-read"
  etag   = md5(data.local_file.s3_access_template_file_content.content)
}

locals {
  cloudtrail_template_object_url = "https://s3.${var.region}.amazonaws.com/${var.s3_bucket_name}/${var.template_object_name}"
  config_template_object_url     = "https://s3.${var.region}.amazonaws.com/${var.s3_bucket_name}/${local.config_object_name}"
  s3_access_template_object_url  = "https://s3.${var.region}.amazonaws.com/${var.s3_bucket_name}/${local.s3_access_object_name}"
}

// ------ Monitor ------
data "aws_sns_topic" "sns_topic_monitor_error" {
  count = var.monitor["enable"] ? 1 : 0
  name  = var.monitor["sns_topic_error_name"]
}

resource "aws_cloudwatch_metric_alarm" "create_alarm_bucket_changes" {
  count               = var.monitor["enable"] ? 1 : 0
  alarm_name          = "app-s3-bucket-size-changes-${var.s3_bucket_name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"

  dimensions = {
    StorageType = "StandardStorage"
    BucketName  = var.s3_bucket_name
  }

  treat_missing_data = "notBreaching"
  period             = "600"
  statistic          = "Sum"
  threshold          = "20000000"
  alarm_description  = "This metric monitors s3 bucket size changes"

  alarm_actions = data.aws_sns_topic.sns_topic_monitor_error.*.arn
}

// -------------------
