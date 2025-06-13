# Fetch the latest Ubuntu AMI - using the most reliable approach
data "aws_ami" "ubuntu" {
  owners      = ["099720109477"] # Canonical
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Create an SSH key pair
resource "aws_key_pair" "terraform_key" {
  key_name   = var.aws_key_pair_name
  public_key = file(var.aws_key_pair_public_key)

  tags = {
    Name        = var.aws_key_pair_name
    Environment = "production"
    Project     = "online-shop"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

# Get the default VPC for the region
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

# Create a security group with improved security
resource "aws_security_group" "terraform_sg" {
  name_prefix = "${var.aws_sg_name}-"
  description = var.aws_sg_description
  vpc_id      = data.aws_vpc.default.id

  # SSH access (consider restricting this to your IP)
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  # HTTP access
  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.http_cidr]
  }

  # HTTPS access
  ingress {
    description = "HTTPS access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.https_cidr]
  }

  # Application port (for development/testing)
  ingress {
    description = "Application port"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.app_cidr]
  }

  # Outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = var.aws_sg_name
    Environment = "production"
    Project     = "online-shop"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes       = [tags]
  }
}

# Create an EC2 instance with improved configuration
resource "aws_instance" "github_action_instance" {
  ami                    = local.final_ami_id
  instance_type          = var.aws_instance_type
  key_name              = aws_key_pair.terraform_key.key_name
  vpc_security_group_ids = [aws_security_group.terraform_sg.id]
  
  # Use a specific subnet for better control
  subnet_id = data.aws_subnets.default.ids[0]
  
  # Enable detailed monitoring
  monitoring = true
  
  # Instance metadata service v2 (more secure)
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 1
  }

  # Root block device configuration
  root_block_device {
    volume_size           = var.aws_instance_storage_size
    volume_type           = var.aws_instance_volume_type
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "${var.aws_instance_name}-root-volume"
    }
  }

  tags = {
    Name        = var.aws_instance_name
    Environment = "production"
    Project     = "online-shop"
    ManagedBy   = "terraform"
  }

  lifecycle {
    ignore_changes = [
      ami,
      tags
    ]
  }
}