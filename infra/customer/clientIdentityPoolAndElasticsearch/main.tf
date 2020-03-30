module "consts" {
  source = "../../../../utils/terraform/consts"
}

data "aws_caller_identity" "current" {}

locals {
  domain_name             = "bc-es-${var.customer_name}"
  cloudtrail_mapping_path = "./index_mapping/cloudtrail-index-mapping.json"
  lacework_mapping_path   = "./index_mapping/lacework-index-mapping.json"
  loggly_mapping_path     = "./index_mapping/loggly-index-mapping.json"
  identity_pool_name      = "IP_${var.customer_name}"
}

resource "aws_ssm_parameter" "app_client_id" {
  name      = "/bc_${var.customer_name}/app_client_id"
  type      = "String"
  value     = data.external.get_app_client_name.result.appClientID
  overwrite = true
}

data "external" "get_identity_pool_id" {
  program = ["bash", "-c", "npm i --quiet --no-progress -s --loglevel error  > /dev/null&&node identity_pool_cli.js getId ${local.identity_pool_name} --profile ${var.aws_profile} --region ${var.region}"]
  working_dir = "${path.module}/../../../../utils/nodeUtils/cognito"
}

// Create identity pool's un/authenticated policies and roles
data "aws_iam_policy_document" "authenticated_role_assume_policy" {
  statement {
    effect = "Allow"

    principals {
      identifiers = [
        "cognito-identity.amazonaws.com",
      ]

      type = "Federated"
    }

    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    condition {
      test = "StringEquals"

      values = [data.external.get_identity_pool_id.result.IdentityPoolId]

      variable = "cognito-identity.amazonaws.com:aud"
    }

    condition {
      test = "ForAnyValue:StringLike"

      values = [
        "authenticated",
      ]

      variable = "cognito-identity.amazonaws.com:amr"
    }
  }
}

resource "aws_iam_role" "authenticated_role" {
  name               = "Cognito_IP_${var.customer_name}_Auth_Role"
  assume_role_policy = data.aws_iam_policy_document.authenticated_role_assume_policy.json
}

data "aws_iam_policy_document" "unauthenticated_role_assume_policy" {
  statement {
    effect = "Allow"

    principals {
      identifiers = [
        "cognito-identity.amazonaws.com",
      ]

      type = "Federated"
    }

    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    condition {
      test = "StringEquals"

      values = [
        data.external.get_identity_pool_id.result.IdentityPoolId,
      ]

      variable = "cognito-identity.amazonaws.com:aud"
    }

    condition {
      test = "ForAnyValue:StringLike"

      values = [
        "unauthenticated",
      ]

      variable = "cognito-identity.amazonaws.com:amr"
    }
  }
}

resource "aws_iam_role" "unauthenticated_role" {
  name               = "Cognito_IP_${var.customer_name}_Unauth_Role"
  assume_role_policy = data.aws_iam_policy_document.unauthenticated_role_assume_policy.json
}

// Create cognito access role for ES
data "aws_iam_policy_document" "es_cognito_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "es:*",
    ]

    // ARN of the host that will be created here. It is constructed to avoid circular dependency
    resources = [
      "arn:aws:es:${var.region}:${data.aws_caller_identity.current.account_id}:domain/${local.domain_name}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "cognito-sync:*",
      "cognito-identity:*",
    ]

    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "es_cognito_access_assume_policy" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      identifiers = [
        "es.amazonaws.com",
      ]

      type = "Service"
    }
  }
}

data "aws_iam_policy_document" "es_access_policy_with_cognito" {
  statement {
    effect = "Allow"

    actions = [
      "es:*",
    ]

    principals {
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
        aws_iam_role.authenticated_role.arn,
        data.aws_caller_identity.current.account_id
      ]

      type = "AWS"
    }
  }
}


resource "aws_iam_role" "es_cognito_access_role" {
  name               = "bc_AmazonESCognitoAccessRole_${var.customer_name}"
  description        = "Allows ES to connect to Cognito"
  assume_role_policy = data.aws_iam_policy_document.es_cognito_access_assume_policy.json
}

