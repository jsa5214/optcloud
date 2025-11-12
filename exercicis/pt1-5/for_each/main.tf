# ---------- LOCALS ----------
# Locals allow you to define intermediate values to reuse throughout the configuration.
# They don't create resources by themselves.
# They are commonly used to build complex structures such as lists or maps that will be used later in resources.

locals {
  # List containing all Availability Zones within the region
  azs = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f"]

  # Map that defines the public subnets.
  # To generate a map: map_key => value // {map_key = value}
  # The for-expression dynamically generates a map in the format:
  # {
  #   "public-us-east-1a" = { cidr = "10.0.0.0/24", az = "us-east-1a" },
  #   "public-us-east-1b" = { cidr = "10.0.1.0/24", az = "us-east-1b" }
  # }
  # Each key corresponds to one subnet, and each value is an object containing its CIDR and AZ.
  public_subnets = {
    for i in range(var.subnet_count) :
    "public_${i + 1}_${element(local.azs, i)}" => {
      cidr = cidrsubnet(var.vpc_cidr, 8, i)
      # To avoid 'index out of range' errors, use the element function or the % operator
      az = element(local.azs, i)
      #   az   = local.azs[i % length(local.azs)]
    }
  }

  # Same logic as above but for private subnets.
  # The index is offset by +var.subnet_count to ensure that the CIDR ranges don't overlap with the public ones.
  private_subnets = {
    for i in range(var.subnet_count) :
    "private_${i + 1}_${element(local.azs, i)}" => {
      cidr = cidrsubnet(var.vpc_cidr, 8, i + var.subnet_count)
      az   = element(local.azs, i)
      #   az   = local.azs[i % length(local.azs)]
    }
  }

  # Nested for loops generate a list of lists of objects.
  # Each object represents an EC2 instance configuration for a given subnet.
  # Because for_each cannot iterate over lists of lists, flatten() merges them into a single list.
  # Example: flatten([[1,2],[3,4]]) -> [1,2,3,4]
  public_instances = flatten([
    for subnet_key, subnet in aws_subnet.public_subnet : [
      for i in range(var.instance_count) : {
        key       = "${subnet_key}_${i + 1}"
        subnet_id = subnet.id
      }
    ]
  ])
  # After the flatten, each element in the list represents a single EC2 instance:
  # [                                                             to    [
  #   [ {key="public-us-east-1a-1", subnet_id="...", number=1},           {key="public-us-east-1a-1", subnet_id="...", number=1},
  #     {key="public-us-east-1a-2", subnet_id="...", number=2} ],         {key="public-us-east-1a-2", subnet_id="...", number=2},
  #   [ {key="public-us-east-1b-1", subnet_id="...", number=1},           {key="public-us-east-1b-1", subnet_id="...", number=1},
  #     {key="public-us-east-1b-2", subnet_id="...", number=2} ]          {key="public-us-east-1b-2", subnet_id="...", number=2}
  # ]                                                                   ]
  # Each object contains its unique key, the subnet ID where it will be deployed, and an internal counter.

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
# Public subnets definition.
# for_each iterates over the local map created above (local.public_subnets).
# Each element in the map represents one subnet and provides its CIDR and Availability Zone.
resource "aws_subnet" "public_subnet" {
  for_each                = local.public_subnets
  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.value.az
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = true # Ensures instances launched here receive a public IP automatically.
  tags = {
    Name    = "${var.project_name}_${each.key}"
    Project = var.project_name
  }
}

# Private subnets use the same logic, except that map_public_ip_on_launch is not set to true.
# This keeps them isolated from the public Internet.
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
# Associates each public subnet with the routing table above.
# This ensures that instances inside those subnets can reach the Internet.
resource "aws_route_table_association" "rta" {
  for_each       = aws_subnet.public_subnet
  route_table_id = aws_route_table.rt_tbl.id
  subnet_id      = each.value.id

  # Must create the dependencies first so it doesn't create them in paral·lel and lead to errors.
  depends_on = [
    aws_internet_gateway.igw,
    aws_route_table.rt_tbl
  ]

}

# ---------- SECURITY GROUP ----------
# Security Group defining the inbound and outbound rules for all EC2 instances.
# - Allows HTTP from anywhere (port 80)
# - Allows SSH only from a specified IP (var.my_ip)
# - Allows ICMP (ping) only within the VPC range
# - Allows all outbound traffic
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
    description = "Allow any outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------- EC2 INSTANCES ----------
# Each instance is created using for_each based on the local.public_instances list.
# A map comprehension converts the list of objects into a map where:
# - The key is obj.key (unique identifier for each instance)
# - The value is the entire object (containing subnet_id and other fields)
# This allows for easy referencing with each.key and each.value.<attribute>.
#
# obj format example:
#   {
#   "public-us-east-1a-1" = {subnet_id="...", number=1, key="..."},
#   "public-us-east-1a-2" = {subnet_id="...", number=2, key="..."},
#   "public-us-east-1b-1" = {subnet_id="...", number=1, key="..."},
#   "public-us-east-1b-2" = {subnet_id="...", number=2, key="..."}
#   }
resource "aws_instance" "ec2_public" {
  for_each               = { for obj in local.public_instances : obj.key => obj }
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

# Same logic as the public instances, but deployed in private subnets.
# These instances have no public IPs and are intended for internal-only workloads.
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
# Random ID is generated to ensure the bucket name is globally unique.
resource "random_id" "suffix" {
  byte_length = 4
}

# S3 bucket creation is conditional.
# If var.create_s3_bucket = true, it will create one bucket with a random suffix.
resource "aws_s3_bucket" "s3_bucket" {
  count  = var.create_s3_bucket ? 1 : 0 # Conditional ternari structure. 
  bucket = "${var.project_name}-bucket-${random_id.suffix.hex}"
  tags = {
    Name    = "${var.project_name}_s3_bucket"
    Project = var.project_name
  }
}







