
# Data: fetch all availability zones

data "aws_availability_zones" "available" {}


# VPC

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}


# Internet Gateway

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "main-igw"
  }
}


# Public Subnets

resource "aws_subnet" "public_subnet" {
  count             = length(var.public_subnet_cidr_block)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnet_cidr_block[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  # Public subnets typically have this set to 'true' so that
  # new EC2 instances get a public IP by default
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}


# Private Subnets

resource "aws_subnet" "private_subnet" {
  count             = length(var.private_subnet_cidr_block)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidr_block[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  # Private subnets usually don't assign public IPs on launch
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}


# Route Table for Public Subnets

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.this.id

  # Route all internet traffic (0.0.0.0/0) via the IGW
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "public-rt"
  }
}


# Associate Public Subnets with Public RT

resource "aws_route_table_association" "public_association" {
  count          = length(var.public_subnet_cidr_block)
  route_table_id = aws_route_table.public_route.id
  subnet_id      = aws_subnet.public_subnet[count.index].id
}



# NAT Gateway
#   - We create an EIP for the NAT
#   - NAT must be in one of the public subnets

resource "aws_eip" "nat_eip" {
  # 'vpc' = true means it's for use in a VPC
  vpc = true

  # Ensure the internet gateway is created before the NAT is attached
  depends_on = [
    aws_internet_gateway.this
  ]
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat_eip.id

  # Place it in the *first* public subnet (index 0). 

  subnet_id = aws_subnet.public_subnet[0].id

  depends_on = [
    aws_internet_gateway.this
  ]

  tags = {
    Name = "main-nat"
  }
}


# Private Route Table (Route to NAT)

resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.this.id

  # Route all internet-bound traffic to the NAT
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "private-rt"
  }
}


# Associate Private Subnets with Private RT

resource "aws_route_table_association" "private_association" {
  count          = length(var.private_subnet_cidr_block)
  route_table_id = aws_route_table.private_route.id
  subnet_id      = aws_subnet.private_subnet[count.index].id
}