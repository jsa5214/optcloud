locals {
  public_subnets = {
    for i in range(var.var.subnet_count) :
    "public_${i + 1}" => {
      cidr = cidrsubnet(var.vpc_cidr, 8, i)
      az   = "us-east-1${element(["a", "b", "c", "d"], i)}"
    }
  }

  private_subnets = {
    for i in range(var.subnet_count) :
    "private_${i + 1}" => {
      cidr = cidrsubnet(var.vpc_cidr, 8, i + var.subnet_count)
      az   = "us-east-1${element(["a", "b", "c", "d"], i)}"
    }
  }
  public_instances = flatten([
    for subnet_key, subnet in aws_subnet.public_subnet : [
      for i in range(var.subnet_count) : {
        key       = "${subnet_key}_${i + 1}"
        subnet_id = subnet.id
        number    = i + 1
      }
    ]
  ])
}

# ---------- VPC ----------
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name    = "${var.project_name}_main_vcp"
    Project = var.project_name
  }
}

# ---------- SUBNETS ----------
resource "aws_subnet" "public_subnet" {
  for_each                = local.public_subnets
  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.value.az
  cidr_block              = each.value.cidir
  count                   = var.subnet_count
  map_public_ip_on_launch = true
  tags = {
    Name    = "${var.project_name}_${each.key}"
    Project = var.project_name
  }
}

resource "aws_subnet" "public_subnet" {
  for_each          = local.private_subnets
  vpc_id            = aws_vpc.main.id
  availability_zone = each.value.az
  cidr_block        = each.value.cidir
  count             = var.subnet_count
  tags = {
    Name    = "${var.project_name}_${each.key}"
    Project = var.project_name
  }
}

# ---------- INTERNET GATEWAY ----------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name    = "${var.project_name}_iwg_vpc_main"
    Project = var.project_name
  }

}

# ---------- ROUTE TABLE ----------
resource "aws_route_table" "rt_tbl" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/16"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name    = "${var.project_name}_routing_table"
    Project = var.project_name
  }
}

# ---------- ROUTING TABLE ASSOCIATIONS ----------
resource "aws_route_table_association" "rta" {
  for_each       = aws_subnet.public_subnet
  route_table_id = aws_route_table.rt_tbl.id
  subnet_id      = each.value.id
}

# ---------- SECURITY GROUP ----------
resource "aws_security_group" "sg_vpc_main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name    = "sg_vpc_main"
    Project = var.project_name
  }

  ingress {
    description = "Allow HTTP from any IP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH from my home IP & HS IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip] # Ometem que es la IP real y no 0.0.0.0
  }

  ingress {
    description = "Allow only ICMP traffic from within the VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow any outgoing traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------- EC2 INSTANCES ----------
resource "aws_instance" "ec2_public" {
  for_each               = { for obj in local.public_instances : obj.key => obj }
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  subnet_id              = each.value.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.sg_vpc_main.id]
  tags = {
    Name    = "${var.project_name}_ec2_${each.value}_instance"
    Project = var.project_name
  }
}

resource "aws_instance" "ec2_private" {
  for_each               = aws_subnet.public_subnet
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_subnet[count.index].id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.sg_vpc_main.id]
  tags = {
    Name    = "${var.project_name}_ec2_${each.value}_instance"
    Project = var.project_name
  }
}


# ---------- S3 BUCKET ----------
resource "aws_s3_bucket" "s3_bucket" {
  count  = var.create_s3_bucket ? 1 : 0 # Conditional ternari structure. 
  bucket = "${var.project_name}-bucket" # Must be unique in the whole AWS structure
  tags = {
    Name    = "Bucket"
    Project = var.project_name
  }
}