resource "aws_iam_role_policy_attachment" "es_cognito_access_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonESCognitoAccess"
  role       = aws_iam_role.es_cognito_access_role.name
}

resource "aws_iam_role_policy" "es_cognito_policy" {
  policy = data.aws_iam_policy_document.es_cognito_policy_document.json
  role   = aws_iam_role.authenticated_role.name
}

resource "aws_cloudwatch_log_group" "es_log_group" {
  name = "/aws/aes/domains/bc-es-${var.customer_name}/application-logs"
}

// Creating an ES + Kibana host
resource "aws_elasticsearch_domain" "host" {
  domain_name           = local.domain_name
  elasticsearch_version = var.elasticsearch_version

  cluster_config {
    instance_type            = var.instance_type
    instance_count           = var.instance_count
    dedicated_master_enabled = var.master_enable
    dedicated_master_type    = var.master_type
    dedicated_master_count   = var.master_count
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.ebs_volume_size
  }

  snapshot_options {
    automated_snapshot_start_hour = var.snapshot_time_hour
  }

  cognito_options {
    enabled          = true
    identity_pool_id = data.external.get_identity_pool_id.result.IdentityPoolId
    role_arn         = aws_iam_role.es_cognito_access_role.arn
    user_pool_id     = var.user_pool_id
  }

  access_policies = data.aws_iam_policy_document.es_access_policy_with_cognito.json

  encrypt_at_rest {
    enabled = var.instance_type != "t2.small.elasticsearch" ? var.encrypt_at_rest_enabled : false
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.es_log_group.arn
    log_type                 = "ES_APPLICATION_LOGS"
  }

  depends_on = [
    null_resource.host_policy_delay,
    null_resource.update_cloudtrail_integrations_when_deleted // Required so after the ES host is destroyed, the update will be called again
  ]
}

// This resource is required to because sometimes, the Elsticsearch host is executed before the ES-Cognito policy is actually attached
// to the role.
resource "null_resource" "host_policy_delay" {
  triggers = {
    build = timestamp()
  }

  provisioner "local-exec" {
    command = "sleep 20"
  }

  depends_on = [aws_iam_role_policy_attachment.es_cognito_access_attachment]
}

resource "null_resource" "kibana_dashboard_resource" {
  triggers = {
    build_number = timestamp()
  }

  provisioner "local-exec" {
    working_dir = path.module
    command     = <<EOT
    pipenv install
pipenv run python ./../../../../utils/utilsPython/utilsPython/es/create_dynamic_template.py --domain_name ${aws_elasticsearch_domain.host.domain_name} --aws_profile ${var.aws_profile} --template_name bc-${var.customer_name}-cloudtrail-template --index_pattern *cloudtrail* --mapping ${local.cloudtrail_mapping_path} --index_type_name bc_${var.customer_name}_cloudtrail_index
pipenv run python ./../../../../utils/utilsPython/utilsPython/es/create_dynamic_template.py --domain_name ${aws_elasticsearch_domain.host.domain_name} --aws_profile ${var.aws_profile} --template_name bc-${var.customer_name}-lacework-template --index_pattern *lacework-events* --mapping ${local.lacework_mapping_path} --index_type_name bc_${var.customer_name}_lacework_index
pipenv run python ./../../../../utils/utilsPython/utilsPython/es/create_dynamic_template.py --domain_name ${aws_elasticsearch_domain.host.domain_name} --aws_profile ${var.aws_profile} --template_name bc-${var.customer_name}-loggly-template --index_pattern *loggly* --mapping ${local.loggly_mapping_path} --index_type_name bc_${var.customer_name}_loggly_index
pipenv run python ./kibana/import_dashboards.py --domain_name ${aws_elasticsearch_domain.host.domain_name} --aws_profile ${var.aws_profile} --region ${var.region}
EOT
  }

}

