# ---------- LOCALS ----------
# Allows you to define intermediate values to reuse through the configuration
# It doesn't create resources by itself
# Helps you build complex structures suchs as maps or lists
locals {
  azs = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f"] # List with all the azs

  public_subnets = {
    # "key => value" in the for loop dinamically generates a map {public_us-east-1a => {cidr"...", az="..."}, that contains the subnets 
    #                                                             public_us-east-1b => {cidr"...", az="..."}}
    for i in range(var.subnet_count) :
    "public_${local.azs[i]}" => {
      cidr = cidrsubnet(var.vpc_cidr, 8, i)
      az   = "${local.azs[i]}"
    }
  }

  private_subnets = {
    for i in range(var.subnet_count) :
    "private_${local.azs[i]}" => {
      cidr = cidrsubnet(var.vpc_cidr, 8, i + var.subnet_count)
      az   = "${local.azs[i]}"
    }
  }

  public_instances = flatten([
  # The nested for generates a list of lists of objects (unusable for a for_each structure, so flatten is used to merge the lists into a single list that contains all the objects) / flatten([[1,2],[3,4]]) -> [1,2,3,4]
    for subnet_key, subnet in aws_subnet.public_subnet : [
      for i in range(var.instance_count) : {
        key       = "${subnet_key}_${i + 1}"
        subnet_id = subnet.id
      }
    ]
  ])

  # After the flatten each element represents a EC2 instance
  # [                                                             to    [
  #   [ {key="public-us-east-1a-1", subnet_id="...", number=1},           {key="public-us-east-1a-1", subnet_id="...", number=1},
  #     {key="public-us-east-1a-2", subnet_id="...", number=2} ],         {key="public-us-east-1a-2", subnet_id="...", number=2},
  #   [ {key="public-us-east-1b-1", subnet_id="...", number=1},           {key="public-us-east-1b-1", subnet_id="...", number=1},
  #     {key="public-us-east-1b-2", subnet_id="...", number=2} ]          {key="public-us-east-1b-2", subnet_id="...", number=2}
  # ]                                                                   ]

  private_instances = flatten([
    for subnet_key, subnet in aws_subnet.private_subnet : [
      for i in range(var.instance_count) : {
        key       = "${subnet_key}_${i + 1}"
        subnet_id = subnet.id
      }
    ]
  ])
}

# ---------- VPC ----------
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name    = "${var.project_name}_main_vpc"
    Project = var.project_name
  }
}

# ---------- SUBNETS ----------
resource "aws_subnet" "public_subnet" {
  for_each                = local.public_subnets
  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.value.az
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = true
  tags = {
    Name    = "${var.project_name}_${each.key}"
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
    cidr_block = "0.0.0.0/0"
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
    description = "Allow SSH from my home IP & school IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
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
  for_each = { for obj in local.public_instances : obj.key => obj }
  # for each (obj) in local.public_instances, use obj.key as the key, and store the whole object as value. That helps to easly reference the object.
  #   {
  #   "public-us-east-1a-1" = {subnet_id="...", number=1, key="..."},
  #   "public-us-east-1a-2" = {subnet_id="...", number=2, key="..."},
  #   "public-us-east-1b-1" = {subnet_id="...", number=1, key="..."},
  #   "public-us-east-1b-2" = {subnet_id="...", number=2, key="..."}
  # }
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  subnet_id              = each.value.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.sg_vpc_main.id]
  tags = {
    Name    = each.key
    Project = var.project_name
  }
}

resource "aws_instance" "ec2_private" {
  for_each = { for obj in local.private_instances : obj.key => obj }

  ami                    = var.instance_ami
  instance_type          = var.instance_type
  subnet_id              = each.value.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.sg_vpc_main.id]
  tags = {
    Name    = each.key
    Project = var.project_name
  }
}


# ---------- S3 BUCKET ----------
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "s3_bucket" {
  count = var.create_s3_bucket ? 1 : 0 # Conditional ternari structure. 
  # Bucket name must be unique in the whole AWS structure so we use a random_id generator to avoid issues.
  bucket = "${var.project_name}-bucket-${random_id.suffix.hex}"
  tags = {
    Name = "${var.project_name}_s3_bucket"
    Project = var.project_name
  }
}







