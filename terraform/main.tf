# Terraform configuration for Online Shop deployment
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
      CreatedAt   = timestamp()
    }
  }
}

# Data source to get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source to get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Data source to get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create a key pair for EC2 access
resource "aws_key_pair" "online_shop_key" {
  key_name   = "${var.project_name}-key-${random_id.key_suffix.hex}"
  public_key = tls_private_key.online_shop_key.public_key_openssh

  tags = {
    Name = "${var.project_name}-key-pair"
  }
}

# Generate private key for EC2 access
resource "tls_private_key" "online_shop_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Random ID for unique resource naming
resource "random_id" "key_suffix" {
  byte_length = 4
}

# Create security group for the application
resource "aws_security_group" "online_shop_sg" {
  name_prefix = "${var.project_name}-sg-"
  description = "Security group for Online Shop application"
  vpc_id      = data.aws_vpc.default.id

  # HTTP access for the application
  ingress {
    description = "Application Port"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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

# IAM role for EC2 instance
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role-${random_id.key_suffix.hex}"

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

# IAM policy for CloudWatch logging
resource "aws_iam_role_policy" "ec2_cloudwatch_policy" {
  name = "${var.project_name}-cloudwatch-policy"
  role = aws_iam_role.ec2_role.id

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
        Resource = "arn:aws:logs:${var.aws_region}:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile-${random_id.key_suffix.hex}"
  role = aws_iam_role.ec2_role.name

  tags = {
    Name = "${var.project_name}-ec2-profile"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "online_shop_logs" {
  name              = "/aws/ec2/${var.project_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-log-group"
  }
}

# EC2 Instance
resource "aws_instance" "online_shop" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.online_shop_key.key_name
  vpc_security_group_ids = [aws_security_group.online_shop_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  subnet_id                   = data.aws_subnets.default.ids[0]
  associate_public_ip_address = true

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    docker_image   = var.docker_image
    app_port       = var.app_port
    log_group_name = aws_cloudwatch_log_group.online_shop_logs.name
    aws_region     = var.aws_region
    app_version    = var.app_version
  }))

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true

    tags = {
      Name = "${var.project_name}-root-volume"
    }
  }

  tags = {
    Name = "${var.project_name}-instance"
    Type = "Application Server"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Alarm for high CPU utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = []

  dimensions = {
    InstanceId = aws_instance.online_shop.id
  }

  tags = {
    Name = "${var.project_name}-cpu-alarm"
  }
}

# CloudWatch Alarm for instance status check
resource "aws_cloudwatch_metric_alarm" "instance_health" {
  alarm_name          = "${var.project_name}-instance-health"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This metric monitors instance health"
  alarm_actions       = []

  dimensions = {
    InstanceId = aws_instance.online_shop.id
  }

  tags = {
    Name = "${var.project_name}-health-alarm"
  }
}
