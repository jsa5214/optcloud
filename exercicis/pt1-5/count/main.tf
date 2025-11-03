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
  vpc_id            = aws_vpc.main.id
  availability_zone = "${var.region}a"
  count             = var.subnet_count
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  # cidrsubnet(prefix, newbits, netnum)
  #     - prefix: CDIR to subnet
  #     - newbits: Bits to borrow to create subnets
  #     - netnum: Number of the subnet, from to the last available subnet (2^newbits - 1).
  map_public_ip_on_launch = true
  tags = {
    Name    = "${var.project_name}_public_subnet_${count.index + 1}"
    Project = var.project_name
  }
}
# Jo anava a fer lo següent pero el cidrsubnet() és bastant més elegant i failproof si canvies la vpc_cidr
## cidr_block = "10.0.${count.index + 1}.0/24"
## cidr_block = "10.0.${count.index + var.subnet_count + 1}.0/24"

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "${var.region}a"
  count             = var.subnet_count
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + var.subnet_count)
  tags = {
    Name    = "${var.project_name}_private_subnet_${count.index + 1}"
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
  route_table_id = aws_route_table.rt_tbl.id
  count          = var.subnet_count
  subnet_id      = aws_subnet.public_subnet[count.index].id
}


# ---------- SECURITY GROUP ----------
resource "aws_security_group" "sg_vpc_main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name    = "${var.project_name}_sg_vpc_main"
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
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  count                  = var.instance_count
  subnet_id              = aws_subnet.public_subnet[count.index].id
  key_name               = "vockey"
  vpc_security_group_ids = [aws_security_group.sg_vpc_main.id]
  tags = {
    Name    = "${var.project_name}_public_instance_${count.index + 1}"
    Project = var.project_name
  }
}

resource "aws_instance" "ec2_private" {
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  count                  = var.instance_count
  subnet_id              = aws_subnet.private_subnet[count.index].id
  vpc_security_group_ids = [aws_security_group.sg_vpc_main.id]
  key_name               = "vockey"
  tags = {
    Name    = "${var.project_name}_private_instance_${count.index + 1}"
    Project = var.project_name
  }
}



# ---------- S3 BUCKET ----------
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "s3_bucket" {
  count = var.create_s3_bucket ? 1 : 0 # Conditional ternari structure. 
  tags = {
    Name   = "Bucket"
    bucket = "${var.project_name}-bucket-${random_id.suffix.hex}"
    # Bucket name must be unique in the whole AWS structure so we use a random_id generator to avoid issues.
    Project = var.project_name
  }
}
