output "instance_id" {
  value = aws_instance.this.id
}

output "start_session_command" {
  value = "aws ssm start-session --target ${aws_instance.this.id}"
}

output "security_group_id" {
  value = aws_security_group.host.id
}

output "session_manager_endpoint_security_group_id" {
  value = aws_security_group.session_manager_endpoints.id
}
