locals {
  provider_host = trimprefix(var.provider_url, "https://")
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid    = "AllowGitHubActionsOidc"
    effect = "Allow"

    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.provider_host}:aud"
      values   = var.allowed_audiences
    }

    condition {
      test     = "StringLike"
      variable = "${local.provider_host}:sub"
      values   = var.allowed_subjects
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = var.role_name
  description          = var.role_description
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  max_session_duration = var.max_session_duration
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  for_each = var.inline_policy_jsons

  name   = each.key
  role   = aws_iam_role.this.id
  policy = each.value
}
