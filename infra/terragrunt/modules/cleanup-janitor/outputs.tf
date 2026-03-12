output "function_name" {
  value = aws_lambda_function.this.function_name
}

output "schedule_rule_name" {
  value = aws_cloudwatch_event_rule.this.name
}

output "dlq_url" {
  value = aws_sqs_queue.dlq.url
}
