# Outputs for Online Shop Terraform configuration

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.online_shop.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.online_shop.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.online_shop.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.online_shop.public_dns
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_instance.online_shop.public_ip}:${var.app_port}"
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.online_shop_sg.id
}

output "key_pair_name" {
  description = "Name of the key pair"
  value       = aws_key_pair.online_shop_key.key_name
}

output "private_key_pem" {
  description = "Private key in PEM format for SSH access"
  value       = tls_private_key.online_shop_key.private_key_pem
  sensitive   = true
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.online_shop_logs.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.online_shop_logs.arn
}

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = data.aws_vpc.default.id
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = data.aws_subnets.default.ids[0]
}

output "ami_id" {
  description = "ID of the AMI used"
  value       = data.aws_ami.amazon_linux.id
}

output "cpu_alarm_name" {
  description = "Name of the CPU utilization alarm"
  value       = aws_cloudwatch_metric_alarm.high_cpu.alarm_name
}

output "health_alarm_name" {
  description = "Name of the instance health alarm"
  value       = aws_cloudwatch_metric_alarm.instance_health.alarm_name
}

output "deployment_info" {
  description = "Deployment information summary"
  value = {
    instance_id     = aws_instance.online_shop.id
    public_ip       = aws_instance.online_shop.public_ip
    application_url = "http://${aws_instance.online_shop.public_ip}:${var.app_port}"
    docker_image    = var.docker_image
    app_version     = var.app_version
    environment     = var.environment
    region          = var.aws_region
    deployed_at     = timestamp()
  }
}
