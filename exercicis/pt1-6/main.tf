# ---------- LOCALS ----------
locals {
  azs = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f"]
  private_subnets = {
    for i in range(var.private_instance_count) :
    "private_${i + 1}_${element(local.azs, i)}" => {
      cidr = cidrsubnet(var.vpc_cidr, 8, i + 2) # Offset not to overlap with the bastion CIDR
      # To avoid 'index out of range' errors, use the element function or the % operator
      az = element(local.azs, i)
    }
  }

  private_instances = flatten([
    for subnet_key, subnet in aws_subnet.private_subnet : [
      for i in range(var.private_instance_count) : {
        key       = "${subnet_key}_${i + 1}"
        subnet_id = subnet.id
      }
    ]
  ])
}

# ---------- VPC ----------
# Defines the main Virtual Private Cloud.
# The CIDR block is provided via variables and used to derive subnets later.
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name    = "${var.project_name}_main_vpc"
    Project = var.project_name
  }
}

# ---------- SUBNETS ----------
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.main.id
  availability_zone = local.azs[0]
  cidr_block        = "10.0.1.0/24"
  tags = {
    Name    = "${var.project_name}_bastion_us-east-1a_public_subnet"
    Project = var.project_name
  }

}

resource "aws_subnet" "private_subnet" {
  for_each          = local.private_subnets
  vpc_id            = aws_vpc.main.id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr
  tags = {
    Name    = "${var.project_name}_${each.key}"
    Project = var.project_name
  }
}

# ---------- INTERNET GATEWAY ----------
# The Internet Gateway allows outbound Internet access for public subnets.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name    = "${var.project_name}_iwg_vpc_main"
    Project = var.project_name
  }

}

# ---------- ROUTE TABLE ----------
# Defines a routing table that directs 0.0.0.0/0 (all outbound traffic) to the Internet Gateway.
# Only public subnets will be associated with this route table.
resource "aws_route_table" "rt_tbl_public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name    = "${var.project_name}_routing_table"
    Project = var.project_name
  }
}

resource "aws_route_table" "rt_tbl_private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngtw.id
  }
  tags = {
    Name    = "${var.project_name}_routing_table"
    Project = var.project_name
  }
}

# ---------- ROUTING TABLE ASSOCIATIONS ----------
resource "aws_route_table_association" "rta_public" {
  route_table_id = aws_route_table.rt_tbl_public.id
  subnet_id      = aws_subnet.public_subnet.id
}

resource "aws_route_table_association" "rta_private" {
  for_each       = aws_subnet.private_subnet
  route_table_id = aws_route_table.rt_tbl_private.id
  subnet_id      = each.value.id
}
# ---------- ELASTIC IPs ----------
# Elastic IP for the NAT Gateway
resource "aws_eip" "ngtw_eip" {
  domain = "vpc"
}

# Elastic IP for the bastion instance
resource "aws_eip" "bastion_eip" {
  domain = "vpc"
}

# ---------- NAT Gateway ----------
resource "aws_nat_gateway" "ngtw" {
  allocation_id = aws_eip.ngtw_eip.id
  subnet_id     = aws_subnet.public_subnet.id
}

# ---------- SECURITY GROUP ----------
resource "aws_security_group" "sg_bastion" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name    = "sg_bastion"
    Project = var.project_name
  }

  ingress {
    description = "Allow SSH from allowed IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  egress {
    description = "Allow SSH traffic to the VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
}

resource "aws_security_group" "sg_private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name    = "sg_private"
    Project = var.project_name
  }

  ingress {
    description     = "Allow SSH traffic from sg_bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_bastion.id]
  }

  ingress {
    description = "Allow SSH from itself"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "Allow any outgoing traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------- PAIR KEYS ----------
resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "bastion_key_pair" {
  key_name = "bastion-key"
  public_key = tls_private_key.bastion_key.public_key_openssh
}

resource "local_file" "bastion_pem" {
  filename = "bastion.pem"
  content = tls_private_key.bastion_key.private_key_pem
  file_permission = "400"
  
}

resource "tls_private_key" "private_instance_key" {
  for_each = local.private_instances
  algorithm = "RSA"
  rsa_bits = 4096
  
}
