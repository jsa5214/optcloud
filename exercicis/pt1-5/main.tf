# ---------- VPC ----------
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name    = "main_vcp"
    Project = var.project_name
  }
}

# ---------- SUBNETS ----------
resource "aws_subnet" "Public Subnet" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "${var.region}a"
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  # cidrsubnet(prefix, newbits, netnum)
  #     - prefix: CDIR to subnet
  #     - newbits: Bits to borrow to create subnets
  #     - netnum: Number of the subnet, from to the last available subnet (2^newbits - 1).
  count                   = var.subnet_count
  map_public_ip_on_launch = true
  tags = {
    Name    = "public_subnet_${count.index + 1}"
    Project = var.project_name
  }
}
# Jo anava a fer lo segÜent pero el cidrsubnet() és bastant més elegant i failproof si canvies la vpc_cdir
## cidr_block = "10.0.${count.index + 1}.0/24"
## cidr_block = "10.0.${count.index + var.subnet_count + 1}.0/24"

resource "aws_subnet" "Private Subnet" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "${var.region}a"
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + var.subnet_count)
  count             = var.subnet_count
  tags = {
    Name    = "private_subnet_${count.index + 1}"
    Project = var.project_name
  }
}

# ---------- INTERNET GATEWAY ----------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name    = "iwg_vpc_main"
    Project = var.project_name
  }

}

# ---------- ROUTE TABLE ----------
resource "aws_route_table" "rt_tbl" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = [var.my_ip]
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name    = "routing_table"
    Project = var.project_name
  }

}

# ---------- SECURITY GROUP ----------
resource "aws_security_group" "sg_vpc_main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name    = "sg_vpc_main"
    Project = var.project_name
  }
}






