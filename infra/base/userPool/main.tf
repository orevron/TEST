resource "random_uuid" "random_external_uuid" {}

module "consts" {
  source = "../../../../utils/terraform/consts"
}


resource "aws_iam_role" "cidp" {
  name = "${var.user_pool_name}_SMS_Role${var.unique_tag}"
  path = "/service-role/"

  assume_role_policy = data.aws_iam_policy_document.cidp_assume_role_policy_document.json
}

data "aws_iam_policy_document" "cidp_assume_role_policy_document" {
  statement {
    effect = "Allow"

    principals {
      identifiers = [
        "cognito-idp.amazonaws.com",
      ]

      type = "Service"
    }

    actions = [
      "sts:AssumeRole",
    ]

    condition {
      test = "StringEquals"

      values = [
        random_uuid.random_external_uuid.result,
      ]

      variable = "sts:ExternalId"
    }
  }
}

resource "aws_iam_role_policy" "cognito_sms_policy" {
  name = "${var.user_pool_name}-SMS-Policy${var.unique_tag}"
  role = aws_iam_role.cidp.id

  policy = data.aws_iam_policy_document.cognito_sms_policy_document.json
}

data "aws_iam_policy_document" "cognito_sms_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "sns:publish",
    ]

    resources = [
      "*",
    ]
  }
}

// This will throw an error in case the BridgeCrew support email doesn't exist, and will stop the customer stack creation
// Need to create it manually according to the readme of the base stack
data "aws_ssm_parameter" "support_email_arn" {
  name = "/base_stack/ses_support_arn"
}

data "aws_caller_identity" "current" {}

