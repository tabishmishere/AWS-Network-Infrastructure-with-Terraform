variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used for naming all resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnet_cidrs" {
  description = "Map of subnet name => CIDR block"
  type        = map(string)
}

variable "my_ip" {
  description = "Public IP (without /32) allowed to SSH"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the bastion"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the AWS key pair to create"
  type        = string
}

variable "public_key_path" {
  description = "Path to your SSH public key"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}