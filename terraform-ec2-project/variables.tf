variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr_block" {
  description = "The CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "The availability zone for the subnet"
  type        = string
  default     = "us-east-1a"
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0c398cb65a93047f2"  # Official Canonical Ubuntu 22.04 LTS AMI
}

variable "instance_user" {
  description = "The user to connect to the EC2 instance"
  type        = string
  default     = "ubuntu"  # This is for Ubuntu instances
}

variable "instance_type" {
  description = "The instance type for the EC2 instance"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "The name of the key pair"
  type        = string
  default     = "deployer-key"
}

variable "private_key_path" {
  description = "The path to save the private key file"
  type        = string
  default     = "./deployer-key.pem"
}