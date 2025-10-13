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

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16" # VPC IP Network
  tags = {
    Name = "VPC-Practica" # VPC Name
  }
}