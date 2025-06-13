# Alternative AMI configurations for fallback

# Try Ubuntu 22.04 LTS first
data "aws_ami" "ubuntu_22" {
  owners      = ["099720109477"] # Canonical
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-lts-amd64-server-*"]
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
}

# Fallback to Ubuntu 20.04 LTS
data "aws_ami" "ubuntu_20" {
  owners      = ["099720109477"] # Canonical
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-20.04-lts-amd64-server-*"]
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
}

# Output available AMIs for debugging
output "available_ubuntu_22_ami" {
  value = {
    id   = try(data.aws_ami.ubuntu_22.id, "not-found")
    name = try(data.aws_ami.ubuntu_22.name, "not-found")
  }
  description = "Ubuntu 22.04 LTS AMI information"
}

output "available_ubuntu_20_ami" {
  value = {
    id   = try(data.aws_ami.ubuntu_20.id, "not-found")
    name = try(data.aws_ami.ubuntu_20.name, "not-found")
  }
  description = "Ubuntu 20.04 LTS AMI information"
}
