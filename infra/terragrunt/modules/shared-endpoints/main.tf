data "aws_region" "current" {}

locals {
  interface_endpoint_services = merge(
    var.enable_execute_api ? { execute_api = "execute-api" } : {},
    var.enable_ecr_api ? { ecr_api = "ecr.api" } : {},
    var.enable_ecr_dkr ? { ecr_dkr = "ecr.dkr" } : {},
    var.enable_logs ? { logs = "logs" } : {},
    var.enable_ssm ? { ssm = "ssm" } : {},
    var.enable_athena ? { athena = "athena" } : {},
    var.enable_glue ? { glue = "glue" } : {},
    var.enable_sts ? { sts = "sts" } : {},
    var.enable_kinesis_streams ? { kinesis_streams = "kinesis-streams" } : {},
  )
}

resource "aws_security_group" "interface_endpoints" {
  count = length(local.interface_endpoint_services) > 0 ? 1 : 0

  name        = "${var.name_prefix}-interface-endpoints"
  description = "Shared security group for private interface VPC endpoints"
  vpc_id      = var.vpc_id

  tags = merge(
    {
      Name = "${var.name_prefix}-interface-endpoints"
    },
  )

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

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoint_services

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.interface_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(
    {
      Name = "${var.name_prefix}-${replace(each.key, "_", "-")}"
    },
  )
}

resource "aws_vpc_endpoint" "s3_gateway" {
  count = var.enable_s3_gateway ? 1 : 0

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_table_ids

  tags = merge(
    {
      Name = "${var.name_prefix}-s3-gateway"
    },
  )
}

resource "aws_ssm_parameter" "interface_endpoint_id" {
  for_each = var.publish_ssm_parameters ? aws_vpc_endpoint.interface : {}

  name  = "${var.ssm_prefix}/${each.key}_vpce_id"
  type  = "String"
  value = each.value.id
}

resource "aws_ssm_parameter" "endpoint_security_group_id" {
  count = var.publish_ssm_parameters && length(local.interface_endpoint_services) > 0 ? 1 : 0

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
