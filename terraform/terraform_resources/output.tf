output "instance_private_ip" {
  value       = aws_instance.mega_project_instance.private_ip
  description = "The private IP address of the main server instance."
}

output "instance_public_ip" {
  value       = aws_instance.mega_project_instance.public_ip
  description = "The public IP address of the main server instance."
}