variable "region" {
  type        = string
  description = "AWS region (us-east-1 by default)"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "pt1-6"
}
variable "private_instance_count" {
  type        = number
  description = "n private subnets"
  default     = 2
}

variable "allowed_ip" {
  type = string
  description = "Allowed IP for SSH"
  default = "0.0.0.0/0" 
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

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "key_name" {
  type        = string
  description = "SSH Key_Name"
  default     = "vockey"
}
