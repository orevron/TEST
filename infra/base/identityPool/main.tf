resource "aws_iam_role" "authenticated_role" {
  name = "app_users_authenticated${var.unique_tag}"

  assume_role_policy = data.aws_iam_policy_document.authenticated_policy.json
}

data "aws_iam_policy_document" "authenticated_policy" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["cognito-identity.amazonaws.com"]
      type        = "Federated"
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "ForAnyValue:StringLike"
      values   = ["authenticated"]
      variable = "cognito-identity.amazonaws.com:amr"
    }
  }
}

resource "aws_iam_role_policy" "authenticated" {
  name = "app_useres_authenticated_policy${var.unique_tag}"
  role = aws_iam_role.authenticated_role.id

  policy = data.aws_iam_policy_document.authenticate_policy_document.json
}

data "aws_iam_policy_document" "authenticate_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "mobileanalytics:PutEvents",
      "cognito-sync:*",
      "cognito-identity:*",
    ]

    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["execute-api:Invoke"]
    resources = ["arn:aws:execute-api:${var.region}:*:${var.api_gateway_id}/*/*/*"]
  }
}