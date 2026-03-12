data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  selected_az_count = min(var.availability_zone_count, length(data.aws_availability_zones.available.names))
  selected_azs      = slice(data.aws_availability_zones.available.names, 0, local.selected_az_count)

  private_subnet_cidrs = {
    for index, az in local.selected_azs :
    az => cidrsubnet(var.vpc_cidr, 8, index)
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
}

resource "aws_subnet" "private" {
  for_each = local.private_subnet_cidrs

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = false
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "shared_workloads" {
  name        = "${var.name_prefix}-shared-workloads"
  description = "Shared outbound-only security group for internal dev workloads"
  vpc_id      = aws_vpc.this.id

  egress {
    description      = "Allow shared dev workloads to initiate outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_ssm_parameter" "vpc_id" {
  count = var.publish_ssm_parameters ? 1 : 0

  name  = "${var.ssm_prefix}/vpc_id"
  type  = "String"
  value = aws_vpc.this.id
}

resource "aws_ssm_parameter" "vpc_cidr" {
  count = var.publish_ssm_parameters ? 1 : 0

  name  = "${var.ssm_prefix}/vpc_cidr"
  type  = "String"
  value = aws_vpc.this.cidr_block
}

resource "aws_ssm_parameter" "private_subnet_ids" {
  count = var.publish_ssm_parameters ? 1 : 0

  name  = "${var.ssm_prefix}/private_subnet_ids"
  type  = "StringList"
  value = join(",", [for subnet in aws_subnet.private : subnet.id])
}

resource "aws_ssm_parameter" "private_route_table_ids" {
  count = var.publish_ssm_parameters ? 1 : 0

  name  = "${var.ssm_prefix}/private_route_table_ids"
  type  = "StringList"
  value = aws_route_table.private.id
}

resource "aws_ssm_parameter" "shared_workload_security_group_id" {
  count = var.publish_ssm_parameters ? 1 : 0

  name  = "${var.ssm_prefix}/shared_workload_security_group_id"
  type  = "String"
  value = aws_security_group.shared_workloads.id
}
