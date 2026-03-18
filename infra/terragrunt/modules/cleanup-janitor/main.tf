data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  cleanup_tag_names                         = distinct(var.cleanup_tag_names)
  cleanup_ttl_tag_names                     = distinct(var.cleanup_ttl_tag_names)
  configured_failure_notification_topic_arn = trimspace(var.failure_notification_topic_arn)
  failure_notifications_enabled             = local.configured_failure_notification_topic_arn != ""
  ec2_resource_arns = [
    "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*",
    "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:security-group/*",
    "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:vpc-endpoint/*",
  ]
  ecs_task_resource_arns = [
    "arn:${data.aws_partition.current.partition}:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task/*",
    "arn:${data.aws_partition.current.partition}:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task/*/*",
  ]
  log_resource_arns = [
    "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.function_name}",
    "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.function_name}:*",
  ]
  cleanup_log_group_resource_arns = [
    "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*",
  ]
  s3_cleanup_resource_arns = [
    "arn:${data.aws_partition.current.partition}:s3:::*",
    "arn:${data.aws_partition.current.partition}:s3:::*/*",
  ]
  ecr_repository_resource_arns = [
    "arn:${data.aws_partition.current.partition}:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/*",
  ]
  scheduler_schedule_resource_arns = [
    "arn:${data.aws_partition.current.partition}:scheduler:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:schedule/*/*",
  ]
  athena_workgroup_resource_arns = [
    "arn:${data.aws_partition.current.partition}:athena:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:workgroup/*",
  ]
  glue_catalog_resource_arns = [
    "arn:${data.aws_partition.current.partition}:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
    "arn:${data.aws_partition.current.partition}:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/*",
    "arn:${data.aws_partition.current.partition}:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/*/*",
  ]
  kinesis_stream_resource_arns = [
    "arn:${data.aws_partition.current.partition}:kinesis:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stream/*",
  ]
  firehose_delivery_stream_resource_arns = [
    "arn:${data.aws_partition.current.partition}:firehose:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deliverystream/*",
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
    for_each = local.cleanup_tag_names
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
    for_each = local.cleanup_tag_names
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
    resources = local.ecs_task_resource_arns
  }

  statement {
    sid    = "CleanupS3Buckets"
    effect = "Allow"
    actions = [
      "s3:DeleteBucket",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:ListBucket",
      "s3:ListBucketVersions",
    ]
    resources = local.s3_cleanup_resource_arns
  }

  statement {
    sid    = "CleanupEcrRepositories"
    effect = "Allow"
    actions = [
      "ecr:DeleteRepository",
      "ecr:DescribeRepositories",
    ]
    resources = local.ecr_repository_resource_arns
  }

  statement {
    sid    = "CleanupLogGroups"
    effect = "Allow"
    actions = [
      "logs:DeleteLogGroup",
      "logs:DescribeLogGroups",
    ]
    resources = local.cleanup_log_group_resource_arns
  }

  statement {
    sid    = "CleanupSchedulerSchedules"
    effect = "Allow"
    actions = [
      "scheduler:DeleteSchedule",
      "scheduler:GetSchedule",
    ]
    resources = local.scheduler_schedule_resource_arns
  }

  statement {
    sid    = "CleanupAthenaWorkgroups"
    effect = "Allow"
    actions = [
      "athena:DeleteWorkGroup",
      "athena:GetWorkGroup",
    ]
    resources = local.athena_workgroup_resource_arns
  }

  statement {
    sid    = "CleanupGlueCatalogObjects"
    effect = "Allow"
    actions = [
      "glue:DeleteDatabase",
      "glue:DeleteTable",
      "glue:GetTables",
    ]
    resources = local.glue_catalog_resource_arns
  }

  statement {
    sid    = "CleanupKinesisStreams"
    effect = "Allow"
    actions = [
      "kinesis:DeleteStream",
      "kinesis:DescribeStreamSummary",
    ]
    resources = local.kinesis_stream_resource_arns
  }

  statement {
    sid    = "CleanupFirehoseDeliveryStreams"
    effect = "Allow"
    actions = [
      "firehose:DeleteDeliveryStream",
      "firehose:DescribeDeliveryStream",
    ]
    resources = local.firehose_delivery_stream_resource_arns
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

  dynamic "statement" {
    for_each = local.failure_notifications_enabled ? [1] : []
    content {
      sid    = "PublishFailureNotifications"
      effect = "Allow"
      actions = [
        "sns:Publish",
      ]
      resources = [local.configured_failure_notification_topic_arn]
    }
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
      cleanup_tag_names              = jsonencode(local.cleanup_tag_names)
      cleanup_ttl_tag_names          = jsonencode(local.cleanup_ttl_tag_names)
      cleanup_schedule_tag_name      = var.cleanup_schedule_tag_name
      created_at_tag_name            = var.created_at_tag_name
      created_on_tag_name            = var.created_on_tag_name
      failure_notification_topic_arn = local.configured_failure_notification_topic_arn
      monthly_cleanup_day            = var.monthly_cleanup_day
      weekly_cleanup_weekday         = var.weekly_cleanup_weekday
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

  environment {
    variables = {
      FAILURE_NOTIFICATION_TOPIC_ARN = local.configured_failure_notification_topic_arn
    }
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

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  count = local.failure_notifications_enabled ? 1 : 0

  alarm_name          = "${var.function_name}-errors"
  alarm_description   = "Notify when the cleanup janitor Lambda reports invocation errors"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [local.configured_failure_notification_topic_arn]

  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }
}
