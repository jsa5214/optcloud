# We define the provider as AWS (North Virginia)
provider "aws" {
  region = "us-east-1"
}

## Ex 1
# Create EC2 instance
resource "aws_instance" "ex-1" {
  instance_type = "t3.micro"
  ami           = "ami-052064a798f08f0d3" # Amazon Linux x86 image (us-east-1)
  count         = 2                       # Specifies n instances to be created

  tags = {
    Name = "Ex1-Inst-${count.index + 1}" # count.index starts from 0 to n_instances-1
    # Names each instance "Exercici 1 - {n-instance}"
  }
}

## Ex 2

# Create VPC
resource "aws_vpc" "main" {          # Important to distinguish between the Terraform intern name and the Amazon AWS Name tag
  cidr_block = "10.0.0.0/16"         # VPC Network ID
  tags       = { Name = "main-vpc" } # VPC Name
}

# Create Subnets
resource "aws_subnet" "subnetA" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.32.0/25" # Subnet Network ID
  availability_zone = "us-east-1a"   # Specify the AZ
  tags              = { Name = "SubnetA" }
}

resource "aws_subnet" "subnetB" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.30.0/23"
  availability_zone = "us-east-1a"
  tags              = { Name = "SubnetB" }
}

resource "aws_subnet" "subnetC" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.33.0/28"
  availability_zone = "us-east-1a"
  tags              = { Name = "SubnetC" }
}

# Create 6 instances, 2 in each subnet
resource "aws_instance" "subnet-instances" {
  count         = 6
  ami           = "ami-052064a798f08f0d3"
  instance_type = "t3.micro"
  # element(list, index) selects an element from the list at the given index
  subnet_id = element(
    [aws_subnet.subnetA.id, aws_subnet.subnetB.id, aws_subnet.subnetC.id], # list of subnets
    floor(count.index / 2)                                                 # Floors the index/2 (1.9->1). Changes the subnet id every 2 instances.
  )
  tags = {
    Name = "Ex2-Inst-${count.index + 1}"
  }
}