data "external" "get_app_client_name" {
  program = ["bash", "-c", "aws cognito-idp list-user-pool-clients --region ${var.region} --profile ${var.aws_profile} --user-pool-id \"${var.user_pool_id}\" --output json | jq -r .UserPoolClients | jq 'map({Id: .ClientId,Name: .ClientName}) | map(select(.Name | contains(\"AWSElasticsearch-${local.domain_name}-${var.region}\"))) | .[-1].Id | {\"appClientID\":.}'"]

  depends_on = [
    "aws_elasticsearch_domain.host",
  ]
}

locals {
  providerName = "cognito-idp.${var.region}.amazonaws.com/${var.user_pool_id}"
  roleMapping = {
    "Type" = "Rules",
    "AmbiguousRoleResolution" = "Deny",
    "RulesConfiguration" = {
      "Rules" = [
        {
          Claim =  "custom:org",
          MatchType = "Contains",
          Value = var.customer_name,
          RoleARN = aws_iam_role.authenticated_role.arn
        }
      ]
    }
  }
}

resource "null_resource" "attach_app_client_id" {
  provisioner "local-exec" {
    working_dir = "${path.module}/../../../../utils/nodeUtils/cognito"
    command = "npm i --quiet --no-progress -s --loglevel error  > /dev/null&&node identity_pool_cli.js updateCognitoProvider ${local.identity_pool_name} --providerName ${local.providerName} --clientId ${data.external.get_app_client_name.result.appClientID} --serverSideTokenCheck false --profile ${var.aws_profile} --region ${var.region} --roleMapping '${jsonencode(local.roleMapping)}'"
  }

  depends_on = [
    data.external.get_app_client_name,
  ]
}

resource "null_resource" "add_google_scope" {
  provisioner "local-exec" {
    working_dir = "${path.module}/../../../../utils/nodeUtils/cognito"
    command = "npm i --quiet --no-progress -s --loglevel error  > /dev/null&&node user_pool_cli.js addScope ${module.consts.google_provider_name} ${data.external.get_app_client_name.result.appClientID} --userPoolID ${var.user_pool_id} --profile ${var.aws_profile} --region ${var.region}"
  }

  depends_on = [
    null_resource.attach_app_client_id
  ]
}

resource "null_resource" "add_github_scope" {
  provisioner "local-exec" {
    working_dir = "${path.module}/../../../../utils/nodeUtils/cognito"
    command = "npm i --quiet --no-progress -s --loglevel error  > /dev/null&&node user_pool_cli.js addScope ${module.consts.openid_provider_name} ${data.external.get_app_client_name.result.appClientID} --userPoolID ${var.user_pool_id} --profile ${var.aws_profile} --region ${var.region}"
  }

  depends_on = [
    null_resource.add_google_scope
  ]
}

// ------ Monitor ------
// Recommended CloudWatch Alarms
// https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/cloudwatch-alarms.html

data "aws_sns_topic" "topic_monitor_error" {
  count = var.monitor["enable"] ? 1 : 0
  name  = var.monitor["sns_topic_error_name"]
}

resource "aws_cloudwatch_metric_alarm" "elasticsearch_cluster_status_red" {
  count               = var.monitor["enable"] ? 1 : 0
  alarm_name          = "bc_elasticsearch_cluster_status_red_${var.customer_name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ClusterStatus.red"
  namespace           = "AWS/ES"

  dimensions = {
    DomainName = local.domain_name
    ClientId   = data.aws_caller_identity.current.account_id
  }

  period            = "60"
  statistic         = "Maximum"
  threshold         = "1"
  alarm_description = "At least one primary shard and its replicas are not allocated to a node"

  alarm_actions = data.aws_sns_topic.topic_monitor_error.*.arn
}

resource "aws_cloudwatch_metric_alarm" "elasticsearch_free_storage_space" {
  count               = var.monitor["enable"] ? 1 : 0
  alarm_name          = "bc_elasticsearch_free_storage_space_${var.customer_name}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/ES"

  dimensions = {
    DomainName = local.domain_name
    ClientId   = data.aws_caller_identity.current.account_id
  }

  period            = "60"
  statistic         = "Minimum"
  threshold         = var.instance_type != "t2.small.elasticsearch" ? "20480" : "6000"
  alarm_description = "A node in your cluster is down to ${var.instance_type != "t2.small.elasticsearch" ? "20" : "6"} GiB of free storage space"

  alarm_actions = data.aws_sns_topic.topic_monitor_error.*.arn
}