resource "aws_cognito_user_pool" "pool" {
  name                     = "${var.user_pool_name}${var.unique_tag}"
  mfa_configuration        = var.mfa_configuration
  auto_verified_attributes = var.auto_verified_attributes

  user_pool_add_ons {
    advanced_security_mode = var.advanced_security_mode
  }

  email_configuration {
    reply_to_email_address = var.support_email
    source_arn             = data.aws_ssm_parameter.support_email_arn.value
  }

  device_configuration {
    device_only_remembered_on_user_prompt = true
  }

  sms_configuration {
    external_id    = random_uuid.random_external_uuid.result
    sns_caller_arn = aws_iam_role.cidp.arn
  }

  admin_create_user_config {
    allow_admin_create_user_only = "true"
    unused_account_validity_days = 0

    invite_message_template {
      email_message = var.email_message
      email_subject = var.email_subject
      sms_message   = var.sms_message
    }
  }

  password_policy {
    minimum_length    = var.minimum_length
    require_lowercase = var.require_lowercase
    require_numbers   = var.require_numbers
    require_symbols   = var.require_symbols
    require_uppercase = var.require_uppercase
  }

  email_verification_subject = var.email_verification_subject
  email_verification_message = var.email_verification_message
  sms_verification_message   = var.sms_verification_message
  sms_authentication_message = var.sms_authentication_message

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "email"
    required                 = true

    string_attribute_constraints {
      min_length = 7
      max_length = 1024
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "tier"
    required                 = false

    string_attribute_constraints {
      min_length = 7
      max_length = 256
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "json_data"
    required                 = false

    string_attribute_constraints {
      min_length = 7
      max_length = 1024
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "org"
    required                 = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "name"
    required                 = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "family_name"
    required                 = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "phone_number"
    required                 = false

    string_attribute_constraints {
      min_length = 6
      max_length = 256
    }
  }

  lambda_config {
    pre_sign_up = "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:bc-authorization-cognito-presignup${var.unique_tag}"
  }

  depends_on = [
    "null_resource.pool_policy_delay",
  ]
}

resource "aws_cognito_identity_provider" "google_provider" {
  user_pool_id  = aws_cognito_user_pool.pool.id
  provider_name = module.consts.google_provider_name
  provider_type = module.consts.google_provider_name

  provider_details = {
    authorize_scopes = var.google_authorize_scopes
    client_id        = var.google_oauth_client_id
    client_secret    = var.google_oauth_client_secret
  }

  attribute_mapping = {
    email          = "email"
    username       = "sub"
    birthdate      = "birthdays"
    gender         = "genders"
    family_name    = "family_name"
    given_name     = "given_name"
    picture        = "picture"
    name           = "name"
    email_verified = "email_verified"
    name           = "name"
  }
}

// This resource is required to because sometimes, the user pool is executed before the SMS policy is actually attached
// to the cidp role.
resource "null_resource" "pool_policy_delay" {
  triggers = {
    build = timestamp()
  }

  provisioner "local-exec" {
    command = "sleep 10"
  }

  depends_on = ["aws_iam_role_policy.cognito_sms_policy"]
}

// In case of turbo mode we shouldn't create domain with certificate arn
resource "aws_cognito_user_pool_domain" "cognito_domain" {
  count           = var.turbo_mode ? 0 : 1
  domain          = "${var.subdomain}.${var.domain}"
  certificate_arn = var.certificate_arn
  user_pool_id    = aws_cognito_user_pool.pool.id
}

resource "aws_cognito_user_pool_domain" "cognito_aws_generated_domain" {
  count        = var.turbo_mode ? 1 : 0
  domain       = "${var.subdomain}-${var.domain}"
  user_pool_id = aws_cognito_user_pool.pool.id
}

locals {
  cognito_route53_domain               = concat(aws_cognito_user_pool_domain.cognito_domain.*.domain, list(""))[0]
  cognito_aws_generated_domain         = "${element(concat(aws_cognito_user_pool_domain.cognito_aws_generated_domain.*.domain, list("")), 0)}.auth.${var.region}.amazoncognito.com"
  cognito_route53_domain_cf_dist       = concat(aws_cognito_user_pool_domain.cognito_domain.*.cloudfront_distribution_arn, list(""))[0]
  cognito_aws_generated_domain_cf_dist = concat(aws_cognito_user_pool_domain.cognito_aws_generated_domain.*.cloudfront_distribution_arn, list(""))[0]
}

resource "null_resource" "setup_logo" {
  triggers = {
    build_number = filebase64sha256(var.path_to_logo)
  }

  provisioner "local-exec" {
    command = "aws --region ${var.region} --profile ${var.aws_profile} cognito-idp set-ui-customization --user-pool-id ${aws_cognito_user_pool.pool.id} --image-file fileb://${var.path_to_logo}"
  }

  depends_on = ["aws_cognito_user_pool_domain.cognito_aws_generated_domain", "aws_cognito_user_pool_domain.cognito_domain"]
}

resource "null_resource" "create_openid_wrapper_to_github_oath" {
  triggers = {
    build = timestamp()
  }

  provisioner "local-exec" {
    command = <<BASH
#!/usr/bin/env bash

provider_details='{"client_id":"${var.github_oauth_client_id}","authorize_scopes":"${var.authorize_scopes}","attributes_request_method":"${var.attributes_request_method}","oidc_issuer":"${split("/v1",var.oidc_issuer)[0]}","authorize_url":"${var.oidc_issuer}/authorize","token_url":"${var.oidc_issuer}/token","attributes_url":"${var.oidc_issuer}/userinfo","jwks_uri":"${var.oidc_issuer}/.well-known/jwks.json"}'
attribute_mapping='{"website":"website","email_verified":"email_verified","updated_at":"updated_at","profile":"profile","name":"name","email":"email","picture":"picture","username":"sub" }'

echo aws cognito-idp create-identity-provider --user-pool-id ${aws_cognito_user_pool.pool.id} --provider-name ${module.consts.openid_provider_name} --provider-type OIDC --provider-details "'"$provider_details"'" --attribute-mapping "'"$attribute_mapping"'" --profile=${var.aws_profile} --region ${var.region} | sh || true

BASH
  }
}

resource "aws_cognito_user_pool_client" "app_client" {
  name                = "app_users_client"
  user_pool_id        = aws_cognito_user_pool.pool.id
  generate_secret     = false
  explicit_auth_flows = ["ADMIN_NO_SRP_AUTH"]

  allowed_oauth_flows_user_pool_client=true
  supported_identity_providers=[module.consts.google_provider_name, module.consts.openid_provider_name]
  callback_urls=[(var.aws_profile == "prod" || var.aws_profile == "stage") ? "https://www.${var.domain}/callback" : "http://localhost:8080/callback"]
  logout_urls=[(var.aws_profile == "prod" || var.aws_profile == "stage") ? "https://www.${var.domain}" : "http://localhost:8080"]
  allowed_oauth_flows=["implicit"]
  allowed_oauth_scopes=["phone", "email", "openid", "profile", "aws.cognito.signin.user.admin"]

  depends_on = [null_resource.create_openid_wrapper_to_github_oath, aws_cognito_identity_provider.google_provider]
}
