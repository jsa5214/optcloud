variable "region" {
  type        = string
  description = "AWS region (us-east-1 by default)"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "pt1-5"
}

variable "instance_count" {
  type        = number
  description = "n instances/subnet"
  default = 2
}

variable "subnet_count" {
  type        = number
  description = "n subnets/vpc"
  default = 2
}

variable "instance_type" {
  type        = string
  description = "Type of instance (t3.micro by default)"
  default     = "t3.micro"
}

variable "instance_ami" {
  type        = string
  description = "AMI ID for the instance (Amazon Linux 2 by default)"
  default     = "ami-052064a798f08f0d3"
}

variable "create_s3_bucket" {
  type        = bool
  description = "Whether to create an S3 bucket or not (false by default)"
  default     = true
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "my_ip" {
  type        = string
  description = "CIDR block for the SSH available connections"
  default     = "0.0.0.0/0"

}
