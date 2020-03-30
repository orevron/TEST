data "aws_caller_identity" "current" {}

module "consts" {
  source = "../../../../utils/terraform/consts"
}

locals {
  bucket_name = "bridgecrew-app-${data.aws_caller_identity.current.account_id}${var.unique_tag}"

  # bucket_name  = "bridgecrew-app"
  s3_origin_id   = "S3-Website-${aws_s3_bucket.app_bucket.bucket_regional_domain_name}${var.unique_tag}"
  route53_domain = "https://${var.api_subdomain}.${var.domain}"
  api_domain     = var.turbo_mode ? var.domain : local.route53_domain

  # Setting the tag manager id only if we are in production mode
  tm_id_param    = (var.aws_profile == "prod") ? "--env.GOOGLE_TAG_MANAGER_ID ${module.consts.tag_manager_id}" : ""
}

resource "aws_s3_bucket" "app_bucket" {
  bucket        = local.bucket_name
  policy        = data.aws_iam_policy_document.bucket_policy.json
  force_destroy = "true"

  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}/*",
    ]

    principals {
      identifiers = [
        "*",
      ]

      type = "*"
    }
  }
}

resource "local_file" "npmrc" {
  content     = "//registry.npmjs.org/:_authToken=${var.app_npm_token}"
  filename = "${var.path_to_origin_folder}/.npmrc"
}

data "external" "hash" {
  program = ["node", "index.js", "${abspath(path.root)}/${var.path_to_origin_folder}"]
  working_dir = "../../../devTools/hash-dir"
}

resource "null_resource" "build_app" {
  triggers = {
    build = data.external.hash.result.hash
  }

  provisioner "local-exec" {
    // Setting CI=false in the build command to avoid failing on warnings - https://github.com/facebook/create-react-app/issues/3657
    command = "cd ${var.path_to_origin_folder} && npm i && npm run build -- --env.REGION ${var.region} --env.DOMAIN ${local.api_domain} --env.USER_POOL_ID ${var.user_pool_id} --env.GOOGLE_ANALYTICS_KEY ${var.google_analytics_key} --env.GITHUB_APP_ID ${var.github_app_id} --env.COGNITO_DOMAIN ${var.cognito_user_pool_domain} --env.SCANNERS_RESULT_BUCKET ${var.scanners_results_bucket} ${local.tm_id_param} --CI false"
  }

  depends_on = [
    "local_file.npmrc"
  ]
}

resource "null_resource" "sync_folder_to_bucket" {
  triggers = {
    build = data.external.hash.result.hash
  }

  provisioner "local-exec" {
    command = "aws --profile ${var.aws_profile} s3 sync ${var.path_to_origin_folder}dist/ s3://${aws_s3_bucket.app_bucket.bucket} --delete"
  }

  depends_on = [
    "null_resource.build_app",
  ]
}

locals {
  apistage = substr(var.api_gateway_invoke_url, 8, length(var.api_gateway_invoke_url) - 8)
}

resource "aws_cloudfront_distribution" "distribution" {
  count = var.turbo_mode ? 0 : 1

  origin {
    domain_name = aws_s3_bucket.app_bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
    origin_path = ""
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "bridge crew site distribution"
  default_root_object = "index.html"

  aliases = [
    "www.${var.domain}",
  ]

  origin {
    domain_name = split("/", local.apistage)[0]
    origin_id   = "apigateway"
    origin_path = "/v1"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.cert_arn
    minimum_protocol_version = "TLSv1"
    ssl_support_method       = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    allowed_methods = [
      "DELETE",
      "GET",
      "HEAD",
      "OPTIONS",
      "PATCH",
      "POST",
      "PUT",
    ]

    cached_methods = [
      "GET",
      "HEAD",
    ]

    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["GET", "PUT", "POST", "PATCH", "DELETE", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "apigateway"

    forwarded_values {
      query_string = true
      headers      = ["Accept", "Authorization", "Content-Type", "Origin", "Referer"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 10
    max_ttl                = 10
    compress               = true
    viewer_protocol_policy = "https-only"
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 5
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 5
  }
}

locals {
  distribution_id = element(concat(aws_cloudfront_distribution.distribution.*.id, list("")), 0)
}

resource "null_resource" "invalidate_cloudfront_cache" {
  count = var.turbo_mode ? 0 : 1

  triggers = {
    build = timestamp()
  }

  provisioner "local-exec" {
    command = "aws --profile ${var.aws_profile} cloudfront create-invalidation --distribution-id ${local.distribution_id} --paths '/*'"
  }

  depends_on = [
    "null_resource.sync_folder_to_bucket",
  ]
}

// ------ Monitor ------

data "aws_sns_topic" "topic_monitor_error" {
  count = var.monitor["enable"] ? 1 : 0
  name  = var.monitor["sns_topic_error_name"]
}

resource "aws_cloudwatch_metric_alarm" "app-s3-bucket-size-change" {
  count               = var.monitor["enable"] ? 1 : 0
  alarm_name          = "app-s3-bucket-size-change-${local.bucket_name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"

  dimensions = {
    StorageType = "StandardStorage"
    BucketName  = local.bucket_name
  }

  treat_missing_data = "notBreaching"
  period             = "600"
  statistic          = "Sum"
  threshold          = "20000000"
  alarm_description  = "This metric monitors s3 bucket size changes"

  alarm_actions = data.aws_sns_topic.topic_monitor_error.*.arn
}
