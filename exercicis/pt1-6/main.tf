# ---------- LOCALS ----------
locals {
  azs = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f"]
  private_subnets = {
    for i in range(var.private_instance_count) :
    "private_${i + 1}_${element(local.azs, i)}" => {
      cidr = cidrsubnet(var.vpc_cidr, 8, i + 1) # Offset not to overlap with the bastion CIDR
      # To avoid 'index out of range' errors, use the element function or the % operator
      az   = element(local.azs, i)
    }
  }
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
  vpc_id = aws_vpc.main.id
  availability_zone = local.azs[0]
  cidr_block = "10.0.0.0/24"
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

