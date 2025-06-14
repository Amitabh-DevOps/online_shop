# ============================================================================
# Online Shop Infrastructure - Main Configuration
# ============================================================================

# Note: Terraform version and provider requirements are defined in versions.tf

terraform {
  # Uncomment and configure for remote state management
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "online-shop/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

# ============================================================================
# Provider Configuration
# ============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "online-shop"
      Environment = var.environment
      ManagedBy   = "terraform"
      Repository  = "online-shop"
      Owner       = "DevOps-Team"
    }
  }
}

# ============================================================================
# Data Sources
# ============================================================================

# Get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get current AWS account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ============================================================================
# Key Pair for EC2 Access
# ============================================================================

# Generate a private key
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS Key Pair
resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${var.project_name}-key-${random_id.suffix.hex}"
  public_key = tls_private_key.ec2_key.public_key_openssh

  tags = {
    Name = "${var.project_name}-key-pair"
  }
}

# Random suffix for unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}

# ============================================================================
# Security Group
# ============================================================================

resource "aws_security_group" "online_shop_sg" {
  name_prefix = "${var.project_name}-sg-"
  description = "Security group for Online Shop application"
  vpc_id      = data.aws_vpc.default.id

  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Consider restricting this to your IP
  }

  # Application port (if needed for direct access)
  ingress {
    description = "Application Port"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-security-group"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# IAM Role for EC2 Instance
# ============================================================================

# IAM role for EC2 instance
resource "aws_iam_role" "ec2_role" {
  name_prefix = "${var.project_name}-ec2-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

# IAM policy for CloudWatch logs and basic EC2 operations
resource "aws_iam_role_policy" "ec2_policy" {
  name_prefix = "${var.project_name}-ec2-policy-"
  role        = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# Instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name_prefix = "${var.project_name}-ec2-profile-"
  role        = aws_iam_role.ec2_role.name

  tags = {
    Name = "${var.project_name}-ec2-instance-profile"
  }
}

# ============================================================================
# User Data Script
# ============================================================================

locals {
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    docker_image       = var.docker_image
    dockerhub_username = var.dockerhub_username
    project_name       = var.project_name
    aws_region         = var.aws_region
  }))
}

# ============================================================================
# EC2 Instance
# ============================================================================

resource "aws_instance" "online_shop" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ec2_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.online_shop_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  subnet_id                   = data.aws_subnets.default.ids[0]
  associate_public_ip_address = true

  user_data = local.user_data

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.project_name}-root-volume"
    }
  }

  tags = {
    Name = "${var.project_name}-instance"
    Type = "web-server"
  }

  lifecycle {
    create_before_destroy = true
  }

  # Wait for instance to be ready
  provisioner "remote-exec" {
    inline = [
      "echo 'Instance is ready for deployment'"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.ec2_key.private_key_pem
      host        = self.public_ip
      timeout     = "5m"
    }
  }
}

# ============================================================================
# CloudWatch Log Group (Optional)
# ============================================================================

resource "aws_cloudwatch_log_group" "online_shop_logs" {
  name              = "/aws/ec2/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-logs"
  }
}

# ============================================================================
# Outputs
# ============================================================================

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.online_shop.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.online_shop.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.online_shop.public_dns
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.online_shop_sg.id
}

output "key_pair_name" {
  description = "Name of the key pair"
  value       = aws_key_pair.ec2_key_pair.key_name
}

output "private_key_pem" {
  description = "Private key in PEM format"
  value       = tls_private_key.ec2_key.private_key_pem
  sensitive   = true
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_instance.online_shop.public_ip}"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${aws_key_pair.ec2_key_pair.key_name}.pem ec2-user@${aws_instance.online_shop.public_ip}"
}
