locals {
  policy_arn = sensitive("arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore")
  assume_role_policy = sensitive(jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    }
  ))
}

# EC2
resource "aws_instance" "this" {
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.instance.id]
  user_data              = var.user_data_path != null ? templatefile(var.user_data_path, var.user_data_arguments) : null
  iam_instance_profile   = aws_iam_instance_profile.this.name

  root_block_device {
    encrypted = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "${var.name_prefix}_instance"
  }
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name_prefix}-iam-instance-profile"
  role = aws_iam_role.this.name
}

resource "aws_iam_role" "this" {
  name               = "${var.name_prefix}-iam-role"
  assume_role_policy = local.assume_role_policy
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = local.policy_arn
}

resource "aws_security_group" "instance" {
  name   = "${var.name_prefix}-instance-security-group"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    cidr_blocks     = var.enable_load_balancer ? null : var.ingress_cidr_blocks
    security_groups = var.enable_load_balancer ? [aws_security_group.lb[0].id] : null
  }

  tags = {
    Name = "${var.name_prefix}_instance_security_group"
  }
}

# VPC endpoint
resource "aws_vpc_endpoint" "this" {
  for_each = !var.nat_gateway_enabled ? toset(["ec2messages", "ssmmessages", "ssm"]) : []

  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  vpc_id              = var.vpc_id
  subnet_ids          = data.aws_subnets.private.ids
  security_group_ids  = [aws_security_group.vpc_endpoint[0].id]
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  tags = {
    Name = "${var.name_prefix}_${each.value}"
  }
}

resource "aws_security_group" "vpc_endpoint" {
  count = !var.nat_gateway_enabled ? 1 : 0

  name   = "${var.name_prefix}-vpc_endpoint-security-group"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${var.name_prefix}_vpc_endpoint"
  }
}
