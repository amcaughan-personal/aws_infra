data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  accepted_cleanup_tag_names = distinct(concat([var.cleanup_tag_name], var.accepted_cleanup_tag_names))
  ec2_resource_arns = [
    "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:instance/*",
    "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:security-group/*",
    "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:vpc-endpoint/*",
  ]
  ecs_task_resource_arns = [
    "arn:${data.aws_partition.current.partition}:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:task/*",
    "arn:${data.aws_partition.current.partition}:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:task/*/*",
  ]
  log_resource_arns = [
    "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.function_name}",
    "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.function_name}:*",
  ]
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda" {
  statement {
    sid    = "TaggingDiscovery"
    effect = "Allow"
    actions = [
      "tag:GetResources",
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = local.accepted_cleanup_tag_names
    content {
      sid    = "CleanupEc2Resources${replace(replace(replace(title(statement.value), "_", ""), "-", ""), " ", "")}"
      effect = "Allow"
      actions = [
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteVpcEndpoints",
        "ec2:TerminateInstances",
      ]
      resources = local.ec2_resource_arns

      condition {
        test     = "StringEquals"
        variable = "aws:ResourceTag/${statement.value}"
        values   = ["true"]
      }
    }
  }

  dynamic "statement" {
    for_each = local.accepted_cleanup_tag_names
    content {
      sid    = "CleanupEcsTasks${replace(replace(replace(title(statement.value), "_", ""), "-", ""), " ", "")}"
      effect = "Allow"
      actions = [
        "ecs:StopTask",
      ]
      resources = local.ecs_task_resource_arns

      condition {
        test     = "StringEquals"
        variable = "aws:ResourceTag/${statement.value}"
        values   = ["true"]
      }
    }
  }

  statement {
    sid    = "DescribeEc2State"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcEndpoints",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DescribeEcsState"
    effect = "Allow"
    actions = [
      "ecs:DescribeTasks",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "WriteLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = local.log_resource_arns
  }

  statement {
    sid    = "SendToDLQ"
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
    ]
    resources = [aws_sqs_queue.dlq.arn]
  }
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.function_name}-policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_sqs_queue" "dlq" {
  name              = "${var.function_name}-dlq"
  kms_master_key_id = "alias/aws/sqs"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda.zip"

  source {
    content = templatefile("${path.module}/lambda.py.tftpl", {
      accepted_cleanup_tag_names = jsonencode(local.accepted_cleanup_tag_names)
      cleanup_schedule_tag_name  = var.cleanup_schedule_tag_name
      cleanup_tag_name           = var.cleanup_tag_name
      created_on_tag_name        = var.created_on_tag_name
      monthly_cleanup_day        = var.monthly_cleanup_day
      weekly_cleanup_weekday     = var.weekly_cleanup_weekday
    })
    filename = "lambda.py"
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = aws_iam_role.this.arn
  handler       = "lambda.handler"
  runtime       = "python3.12"
  timeout       = 60

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  reserved_concurrent_executions = var.reserved_concurrent_executions

  dead_letter_config {
    target_arn = aws_sqs_queue.dlq.arn
  }

  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_role_policy.this,
  ]
}

resource "aws_cloudwatch_event_rule" "this" {
  name                = "${var.function_name}-schedule"
  description         = "Run the cleanup janitor on a fixed schedule"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "this" {
  rule      = aws_cloudwatch_event_rule.this.name
  target_id = "cleanup-janitor"
  arn       = aws_lambda_function.this.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this.arn
}
