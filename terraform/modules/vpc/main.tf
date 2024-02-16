data "aws_availability_zones" "main" {}

locals {
  azs                                 = length(var.availability_zones) > 0 ? var.availability_zones : data.aws_availability_zones.main.names
  internet_gateway_count              = (var.create_internet_gateway && length(var.public_subnet_cidrs) > 0) ? 1 : 0
  egress_only_internet_gateway_count  = (var.create_egress_only_internet_gateway && length(var.private_subnet_cidrs) > 0) ? 1 : 0
  public_route_count                  = var.create_individual_public_subnet_route_tables ? length(var.public_subnet_cidrs) : local.internet_gateway_count
  create_public_subnet_default_routes = var.create_public_subnet_default_routes ? local.public_route_count : 0
}

resource "aws_vpc" "main" {
  cidr_block                       = var.cidr_block
  instance_tenancy                 = "default"
  assign_generated_ipv6_cidr_block = true

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-vpc"
    },
  )
}

resource "aws_internet_gateway" "public" {
  count      = local.internet_gateway_count
  depends_on = [aws_vpc.main]
  vpc_id     = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-public-igw"
    },
  )
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = element(local.azs, count.index)
  map_public_ip_on_launch = var.map_public_ip_on_launch


  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-public-subnet-${count.index + 1}"
      "Tier" = "Public"
    },
  )
}

resource "aws_route_table" "public" {
  count      = local.public_route_count
  depends_on = [aws_vpc.main]
  vpc_id     = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      "Name" = var.create_individual_public_subnet_route_tables ? "${var.name_prefix}-public-rt-${count.index + 1}" : "${var.name_prefix}-public-rt"
    },
  )
}

resource "aws_route" "public" {
  count = local.create_public_subnet_default_routes
  depends_on = [
    aws_internet_gateway.public,
    aws_route_table.public,
  ]
  route_table_id         = aws_route_table.public[count.index].id
  gateway_id             = aws_internet_gateway.public[0].id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "ipv6-public" {
  count = local.create_public_subnet_default_routes
  depends_on = [
    aws_internet_gateway.public,
    aws_route_table.public,
  ]
  route_table_id              = aws_route_table.public[count.index].id
  gateway_id                  = aws_internet_gateway.public[0].id
  destination_ipv6_cidr_block = "::/0"
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = var.create_individual_public_subnet_route_tables ? aws_route_table.public[count.index].id : aws_route_table.public[0].id
}

resource "aws_security_group" "main" {
  name        = "main_vpc_sg"
  description = "Allow traffic to pass from to the internet"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-sg"
    },
  )
}