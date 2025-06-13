output "instance_private_ip" {
  value       = aws_instance.github_action_instance.private_ip
  description = "The private IP address of the main server instance."
}

output "instance_public_ip" {
  value       = aws_instance.github_action_instance.public_ip
  description = "The public IP address of the main server instance."
}

output "instance_id" {
  value       = aws_instance.github_action_instance.id
  description = "The ID of the EC2 instance."
}

output "instance_dns" {
  value       = aws_instance.github_action_instance.public_dns
  description = "The public DNS name of the EC2 instance."
}

output "security_group_id" {
  value       = aws_security_group.terraform_sg.id
  description = "The ID of the security group."
}

output "key_pair_name" {
  value       = aws_key_pair.terraform_key.key_name
  description = "The name of the SSH key pair."
}

output "application_url" {
  value       = "http://${aws_instance.github_action_instance.public_ip}"
  description = "The URL to access the deployed application."
}

output "ami_id" {
  value       = data.aws_ami.ubuntu.id
  description = "The AMI ID used for the EC2 instance."
}

output "ami_name" {
  value       = data.aws_ami.ubuntu.name
  description = "The AMI name used for the EC2 instance."
}