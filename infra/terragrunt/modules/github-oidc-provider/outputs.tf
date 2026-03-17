output "provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}

output "provider_url" {
  value = aws_iam_openid_connect_provider.github.url
}

output "client_id_list" {
  value = aws_iam_openid_connect_provider.github.client_id_list
}
