data "aws_region" "current" {}

resource "aws_security_group" "interface_endpoints" {
  count = var.enable_execute_api ? 1 : 0

  name        = "${var.name_prefix}-interface-endpoints"
  description = "Shared security group for private interface VPC endpoints"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTPS from inside the shared dev VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description      = "Allow endpoint responses and service-managed outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_vpc_endpoint" "execute_api" {
  count = var.enable_execute_api ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.execute-api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.interface_endpoints[0].id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3_gateway" {
  count = var.enable_s3_gateway ? 1 : 0

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_table_ids
}

resource "aws_route53_zone" "private" {
  count = var.enable_private_dns_zone ? 1 : 0

  name = var.private_dns_zone_name

  vpc {
    vpc_id = var.vpc_id
  }
}

resource "aws_ssm_parameter" "execute_api_vpce_id" {
  count = var.publish_ssm_parameters && var.enable_execute_api ? 1 : 0

  name  = "${var.ssm_prefix}/execute_api_vpce_id"
  type  = "String"
  value = aws_vpc_endpoint.execute_api[0].id
}

resource "aws_ssm_parameter" "endpoint_security_group_id" {
  count = var.publish_ssm_parameters && var.enable_execute_api ? 1 : 0

  name  = "${var.ssm_prefix}/endpoint_security_group_id"
  type  = "String"
  value = aws_security_group.interface_endpoints[0].id
}

resource "aws_ssm_parameter" "s3_gateway_endpoint_id" {
  count = var.publish_ssm_parameters && var.enable_s3_gateway ? 1 : 0

  name  = "${var.ssm_prefix}/s3_gateway_endpoint_id"
  type  = "String"
  value = aws_vpc_endpoint.s3_gateway[0].id
}

resource "aws_ssm_parameter" "private_dns_zone_id" {
  count = var.publish_ssm_parameters && var.enable_private_dns_zone ? 1 : 0

  name  = "${var.ssm_prefix}/private_dns_zone_id"
  type  = "String"
  value = aws_route53_zone.private[0].zone_id
}

resource "aws_ssm_parameter" "private_dns_zone_name" {
  count = var.publish_ssm_parameters && var.enable_private_dns_zone ? 1 : 0

  name  = "${var.ssm_prefix}/private_dns_zone_name"
  type  = "String"
  value = aws_route53_zone.private[0].name
}
