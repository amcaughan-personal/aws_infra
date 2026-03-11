# Root console login
resource "aws_cloudwatch_log_metric_filter" "root_console_login" {
  name           = "RootConsoleLogin"
  log_group_name = var.log_group_name

  pattern = "{ ($.eventName = \"ConsoleLogin\") && ($.userIdentity.type = \"Root\") && ($.responseElements.ConsoleLogin = \"Success\") }"

  metric_transformation {
    name      = "RootConsoleLoginCount"
    namespace = "Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "root_console_login" {
  alarm_name          = "RootConsoleLogin"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.eval_periods
  metric_name         = "RootConsoleLoginCount"
  namespace           = "Security"
  period              = var.period_seconds
  statistic           = "Sum"
  threshold           = 1

  alarm_actions = [var.sns_topic_arn]
}

# CloudTrail tampering
resource "aws_cloudwatch_log_metric_filter" "cloudtrail_tamper" {
  name           = "CloudTrailTamper"
  log_group_name = var.log_group_name

  pattern = "{ ($.eventSource = \"cloudtrail.amazonaws.com\") && (($.eventName = \"StopLogging\") || ($.eventName = \"DeleteTrail\") || ($.eventName = \"UpdateTrail\") || ($.eventName = \"PutEventSelectors\")) }"

  metric_transformation {
    name      = "CloudTrailTamperCount"
    namespace = "Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudtrail_tamper" {
  alarm_name          = "CloudTrailTamper"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.eval_periods
  metric_name         = "CloudTrailTamperCount"
  namespace           = "Security"
  period              = var.period_seconds
  statistic           = "Sum"
  threshold           = 1

  alarm_actions = [var.sns_topic_arn]
}

# High-signal IAM changes
resource "aws_cloudwatch_log_metric_filter" "iam_changes" {
  name           = "IamChanges"
  log_group_name = var.log_group_name

  pattern = <<-EOT
{ ($.eventSource = "iam.amazonaws.com") && (
    ($.eventName = "CreateUser") || ($.eventName = "DeleteUser") ||
    ($.eventName = "CreateRole") || ($.eventName = "DeleteRole") ||
    ($.eventName = "PutUserPolicy") || ($.eventName = "PutRolePolicy") ||
    ($.eventName = "AttachUserPolicy") || ($.eventName = "AttachRolePolicy") ||
    ($.eventName = "DetachUserPolicy") || ($.eventName = "DetachRolePolicy") ||
    ($.eventName = "UpdateAssumeRolePolicy")
) }
EOT

  metric_transformation {
    name      = "IamChangesCount"
    namespace = "Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "iam_changes" {
  alarm_name          = "IamChanges"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.eval_periods
  metric_name         = "IamChangesCount"
  namespace           = "Security"
  period              = var.period_seconds
  statistic           = "Sum"
  threshold           = 1

  alarm_actions = [var.sns_topic_arn]
}

# Repeated failed console logins
resource "aws_cloudwatch_log_metric_filter" "console_login_failures" {
  name           = "ConsoleLoginFailures"
  log_group_name = var.log_group_name

  pattern = "{ ($.eventName = \"ConsoleLogin\") && ($.errorMessage = \"Failed authentication\") }"

  metric_transformation {
    name      = "ConsoleLoginFailuresCount"
    namespace = "Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "console_login_failures" {
  alarm_name          = "ConsoleLoginFailureBurst"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.eval_periods
  metric_name         = "ConsoleLoginFailuresCount"
  namespace           = "Security"
  period              = var.period_seconds
  statistic           = "Sum"
  threshold           = var.console_login_failure_threshold

  alarm_actions = [var.sns_topic_arn]
}

# Long-lived credentials appearing unexpectedly
resource "aws_cloudwatch_log_metric_filter" "access_key_created" {
  name           = "AccessKeyCreated"
  log_group_name = var.log_group_name

  pattern = "{ ($.eventSource = \"iam.amazonaws.com\") && ($.eventName = \"CreateAccessKey\") }"

  metric_transformation {
    name      = "AccessKeyCreatedCount"
    namespace = "Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "access_key_created" {
  alarm_name          = "AccessKeyCreated"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.eval_periods
  metric_name         = "AccessKeyCreatedCount"
  namespace           = "Security"
  period              = var.period_seconds
  statistic           = "Sum"
  threshold           = 1

  alarm_actions = [var.sns_topic_arn]
}

# Network exposure changes
resource "aws_cloudwatch_log_metric_filter" "security_group_ingress_change" {
  name           = "SecurityGroupIngressChange"
  log_group_name = var.log_group_name

  pattern = "{ ($.eventSource = \"ec2.amazonaws.com\") && (($.eventName = \"AuthorizeSecurityGroupIngress\") || ($.eventName = \"RevokeSecurityGroupIngress\")) }"

  metric_transformation {
    name      = "SecurityGroupIngressChangeCount"
    namespace = "Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "security_group_ingress_change" {
  alarm_name          = "SecurityGroupIngressChange"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.eval_periods
  metric_name         = "SecurityGroupIngressChangeCount"
  namespace           = "Security"
  period              = var.period_seconds
  statistic           = "Sum"
  threshold           = 1

  alarm_actions = [var.sns_topic_arn]
}
