# We define the provider as AWS (North Virginia)
provider "aws" {
    region = "us-east-1"
}

# Create EC2 instance
resource "aws_instance" "ex-1" {
    instance_type = "t3.micro"
    ami = "ami-052064a798f08f0d3" # Amazon Linux x86 image (us-east-1)
    count = 2 # Creates 2 EC2 instances

    tags = {
      Name = "Exercici 1 - ${count.index + 1}" # Adds a number to each "same" instance
    }
}

resource "aws_vpc" "main" { # Important to do distinction between the Terraform intern name and the Amazon AWS Name tag
  cidr_block = "10.0.0.0/16" # VPC Network_ID
  tags = { Name = "main-vpc" } # VPC Name
}

resource "aws_subnet" "subnetA" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.32.0/25"
  availability_zone       = "us-east-1a" 
  map_public_ip_on_launch = true # Assign public IP addres auto
  tags = { Name = "SubnetA" }
}

resource "aws_subnet" "subnetB" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.30.0/23"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "SubnetB" }
}

resource "aws_subnet" "subnetC" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.33.0/28"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "SubnetC" }
}