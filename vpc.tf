locals {
  subnets_count            = var.public_subnets_count + var.private_subnets_count
  subnet_bits              = ceil(log(local.subnets_count, 2))
  public_cidr_subnets      = [for net in range(0, var.public_subnets_count) : cidrsubnet(var.vpc_cidr_block, local.subnet_bits, net)]
  private_cidr_subnets     = [for net in range(var.public_subnets_count, local.subnets_count) : cidrsubnet(var.vpc_cidr_block, local.subnet_bits, net)]
  availability_zones_count = length(data.aws_availability_zones.available.names)
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = "${var.name_prefix}_vpc"
  }
}

resource "aws_subnet" "public" {
  count = length(local.public_cidr_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_cidr_subnets[count.index]
  map_public_ip_on_launch = "true"
  availability_zone       = count.index < local.availability_zones_count ? data.aws_availability_zones.available.names[count.index] : data.aws_availability_zones.available.names[count.index % local.availability_zones_count]

  tags = {
    Name = "${var.name_prefix}_public_subnet_${count.index + 1}"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}_internet_gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.name_prefix}_public_route_table"
  }
}

resource "aws_route_table_association" "public" {
  count = length(local.public_cidr_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "private" {
  count = length(local.private_cidr_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_cidr_subnets[count.index]
  availability_zone = count.index < local.availability_zones_count ? data.aws_availability_zones.available.names[count.index] : data.aws_availability_zones.available.names[count.index % local.availability_zones_count]

  tags = {
    Name = "${var.name_prefix}_private_subnet_${count.index + 1}"
  }
}

resource "aws_vpc_endpoint" "this" {
  for_each = length(local.private_cidr_subnets) > 0 && !var.enable_nat_gateway ? toset(["ec2messages", "ssmmessages", "ssm"]) : []

  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  vpc_id              = aws_vpc.this.id
  subnet_ids          = [for subnet in aws_subnet.private : subnet.id]
  security_group_ids  = [aws_security_group.vpc_endpoint[0].id]
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  tags = {
    Name = "${var.name_prefix}_${each.value}_vpc_endpoint"
  }
}

resource "aws_security_group" "vpc_endpoint" {
  count = length(local.private_cidr_subnets) > 0 && !var.enable_nat_gateway ? 1 : 0

  name   = "${var.name_prefix}-vpc_endpoint-security-group"
  vpc_id = aws_vpc.this.id

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
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  tags = {
    Name = "${var.name_prefix}_vpc_endpoint_security_group"
  }
}

resource "aws_eip" "nat_gateway" {
  count = var.enable_nat_gateway ? 1 : 0

  vpc = true

  tags = {
    Name = "${var.name_prefix}_nat_gateway_eip"
  }
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat_gateway[count.index].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.name_prefix}_nat_gateway"
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [
      {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.this[0].id
      }
    ] : []
    content {
      cidr_block     = route.value["cidr_block"]
      nat_gateway_id = route.value["nat_gateway_id"]
    }
  }

  tags = {
    Name = "${var.name_prefix}_private_route_table"
  }
}

# route associations private
resource "aws_route_table_association" "private" {
  count = length(local.private_cidr_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
