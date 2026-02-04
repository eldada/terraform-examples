# Data source to get available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-vpc"
    }
  )
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-igw"
    }
  )
}

# Create public subnets
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-public-subnet-${count.index + 1}"
      "kubernetes.io/role/elb" = "1"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
  )
}

# Create private subnets
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-private-subnet-${count.index + 1}"
      "kubernetes.io/role/internal-elb" = "1"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
  )
}

# Local to determine NAT Gateway count based on mode
locals {
  nat_gateway_count = var.nat_gateway_mode == "single" ? 1 : length(var.availability_zones)
}

# Create Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = local.nat_gateway_count

  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-nat-eip-${count.index + 1}"
    }
  )
}

# Create NAT Gateways
# In "single" mode: one NAT Gateway in the first public subnet
# In "ha" mode: one NAT Gateway per AZ for high availability
resource "aws_nat_gateway" "main" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.main]

  tags = merge(
    var.tags,
    {
      Name = var.nat_gateway_mode == "single" ? "${var.cluster_name}-nat" : "${var.cluster_name}-nat-${count.index + 1}"
    }
  )
}

# Create route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-public-rt"
    }
  )
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Create route tables for private subnets
# In "single" mode: all private subnets share one route table pointing to the single NAT Gateway
# In "ha" mode: each private subnet has its own route table pointing to its AZ's NAT Gateway
resource "aws_route_table" "private" {
  count = var.nat_gateway_mode == "single" ? 1 : length(var.availability_zones)

  vpc_id = aws_vpc.main.id

  route {
    # "0.0.0.0/0" specifies the default route for all IPv4 addresses,
    # meaning any outgoing traffic not matched by a more specific route
    # will be routed through the NAT Gateway defined below.
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.nat_gateway_mode == "single" ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index].id
  }

  tags = merge(
    var.tags,
    {
      Name = var.nat_gateway_mode == "single" ? "${var.cluster_name}-private-rt" : "${var.cluster_name}-private-rt-${count.index + 1}"
    }
  )
}

# Associate private subnets with private route tables
# In "single" mode: all private subnets associate with the single route table
# In "ha" mode: each private subnet associates with its corresponding route table
resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.nat_gateway_mode == "single" ? aws_route_table.private[0].id : aws_route_table.private[count.index].id
}

