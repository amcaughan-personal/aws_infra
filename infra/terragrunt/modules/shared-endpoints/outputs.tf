output "execute_api_vpce_id" {
  value = var.enable_execute_api ? aws_vpc_endpoint.execute_api[0].id : null
}

output "execute_api_endpoint_security_group_id" {
  value = var.enable_execute_api ? aws_security_group.interface_endpoints[0].id : null
}

output "s3_gateway_endpoint_id" {
  value = var.enable_s3_gateway ? aws_vpc_endpoint.s3_gateway[0].id : null
}

output "private_dns_zone_id" {
  value = var.enable_private_dns_zone ? aws_route53_zone.private[0].zone_id : null
}

output "private_dns_zone_name" {
  value = var.enable_private_dns_zone ? aws_route53_zone.private[0].name : null
}
