# 🚀 CI/CD Setup Guide for Online Shop

This guide will help you set up a complete CI/CD pipeline for the Online Shop project using GitHub Actions, Terraform, and AWS.

## 📋 Table of Contents

- [Overview](#-overview)
- [Prerequisites](#-prerequisites)
- [Quick Setup](#-quick-setup)
- [Manual Setup](#-manual-setup)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [Troubleshooting](#-troubleshooting)
- [Security Best Practices](#-security-best-practices)
- [Cost Optimization](#-cost-optimization)

## 🎯 Overview

The CI/CD pipeline consists of two main workflows:

### 🔧 Deploy Workflow (`deploy.yml`)
- **Trigger**: Push to `final` branch
- **Actions**: Build Docker image → Provision AWS infrastructure → Deploy application
- **Result**: Running application on AWS EC2

### 🗑️ Destroy Workflow (`destroy.yml`)
- **Trigger**: Manual dispatch only
- **Actions**: Backup state → Destroy all AWS resources
- **Result**: Clean AWS account with no running resources

## 🛠️ Prerequisites

### Required Tools
- [Git](https://git-scm.com/) - Version control
- [AWS CLI](https://aws.amazon.com/cli/) - AWS command line interface
- [Terraform](https://www.terraform.io/) - Infrastructure as Code
- [Docker](https://www.docker.com/) - Containerization
- [GitHub CLI](https://cli.github.com/) (optional) - For automated secret setup

### Required Accounts
- **GitHub Account** - For repository and CI/CD
- **AWS Account** - For infrastructure hosting
- **Docker Hub Account** - For container registry

### Installation Commands

#### macOS (using Homebrew)
```bash
brew install git awscli terraform docker gh
```

#### Ubuntu/Debian
```bash
# Git
sudo apt update && sudo apt install git

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Docker
sudo apt install docker.io
sudo systemctl start docker
sudo usermod -aG docker $USER

# GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh
```

#### Windows (using Chocolatey)
```powershell
choco install git awscli terraform docker-desktop gh
```

## ⚡ Quick Setup

### Option 1: Automated Setup Script
```bash
# Run the setup script
./scripts/setup-cicd.sh
```

The script will:
- ✅ Check all prerequisites
- 🐙 Setup GitHub repository and branches
- ☁️ Configure AWS credentials
- 🐳 Setup Docker Hub integration
- 🏗️ Validate Terraform configuration
- 🔐 Configure GitHub Secrets (if GitHub CLI is available)

### Option 2: One-Command Setup
```bash
# Clone, setup, and deploy in one go
git clone https://github.com/your-username/online-shop.git
cd online-shop
./scripts/setup-cicd.sh
git checkout final
git push origin final
```

## 🔧 Manual Setup

If you prefer to set up everything manually:

### 1. Configure AWS CLI
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your default region (e.g., us-east-1)
# Enter output format (json)
```

### 2. Create Docker Hub Access Token
1. Go to [Docker Hub](https://hub.docker.com/)
2. Sign in to your account
3. Go to Account Settings → Security
4. Click "New Access Token"
5. Give it a name (e.g., "github-actions")
6. Copy the generated token

### 3. Setup GitHub Repository
```bash
# Create and push to final branch
git checkout -b final
git push -u origin final
git checkout main
```

### 4. Configure GitHub Secrets
Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these repository secrets:
- `AWS_ACCESS_KEY_ID`: Your AWS access key ID
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key
- `DOCKERHUB_USERNAME`: Your Docker Hub username
- `DOCKERHUB_TOKEN`: Your Docker Hub access token
- `EC2_SSH_PRIVATE_KEY`: SSH private key (generate with `ssh-keygen -t rsa -b 4096`)

### 5. Validate Terraform
```bash
cd terraform
terraform init
terraform validate
terraform fmt
cd ..
```

## ⚙️ Configuration

### Environment Variables

Edit `.github/workflows/deploy.yml` to customize:

```yaml
env:
  AWS_REGION: us-east-1          # Your preferred AWS region
  DOCKER_IMAGE_NAME: online-shop  # Your Docker image name
  EC2_INSTANCE_TYPE: t3.micro    # Instance type (t3.micro for free tier)
  TERRAFORM_VERSION: 1.6.0       # Terraform version
```

### Terraform Variables

Edit `terraform/variables.tf` or create `terraform/terraform.tfvars`:

```hcl
# terraform/terraform.tfvars
aws_region                    = "us-west-2"
environment                   = "production"
instance_type                 = "t3.small"
allowed_cidr_blocks          = ["0.0.0.0/0"]  # Restrict for security
enable_detailed_monitoring   = true
root_volume_size             = 30
```

### Security Group Customization

To restrict access to specific IPs, modify `terraform/main.tf`:

```hcl
# Allow SSH only from your IP
ingress {
  description = "SSH"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["YOUR.IP.ADDRESS/32"]  # Replace with your IP
}
```

## 🚀 Usage

### Deploy Application

#### Method 1: Push to Final Branch
```bash
git checkout final
git merge main  # Merge your latest changes
git push origin final
```

#### Method 2: Manual Trigger
1. Go to GitHub Actions tab
2. Select "🚀 Deploy Infrastructure & Application"
3. Click "Run workflow"
4. Select `final` branch
5. Click "Run workflow"

### Monitor Deployment
1. Go to GitHub Actions tab
2. Click on the running workflow
3. Monitor each step's progress
4. Check the deployment summary for access URLs

### Access Your Application
After successful deployment:
- **Application URL**: `http://<instance-ip>` (shown in workflow output)
- **Health Check**: `http://<instance-ip>/health`
- **SSH Access**: Use the command shown in workflow output

### Destroy Infrastructure
⚠️ **Warning**: This will permanently delete all AWS resources!

1. Go to GitHub Actions tab
2. Select "🗑️ Destroy Infrastructure"
3. Click "Run workflow"
4. Type "DESTROY" in the confirmation field
5. Optionally enable "Force destroy"
6. Click "Run workflow"

## 🐛 Troubleshooting

### Common Issues and Solutions

#### 1. Docker Build Fails
```bash
# Check Dockerfile syntax
docker build -t test .

# Common fixes:
# - Ensure all dependencies are in package.json
# - Check for correct file paths
# - Verify base image availability
```

#### 2. AWS Permission Errors
```bash
# Check your AWS credentials
aws sts get-caller-identity

# Verify required permissions:
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::ACCOUNT:user/USERNAME \
  --action-names ec2:RunInstances ec2:DescribeInstances \
  --resource-arns "*"
```

#### 3. Terraform Apply Fails
```bash
# Check Terraform logs
export TF_LOG=DEBUG
terraform apply

# Common fixes:
# - Verify AWS region availability
# - Check resource limits/quotas
# - Ensure unique resource names
```

#### 4. Application Not Accessible
```bash
# SSH into instance
ssh -i key.pem ec2-user@<instance-ip>

# Check container status
sudo docker ps
sudo docker logs online-shop

# Check security group
aws ec2 describe-security-groups --group-ids <sg-id>
```

#### 5. GitHub Actions Secrets Issues
```bash
# Verify secrets are set
gh secret list

# Update a secret
gh secret set SECRET_NAME --body "new-value"
```

### Debug Commands

#### Check Infrastructure Status
```bash
# List EC2 instances
aws ec2 describe-instances --filters "Name=tag:Project,Values=online-shop"

# Check security groups
aws ec2 describe-security-groups --filters "Name=tag:Project,Values=online-shop"

# View CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix "/aws/ec2/online-shop"
```

#### Application Debugging
```bash
# SSH into instance
ssh -i ~/.ssh/id_rsa ec2-user@<instance-ip>

# Check system status
/opt/online-shop/system-info.sh

# View application logs
sudo docker logs online-shop --tail 100

# Check nginx status
sudo systemctl status nginx

# Test local connectivity
curl http://localhost
```

## 🔒 Security Best Practices

### 1. Network Security
```hcl
# Restrict SSH access to your IP only
variable "my_ip" {
  description = "Your public IP address"
  type        = string
  default     = "YOUR.IP.ADDRESS/32"
}

# Use in security group
cidr_blocks = [var.my_ip]
```

### 2. IAM Security
- Use least privilege principle
- Rotate access keys regularly
- Consider using IAM roles instead of access keys
- Enable MFA on AWS account

### 3. Secrets Management
```bash
# Use GitHub environment secrets for production
# Rotate Docker Hub tokens regularly
# Use AWS Secrets Manager for application secrets
```

### 4. Infrastructure Security
```hcl
# Enable encryption
root_block_device {
  encrypted = true
}

# Use private subnets for production
# Implement VPC with NAT Gateway
# Enable VPC Flow Logs
```

### 5. Monitoring and Alerting
```bash
# Set up CloudWatch alarms
aws cloudwatch put-metric-alarm \
  --alarm-name "HighCPUUtilization" \
  --alarm-description "Alarm when CPU exceeds 70%" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 70 \
  --comparison-operator GreaterThanThreshold
```

## 💰 Cost Optimization

### 1. Instance Right-Sizing
```hcl
# Start with t3.micro (free tier eligible)
instance_type = "t3.micro"

# Monitor and adjust based on usage
# Use CloudWatch metrics to determine optimal size
```

### 2. Storage Optimization
```hcl
# Use GP3 for better price/performance
root_block_device {
  volume_type = "gp3"
  volume_size = 20  # Start small, expand if needed
}
```

### 3. Scheduled Shutdown
```bash
# Add to user data for development environments
echo "0 18 * * 1-5 /sbin/shutdown -h now" | crontab -
```

### 4. Cost Monitoring
```bash
# Set up billing alerts
aws budgets create-budget \
  --account-id ACCOUNT-ID \
  --budget file://budget.json
```

### 5. Resource Cleanup
```bash
# Regular cleanup of unused resources
# Use AWS Config Rules for compliance
# Implement automated resource tagging
```

## 📊 Monitoring and Observability

### CloudWatch Integration
The infrastructure includes:
- **System Metrics**: CPU, Memory, Disk usage
- **Application Logs**: Forwarded to CloudWatch
- **Custom Metrics**: Application-specific metrics

### Health Checks
```bash
# Application health endpoint
curl http://<instance-ip>/health

# System health script
/opt/online-shop/monitor.sh
```

### Log Analysis
```bash
# View application logs
aws logs tail /aws/ec2/online-shop --follow

# Search for errors
aws logs filter-log-events \
  --log-group-name /aws/ec2/online-shop \
  --filter-pattern "ERROR"
```

## 🔄 Advanced Configuration

### Multi-Environment Setup
```yaml
# .github/workflows/deploy-staging.yml
on:
  push:
    branches: [ staging ]

env:
  ENVIRONMENT: staging
  INSTANCE_TYPE: t3.micro
```

### Blue-Green Deployment
```hcl
# terraform/blue-green.tf
resource "aws_lb_target_group" "blue" {
  name = "${var.project_name}-blue"
  # ... configuration
}

resource "aws_lb_target_group" "green" {
  name = "${var.project_name}-green"
  # ... configuration
}
```

### Auto Scaling
```hcl
# terraform/autoscaling.tf
resource "aws_autoscaling_group" "online_shop" {
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.online_shop.arn]
  health_check_type   = "ELB"
  
  min_size         = 1
  max_size         = 3
  desired_capacity = 2
}
```

## 📚 Additional Resources

### Documentation
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EC2 User Guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/)
- [Docker Documentation](https://docs.docker.com/)

### Best Practices
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/)
- [GitHub Actions Security](https://docs.github.com/en/actions/security-guides)

### Community
- [AWS Community](https://aws.amazon.com/developer/community/)
- [Terraform Community](https://discuss.hashicorp.com/c/terraform-core/)
- [GitHub Community](https://github.community/)

## 🤝 Contributing

To contribute to the CI/CD setup:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/cicd-improvement`
3. **Test your changes** in a separate AWS account
4. **Update documentation** as needed
5. **Submit a pull request** with detailed description

### Testing Changes
```bash
# Test Terraform changes
terraform plan -var-file="test.tfvars"

# Test GitHub Actions locally (using act)
act -j build-and-push

# Validate workflows
actionlint .github/workflows/*.yml
```

## 📞 Support

If you encounter issues:

1. **Check the troubleshooting section** above
2. **Review GitHub Actions logs** for detailed error messages
3. **Check AWS CloudTrail** for API call logs
4. **Open an issue** in the repository with:
   - Error messages
   - Steps to reproduce
   - Environment details
   - Relevant logs

---

**Happy Deploying! 🚀**
