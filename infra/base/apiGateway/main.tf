module "consts" {
  source = "../../../../utils/terraform/consts"
}

// ------ Monitor ------
data "aws_sns_topic" "sns_topic_monitor_error" {
  count = var.monitor["enable"] ? 1 : 0
  name  = var.monitor["sns_topic_error_name"]
}

resource "aws_cloudwatch_metric_alarm" "create_alarm_error_5XX" {
  count               = var.monitor["enable"] ? 1 : 0
  alarm_name          = "api_gateway_5XX_errors_alarm${var.unique_tag}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"

  dimensions = {
    Stage   = var.stage
    ApiName = aws_api_gateway_rest_api.swagger_api.name
  }

  period            = "3600"
  statistic         = "Sum"
  threshold         = "1"
  alarm_description = "This metric monitors api gateway 5XX errors"

  alarm_actions = data.aws_sns_topic.sns_topic_monitor_error.*.arn
}

resource "aws_cloudwatch_metric_alarm" "create_alarm_error_4XX" {
  count               = var.monitor["enable"] ? 1 : 0
  alarm_name          = "api_gateway_4XX_errors_alarm${var.unique_tag}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"

  dimensions = {
    Stage   = var.stage
    ApiName = aws_api_gateway_rest_api.swagger_api.name
  }

  period            = "86400"
  statistic         = "Sum"
  threshold         = "10"
  alarm_description = "This metric monitors api gateway 4XX errors"

  alarm_actions = data.aws_sns_topic.sns_topic_monitor_error.*.arn
}

#
# handle jira
#


data "aws_lambda_function" "jira_lambda" {
  count         = length(var.jira_function_names)
  function_name = var.jira_function_names[count.index]
}

