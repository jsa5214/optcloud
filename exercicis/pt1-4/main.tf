# ---------- PROVIDER ----------
provider "aws" {
  region = "us-east-1"
}

# ---------- VPC ----------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "VPC_03" }
}

# ---------- SUBNETS ----------
resource "aws_subnet" "SubnetA" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # Autoassign public IP on launch
  tags                    = { Name = "Public Subnet A" }
}

resource "aws_subnet" "SubnetB" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "us-east-1b"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  tags                    = { Name = "Public Subnet B" }

}

# ---------- INTERNET GATEWAY ----------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "igw-vpc_03" }

}

# ---------- ROUTING TABLE ----------
resource "aws_route_table" "rt_tbl" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0" # Redirect all the traffic to the gateway
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "Public Routing Table" }


}

# ---------- ROUTING TABLE ASSOCIATIONS ----------
resource "aws_route_table_association" "rta_a" {
  route_table_id = aws_route_table.rt_tbl.id
  subnet_id      = aws_subnet.SubnetA.id
}

resource "aws_route_table_association" "rta_b" {
  route_table_id = aws_route_table.rt_tbl.id
  subnet_id      = aws_subnet.SubnetB.id
}

# ---------- SECURITY GROUPS ----------
resource "aws_security_group" "sg_vpc_03" {
  name        = "sg_vpc_03"
  description = "Allow SSH, ICMP, and all outgoing traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Must be a list due to the nature of the ingress/egress. Even if it's just 1 element. 
  }

  ingress {
    description = "Allow ICMP from the VPC"
    from_port   = -1 # Code to allow all ICMP traffic
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Allow all outgoing traffic"
    from_port   = 0 # You must assign a port anyway even if you select all protocols. 0 by default
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = { Name = "sg_vpc_03" }
}

# ---------- EC2 INSTANCES ----------
resource "aws_instance" "ec2-a" {
  ami                    = "ami-052064a798f08f0d3"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.SubnetA.id
  key_name               = "vockey"
  vpc_security_group_ids = [aws_security_group.sg_vpc_03.id]
  tags                   = { Name = "ec2-a" }
}

resource "aws_instance" "ec2-b" {
  ami                    = "ami-052064a798f08f0d3"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.SubnetB.id
  key_name               = "vockey"
  vpc_security_group_ids = [aws_security_group.sg_vpc_03.id]
  tags                   = { Name = "ec2-b" }
}
