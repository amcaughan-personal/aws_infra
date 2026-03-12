output "execute_api_vpce_id" {
  value = try(aws_vpc_endpoint.interface["execute_api"].id, null)
}

output "execute_api_endpoint_security_group_id" {
  value = length(local.interface_endpoint_services) > 0 ? aws_security_group.interface_endpoints[0].id : null
}

output "s3_gateway_endpoint_id" {
  value = var.enable_s3_gateway ? aws_vpc_endpoint.s3_gateway[0].id : null
}

output "interface_endpoint_ids" {
  value = { for key, endpoint in aws_vpc_endpoint.interface : key => endpoint.id }
}