resource "aws_lambda_permission" "jiraConf_lambda_permissions" {
  count         = length(var.jira_function_names)
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.jira_lambda.*.function_name[count.index]
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.swagger_api.execution_arn}/*"
}

#
# handle integrations
#

data "aws_lambda_function" "integrations_lambda" {
  count         = length(var.integrations_handler_function_name)
  function_name = var.integrations_handler_function_name[count.index]
}

resource "aws_lambda_permission" "integrations_lambda_permissions" {
  count         = length(var.integrations_handler_function_name)
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.integrations_lambda.*.function_name[count.index]
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.swagger_api.execution_arn}/*"
}

#
# handle cloudmapper api
#

data "aws_lambda_function" "cloudmapper_lambda" {
  count         = length(var.cloudmapper_api_function_name)
  function_name = var.cloudmapper_api_function_name[count.index]
}

resource "aws_lambda_permission" "cloudmapper_lambda_permissions" {
  count         = length(var.cloudmapper_api_function_name)
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.cloudmapper_lambda.*.function_name[count.index]
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.swagger_api.execution_arn}/*"
}
#
# handle snapshots api
#

data "aws_lambda_function" "snapshots_lambda" {
  count         = length(var.snapshots_api_function_name)
  function_name = var.snapshots_api_function_name[count.index]
}

resource "aws_lambda_permission" "snapshots_lambda_permissions" {
  count         = length(var.snapshots_api_function_name)
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.snapshots_lambda.*.function_name[count.index]
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.swagger_api.execution_arn}/*"
}


#
# Create the custom authorizer lambda
#
data "aws_lambda_function" "authorization_lambdas" {
  count         = length(var.authorization_functions_names)
  function_name = var.authorization_functions_names[count.index]
}

resource "aws_lambda_permission" "authorization_lambdas_permissions" {
  count         = length(var.authorization_functions_names)
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.authorization_lambdas.*.function_name[count.index]
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.swagger_api.execution_arn}/*"
}

#
# handle logstash
#

data "aws_lambda_function" "logstash_lambda" {
  count         = length(var.logstash_function_name)
  function_name = var.logstash_function_name[count.index]
}

data "local_file" "swagger_file" {
  filename = var.swagger_file_path
}

locals {
  api_name               = var.unique_tag == "" ? module.consts.api_name : "${module.consts.api_name}${var.unique_tag}"
  swagger_with_title     = replace(data.local_file.swagger_file.content, "api_title", local.api_name)
  swagger_with_user_pool = replace(local.swagger_with_title, "user_pool_arn", var.user_pool_arn)
  controller_arn         = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${concat(var.remediation_function_arns, list(""))[0]}/invocations"
  remote_arn             = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${concat(var.remediation_function_arns, list("", ""))[1]}/invocations"
  violations_api_arn     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${concat(data.aws_lambda_function.violations_api_lambda.*.arn, list(""))[0]}/invocations"
  suppressions_api_arn   = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${concat(data.aws_lambda_function.violations_api_lambda.*.arn, list("", ""))[1]}/invocations"
  guardrail_api_arn      = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${concat(data.aws_lambda_function.violations_api_lambda.*.arn, list("", "", ""))[2]}/invocations"
  integrations_arn       = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${concat(data.aws_lambda_function.integrations_lambda.*.arn, list(""))[0]}/invocations"
  jira_conf_arn          = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${concat(data.aws_lambda_function.jira_lambda.*.arn, list(""))[0]}/invocations"
  logstash_producer_arn  = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${concat(data.aws_lambda_function.logstash_lambda.*.arn, list(""))[0]}/invocations"
  customer_info_api_arn  = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${concat(data.aws_lambda_function.customer_info_api_lambda.*.arn, list(""))[0]}/invocations"
  cloudmapper_api_arn    = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${concat(data.aws_lambda_function.cloudmapper_lambda.*.arn, list(""))[0]}/invocations"
  snapshots_api_arn      = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${concat(data.aws_lambda_function.snapshots_lambda.*.arn, list(""))[0]}/invocations"
  authorizer_lambda_uri  = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${concat(data.aws_lambda_function.authorization_lambdas.*.arn, list(""))[0]}/invocations"
  github_lambda_arn      = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${concat(data.aws_lambda_function.github_api_lambdas.*.arn, list(""))[0]}/invocations"
  github_webhook_arn     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${concat(data.aws_lambda_function.github_api_lambdas.*.arn, list("",""))[1]}/invocations"
  tokens_api_arn         = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${concat(data.aws_lambda_function.authorization_lambdas.*.arn, list("", ""))[1]}/invocations"
  github_openid_wrapper  = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${concat(data.aws_lambda_function.authorization_lambdas.*.arn, list("","",""))[2]}/invocations"
  sso_manager_arn        = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${concat(data.aws_lambda_function.authorization_lambdas.*.arn, list("","","","",""))[4]}/invocations"
  benchmarks_api_arn     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${concat(data.aws_lambda_function.benchmarks_api_lambdas.*.arn, list("", ""))[0]}/invocations"

  swagger_with_controller_arn         = replace(local.swagger_with_user_pool, "remediation_controller_arn", local.controller_arn)
  swagger_with_remote_remediation_arn = replace(local.swagger_with_controller_arn, "remote_remediation_arn", local.remote_arn)
  swagger_with_violation_api_arn      = replace(local.swagger_with_remote_remediation_arn, "violation_api_arn", local.violations_api_arn)
  swagger_with_suppression_api_arn    = replace(local.swagger_with_violation_api_arn, "suppression_api_arn", local.suppressions_api_arn)
  swagger_with_guardrail_api_arn      = replace(local.swagger_with_suppression_api_arn, "guardrail_api_arn", local.guardrail_api_arn)
  swagger_with_integrations_arn       = replace(local.swagger_with_guardrail_api_arn, "integrations_arn", local.integrations_arn)
  swagger_with_jira_conf_arn          = replace(local.swagger_with_integrations_arn, "jira_integration_arn", local.jira_conf_arn)
  swagger_with_customer_api_arn       = replace(local.swagger_with_jira_conf_arn, "customer_info_api_arn", local.customer_info_api_arn)
  swagger_with_logstash_arn           = replace(local.swagger_with_customer_api_arn, "logstash_producer_arn", local.logstash_producer_arn)
  swagger_with_cloudmapper_arn        = replace(local.swagger_with_logstash_arn, "cloudmapper_arn", local.cloudmapper_api_arn)
  swagger_with_snapshots_api_arn      = replace(local.swagger_with_cloudmapper_arn, "snapshots_api_arn", local.snapshots_api_arn)
  swagger_with_authorizer_lambda_uri  = replace(local.swagger_with_snapshots_api_arn, "authorizer_lambda_uri", local.authorizer_lambda_uri)
  swagger_with_tokens_api_arn         = replace(local.swagger_with_authorizer_lambda_uri, "tokens_api_arn", local.tokens_api_arn)
  swagger_with_github_openid_wrapper  = replace(local.swagger_with_tokens_api_arn, "github_openid_wrapper", local.github_openid_wrapper)
  swagger_with_github_api_arn         = replace(local.swagger_with_github_openid_wrapper, "github_api_arn", local.github_lambda_arn)
  swagger_with_benchmarks_api_arn     = replace(local.swagger_with_github_api_arn, "benchmarks_api_arn", local.benchmarks_api_arn)
  swagger_with_sso_manager_arn        = replace(local.swagger_with_benchmarks_api_arn, "sso_manager_arn", local.sso_manager_arn)
  swagger_with_github_webhook_arn     = replace(local.swagger_with_sso_manager_arn, "github_webhook_arn", local.github_webhook_arn)
}

resource "aws_api_gateway_rest_api" "swagger_api" {
  name        = local.api_name
  description = "Description"
  body        = local.swagger_with_github_webhook_arn
}

data "aws_arn" "remediation_arns" {
  count = length(var.remediation_function_arns)
  arn   = var.remediation_function_arns[count.index]
}

data "aws_lambda_function" "remediation_lambdas" {
  count         = length(var.remediation_function_arns)
  function_name = data.aws_arn.remediation_arns[count.index].resource
}

resource "aws_lambda_permission" "remediation_lambda_permissions" {
  count         = length(var.remediation_function_arns)
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.remediation_lambdas[count.index].function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.swagger_api.execution_arn}/*"
}

data "aws_lambda_function" "handle_logstash_lambdas" {
  count         = length(var.logstash_function_name)
  function_name = var.logstash_function_name[count.index]
}

resource "aws_lambda_permission" "handle_logstash_lambda_permissions" {
  count         = length(var.logstash_function_name)
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.handle_logstash_lambdas[count.index].function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.swagger_api.execution_arn}/*"
}

// ------- violations api ----------
data "aws_lambda_function" "violations_api_lambda" {
  count         = length(var.violations_function_names)
  function_name = var.violations_function_names[count.index]
}

resource "aws_lambda_permission" "violation_api_lambda_permissions" {
  count         = length(var.violations_function_names)
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.violations_api_lambda[count.index].function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.swagger_api.execution_arn}/*"
}


// ------- customers api ----------
data "aws_lambda_function" "customer_info_api_lambda" {
  count         = length(var.customers_function_names)
  function_name = var.customers_function_names[count.index]
}

resource "aws_lambda_permission" "customer_info_api_lambda_permissions" {
  count         = length(var.customers_function_names)
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.customer_info_api_lambda[count.index].function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.swagger_api.execution_arn}/*"
}

// ----------- Github api -------------
data aws_lambda_function "github_api_lambdas" {
  count         = length(var.github_api_function_name)
  function_name = var.github_api_function_name[count.index]
}

resource "aws_lambda_permission" "github_api_lambda_permissions" {
  count         = length(var.github_api_function_name)
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.github_api_lambdas[count.index].function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.swagger_api.execution_arn}/*"
}

//-------------- Benchmarks api -----------------
data aws_lambda_function "benchmarks_api_lambdas" {
  count         = length(var.benchmarks_function_names)
  function_name = var.benchmarks_function_names[count.index]
}

resource "aws_lambda_permission" "benchmarks_api_lambdas_permissions" {
  count         = length(var.benchmarks_function_names)
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.benchmarks_api_lambdas[count.index].function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.swagger_api.execution_arn}/*"
}