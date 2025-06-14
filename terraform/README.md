# 🏗️ Terraform Infrastructure for Online Shop

This directory contains the Terraform configuration for provisioning AWS infrastructure for the Online Shop application.

## 📁 File Structure

```
terraform/
├── main.tf           # Main Terraform configuration
├── variables.tf      # Input variables
├── versions.tf       # Provider version constraints
├── user-data.sh      # EC2 instance initialization script
└── README.md         # This file
```

## 🏗️ Infrastructure Components

### Core Resources
- **EC2 Instance**: Amazon Linux 2023 with Docker pre-installed
- **Security Group**: Configured for HTTP, HTTPS, and SSH access
- **Key Pair**: Auto-generated for secure SSH access
- **IAM Role**: For CloudWatch logging and basic EC2 operations

### Networking
- **VPC**: Uses default VPC for simplicity
- **Subnet**: Uses default public subnet
- **Internet Gateway**: Automatic via default VPC

### Storage
- **Root Volume**: 20GB GP3 encrypted EBS volume
- **CloudWatch Logs**: For application and system logging

### Security
- **IAM Instance Profile**: Least privilege access
- **Security Groups**: Restrictive inbound rules
- **Encrypted Storage**: EBS encryption enabled
- **SSH Key Management**: Auto-generated key pairs

## 🔧 Configuration Variables

### Required Variables
```hcl
docker_image       # Docker image to deploy (e.g., "username/online-shop:latest")
dockerhub_username # Docker Hub username
```

### Optional Variables
```hcl
aws_region                    = "us-east-1"     # AWS region
environment                   = "prod"          # Environment name
project_name                  = "online-shop"   # Project identifier
instance_type                 = "t3.micro"      # EC2 instance type
allowed_cidr_blocks          = ["0.0.0.0/0"]   # Allowed IP ranges
enable_detailed_monitoring   = false            # CloudWatch detailed monitoring
enable_termination_protection = false          # Termination protection
root_volume_size             = 20               # Root volume size in GB
backup_retention_days        = 7                # Log retention period
```

## 🚀 Usage

### Prerequisites
1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.6.0 installed
3. Docker image built and pushed to Docker Hub

### Deployment Commands

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan \
  -var="docker_image=your-username/online-shop:latest" \
  -var="dockerhub_username=your-username"

# Apply the configuration
terraform apply \
  -var="docker_image=your-username/online-shop:latest" \
  -var="dockerhub_username=your-username"

# Destroy the infrastructure
terraform destroy \
  -var="docker_image=your-username/online-shop:latest" \
  -var="dockerhub_username=your-username"
```

### Using Variable Files

Create a `terraform.tfvars` file:
```hcl
aws_region         = "us-west-2"
environment        = "production"
instance_type      = "t3.small"
docker_image       = "myusername/online-shop:v1.0.0"
dockerhub_username = "myusername"
```

Then run:
```bash
terraform apply
```

## 📤 Outputs

After successful deployment, Terraform provides:

```hcl
instance_id          # EC2 instance ID
instance_public_ip   # Public IP address
instance_public_dns  # Public DNS name
security_group_id    # Security group ID
key_pair_name        # SSH key pair name
application_url      # Direct application URL
ssh_command          # SSH connection command
```

## 🔐 Security Considerations

### Network Security
- Security group restricts access to necessary ports only
- Consider using a bastion host for SSH access in production
- Implement VPC with private subnets for enhanced security

### Access Control
- IAM role follows least privilege principle
- SSH key is auto-generated and managed by Terraform
- Consider using AWS Systems Manager Session Manager instead of SSH

### Data Protection
- EBS volumes are encrypted at rest
- Consider implementing backup strategies
- Use AWS Secrets Manager for sensitive configuration

### Monitoring and Logging
- CloudWatch agent installed for system metrics
- Application logs forwarded to CloudWatch
- Consider implementing AWS Config for compliance

## 🔄 State Management

### Local State (Default)
Terraform state is stored locally in `terraform.tfstate`. This is suitable for development but not recommended for production.

### Remote State (Recommended)
Configure S3 backend for production use:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "online-shop/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### State Locking
Use DynamoDB for state locking in team environments:

```bash
# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

## 🧪 Testing

### Validation
```bash
# Validate Terraform configuration
terraform validate

# Format Terraform files
terraform fmt

# Security scanning with tfsec
tfsec .

# Cost estimation with Infracost
infracost breakdown --path .
```

### Integration Testing
```bash
# Test infrastructure provisioning
terraform plan -detailed-exitcode

# Test application deployment
curl -f http://$(terraform output -raw instance_public_ip)
```

## 🔧 Customization

### Instance Types
Modify `instance_type` variable for different performance requirements:
- `t3.micro`: 1 vCPU, 1 GB RAM (Free tier eligible)
- `t3.small`: 2 vCPU, 2 GB RAM
- `t3.medium`: 2 vCPU, 4 GB RAM
- `m5.large`: 2 vCPU, 8 GB RAM

### Multi-AZ Deployment
For high availability, modify the configuration to use multiple availability zones:

```hcl
# Add to main.tf
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_instance" "online_shop" {
  count             = 2
  availability_zone = data.aws_availability_zones.available.names[count.index]
  # ... other configuration
}
```

### Load Balancer
Add Application Load Balancer for production:

```hcl
resource "aws_lb" "online_shop" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids
}
```

## 🐛 Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   # Check AWS credentials
   aws sts get-caller-identity
   
   # Verify IAM permissions
   aws iam get-user
   ```

2. **Resource Already Exists**
   ```bash
   # Import existing resource
   terraform import aws_instance.online_shop i-1234567890abcdef0
   ```

3. **State Lock Issues**
   ```bash
   # Force unlock (use with caution)
   terraform force-unlock LOCK_ID
   ```

4. **Instance Not Accessible**
   ```bash
   # Check security group rules
   aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx
   
   # Verify instance status
   aws ec2 describe-instances --instance-ids i-xxxxxxxxx
   ```

### Debug Mode
Enable Terraform debug logging:
```bash
export TF_LOG=DEBUG
terraform apply
```

## 📊 Cost Optimization

### Resource Sizing
- Use `t3.micro` for development (free tier eligible)
- Monitor CloudWatch metrics to right-size instances
- Consider Spot instances for non-critical workloads

### Storage Optimization
- Use GP3 volumes for better price/performance
- Implement lifecycle policies for logs
- Regular cleanup of unused snapshots

### Monitoring Costs
```bash
# Get cost estimates
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost
```

## 🔄 Maintenance

### Regular Tasks
1. **Update AMI**: Regularly update to latest Amazon Linux AMI
2. **Security Patches**: Keep system packages updated
3. **Backup Verification**: Test backup and restore procedures
4. **Cost Review**: Monthly cost analysis and optimization

### Automation
Consider implementing:
- Automated AMI updates
- Scheduled backups
- Cost alerts
- Security compliance checks

## 📚 Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EC2 Best Practices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-best-practices.html)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)

## 🤝 Contributing

When modifying the Terraform configuration:
1. Follow Terraform style guidelines
2. Update variable descriptions
3. Test changes in a separate environment
4. Document any breaking changes
5. Update this README accordingly
