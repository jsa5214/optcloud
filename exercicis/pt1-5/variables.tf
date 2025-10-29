variable "region" {
    type = string
    default = "us-east-1"
    description = "AWS region (us-east-1 by default)"
} 
variable "project_name" {
    type = string
    description = "Name of the project"
    default = "pt1-5"
}

variable "instance_count" {
    type = number
    description = "n instances/subnet"
}

variable "subnet_count" {
    type = number
    description = "n subnets/vpc"
    default = 2
}

variable "instance_type" {
    type = string
    default = "t3.micro"
    description = "Type of instance (t3.micro by default)"
}

variable "instance_ami" {
    type = string
    default = "ami-052064a798f08f0d3"
    description = "AMI ID for the instance (Amazon Linux 2 by default)"
}

variable "create_s3_bucket" {
    type = bool
    default = false
    description = "Whether to create an S3 bucket or not (false by default)"
}

variable "vpc_cidr" {
    type = string
    default = "10.0.0.0/16"
    description = "CIDR block for the VPC"
}

variable "my_ip" {
    type = string
    default = "0.0.0.0/0"
    description = "CIDR block for the SSH available connections"
}