resource "aws_cloudwatch_metric_alarm" "elasticsearch_cluster_index_write_blocked" {
  count               = var.monitor["enable"] ? 1 : 0
  alarm_name          = "bc_elasticsearch_cluster_index_write_blocked_${var.customer_name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ClusterIndexWritesBlocked"
  namespace           = "AWS/ES"

  dimensions = {
    DomainName = local.domain_name
    ClientId   = data.aws_caller_identity.current.account_id
  }

  period            = "300"
  statistic         = "Sum"
  threshold         = "1"
  alarm_description = "Your cluster is blocking write request"

  alarm_actions = data.aws_sns_topic.topic_monitor_error.*.arn
}

resource "aws_cloudwatch_metric_alarm" "elasticsearch_automated_snapshot_failure" {
  count               = var.monitor["enable"] ? 1 : 0
  alarm_name          = "bc_elasticsearch_automated_snapshot_failure_${var.customer_name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "AutomatedSnapshotFailure"
  namespace           = "AWS/ES"

  dimensions = {
    DomainName = local.domain_name
    ClientId   = data.aws_caller_identity.current.account_id
  }

  treat_missing_data = "notBreaching"
  period             = "60"
  statistic          = "Maximum"
  threshold          = "1"
  alarm_description  = "An automated snapshot failed"

  alarm_actions = data.aws_sns_topic.topic_monitor_error.*.arn
}

resource "aws_cloudwatch_metric_alarm" "elasticsearch_cpu_utilization" {
  count               = var.monitor["enable"] ? 1 : 0
  alarm_name          = "bc_elasticsearch_cpu_utilization_${var.customer_name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ES"

  dimensions = {
    DomainName = local.domain_name
    ClientId   = data.aws_caller_identity.current.account_id
  }

  period            = "900"
  statistic         = "Average"
  threshold         = "80"
  alarm_description = "100% CPU utilization isn't uncommon"

  alarm_actions = data.aws_sns_topic.topic_monitor_error.*.arn
}

resource "aws_cloudwatch_metric_alarm" "elasticsearch_jvm_memory_pressure" {
  count               = var.monitor["enable"] ? 1 : 0
  alarm_name          = "bc_elasticsearch_jvm_memory_pressure_${var.customer_name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "JVMMemoryPressure"
  namespace           = "AWS/ES"

  dimensions = {
    DomainName = local.domain_name
    ClientId   = data.aws_caller_identity.current.account_id
  }

  period            = "900"
  statistic         = "Maximum"
  threshold         = "80"
  alarm_description = "The cluster could encounter out of memory errors if usage increases"

  alarm_actions = data.aws_sns_topic.topic_monitor_error.*.arn
}

resource "aws_cloudwatch_log_metric_filter" "elasticsearch_log_metric_filter" {
  count          = var.monitor["enable"] ? 1 : 0
  name           = "bc_elasticsearch_log_metric_filter_${var.customer_name}"
  pattern        = "[ERROR]"
  log_group_name = aws_cloudwatch_log_group.es_log_group.name

  metric_transformation {
    name      = "bc_Errors_${var.customer_name}"
    namespace = "bridgecrew/ES"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "elasticsearch_log_metric_error" {
  count               = var.monitor["enable"] ? 1 : 0
  alarm_name          = "bc_elasticsearch_log_metric_error_${var.customer_name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors_${var.customer_name}"
  namespace           = "bridgecrew/ES"

  treat_missing_data = "notBreaching"
  period             = "60"
  statistic          = "Maximum"
  threshold          = "1"
  alarm_description  = "Elasticsearch logs error"

  alarm_actions = data.aws_sns_topic.topic_monitor_error.*.arn
}
