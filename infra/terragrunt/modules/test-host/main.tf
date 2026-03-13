data "aws_region" "current" {}

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "time_static" "created_on" {
  count = var.auto_cleanup_enabled ? 1 : 0
}

locals {
  cleanup_tags = var.auto_cleanup_enabled ? {
    (var.cleanup_tag_name)          = "true"
    (var.cleanup_schedule_tag_name) = var.cleanup_schedule
    (var.created_on_tag_name)       = formatdate("YYYY-MM-DD", time_static.created_on[0].rfc3339)
  } : {}
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.name_prefix}-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name_prefix}-instance-profile"
  role = aws_iam_role.this.name
}

resource "aws_security_group" "host" {
  name        = "${var.name_prefix}-host"
  description = "No-ingress security group for the dev network test host"
  vpc_id      = var.vpc_id

  tags = merge(
    local.cleanup_tags,
    {
      Name = "${var.name_prefix}-host"
    },
  )

  egress {
    description      = "Allow the test host to reach VPC endpoints and other outbound targets"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "session_manager_endpoints" {
  name        = "${var.name_prefix}-session-manager-endpoints"
  description = "Allow HTTPS from inside the shared dev VPC to Session Manager endpoints"
  vpc_id      = var.vpc_id

  tags = merge(
    local.cleanup_tags,
    {
      Name = "${var.name_prefix}-session-manager-endpoints"
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

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.session_manager_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    local.cleanup_tags,
    {
      Name = "${var.name_prefix}-ssm"
    },
  )
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.session_manager_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    local.cleanup_tags,
    {
      Name = "${var.name_prefix}-ssmmessages"
    },
  )
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.session_manager_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    local.cleanup_tags,
    {
      Name = "${var.name_prefix}-ec2messages"
    },
  )
}

resource "aws_instance" "this" {
  ami                  = data.aws_ssm_parameter.al2023_ami.value
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.this.name
  subnet_id            = var.subnet_id
  ebs_optimized        = true
  vpc_security_group_ids = [
    aws_security_group.host.id,
  ]

  associate_public_ip_address = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted = true
  }

  tags = merge(
    local.cleanup_tags,
    {
      Name = var.name_prefix
    },
  )

  depends_on = [
    aws_vpc_endpoint.ssm,
    aws_vpc_endpoint.ssmmessages,
    aws_vpc_endpoint.ec2messages,
  ]
}

resource "aws_ssm_parameter" "instance_id" {
  count = var.publish_ssm_parameters ? 1 : 0

  name  = "${var.ssm_prefix}/instance_id"
  type  = "String"
  value = aws_instance.this.id
}
