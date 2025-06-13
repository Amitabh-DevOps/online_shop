variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name of the EC2 Key Pair"
  type        = string
  default     = "online-shop-key"
}

variable "public_key" {
  description = "Public key for EC2 access"
  type        = string
}

variable "docker_image" {
  description = "Docker image to deploy"
  type        = string
}
