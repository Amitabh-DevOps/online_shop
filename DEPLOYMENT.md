# 🚀 Modern CI/CD Deployment Guide

This document explains the modern, clean CI/CD pipeline implementation for the Online Shop application.

## 🏗️ Architecture Overview

### Infrastructure Components
- **S3 Bucket**: Terraform state storage with versioning and encryption
- **DynamoDB Table**: Terraform state locking
- **EC2 Instance**: Application server with Ubuntu 22.04 LTS
- **Elastic IP**: Static IP address for the application
- **Security Group**: Firewall rules for HTTP, HTTPS, SSH, and application ports
- **Key Pair**: SSH access to the EC2 instance

### CI/CD Pipeline
1. **Setup Backend**: Creates S3 and DynamoDB for Terraform state
2. **Build Image**: Builds and pushes Docker image to DockerHub
3. **Deploy Infrastructure**: Provisions AWS resources using Terraform
4. **Deploy Application**: Deploys Docker container to EC2
5. **Health Check**: Verifies application is running correctly
6. **Notify**: Sends email notification with deployment status

## 📁 Project Structure

```
online-shop/
├── .github/workflows/
│   ├── deploy.yml          # Main deployment pipeline
│   └── destroy.yml         # Infrastructure destruction
├── infrastructure/
│   ├── backend/            # Terraform backend resources
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── main/               # Main infrastructure
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── user_data.sh
│       └── backend.hcl
├── scripts/
│   ├── deploy.sh           # Application deployment script
│   └── setup-backend.sh   # Backend setup script
├── Dockerfile              # Application container
├── SECRETS_SETUP.md        # GitHub secrets configuration
└── DEPLOYMENT.md           # This file
```

## 🔧 Setup Instructions

### 1. Configure GitHub Secrets
Follow the [SECRETS_SETUP.md](SECRETS_SETUP.md) guide to configure all required secrets.

### 2. Customize Configuration
Update the following files if needed:
- `infrastructure/main/variables.tf` - Instance type, region, etc.
- `.github/workflows/deploy.yml` - Workflow configuration

### 3. Deploy
Push to the `master` branch to trigger the deployment pipeline.

## 🚀 Deployment Process

### Automatic Deployment
```bash
git add .
git commit -m "Deploy application"
git push origin master
```

### Manual Backend Setup (if needed)
```bash
./scripts/setup-backend.sh my-state-bucket my-locks-table eu-west-1
```

### Manual Application Deployment (if needed)
```bash
./scripts/deploy.sh username/online-shop:latest 1.2.3.4 ~/.ssh/key.pem
```

## 🔥 Destruction Process

### Via GitHub Actions
1. Go to **Actions** → **Destroy Infrastructure**
2. Click **Run workflow**
3. Type `destroy` to confirm
4. Click **Run workflow**

### Manual Destruction
```bash
# Destroy main infrastructure
cd infrastructure/main
terraform destroy

# Destroy backend (after emptying S3 bucket)
cd ../backend
terraform destroy
```

## 📊 Monitoring & Logs

### Application Logs
```bash
# SSH to EC2 instance
ssh -i your-key.pem ubuntu@your-instance-ip

# View application logs
docker logs online-shop

# View system logs
sudo journalctl -u online-shop.service
```

### Health Check
```bash
# Manual health check
curl http://your-instance-ip

# Automated health check script
/opt/online-shop/health-check.sh
```

## 🔒 Security Features

- **Encrypted EBS volumes**
- **Security groups with minimal required ports**
- **SSH key-based authentication**
- **S3 bucket encryption and versioning**
- **Private subnets for sensitive resources**
- **IAM roles with least privilege**

## 🛠️ Troubleshooting

### Common Issues

#### Deployment Fails
1. Check GitHub Actions logs
2. Verify all secrets are configured
3. Check AWS credentials and permissions
4. Verify Docker image exists in DockerHub

#### Application Not Accessible
1. Check security group rules
2. Verify EC2 instance is running
3. Check application logs: `docker logs online-shop`
4. Verify health check: `curl http://instance-ip`

#### Terraform State Issues
1. Check S3 bucket exists and is accessible
2. Verify DynamoDB table exists
3. Check AWS credentials have proper permissions
4. Review Terraform logs in GitHub Actions

### Debug Commands
```bash
# Check EC2 instance status
aws ec2 describe-instances --instance-ids i-1234567890abcdef0

# Check S3 bucket
aws s3 ls s3://your-state-bucket

# Check DynamoDB table
aws dynamodb describe-table --table-name your-locks-table

# Test SSH connection
ssh -i your-key.pem ubuntu@your-instance-ip "echo 'Connection successful'"
```

## 📈 Performance Optimization

### Instance Sizing
- **t3.micro**: Development/testing (1 vCPU, 1GB RAM)
- **t3.small**: Light production (2 vCPU, 2GB RAM)
- **t3.medium**: Production (2 vCPU, 4GB RAM)

### Cost Optimization
- Use **Spot Instances** for development
- Enable **detailed monitoring** only when needed
- Set up **auto-scaling** for production workloads
- Use **reserved instances** for long-term deployments

## 🔄 CI/CD Best Practices

### Implemented Features
- ✅ **Infrastructure as Code** with Terraform
- ✅ **Containerized applications** with Docker
- ✅ **Automated testing** and deployment
- ✅ **State management** with S3 and DynamoDB
- ✅ **Email notifications** for deployment status
- ✅ **Health checks** and monitoring
- ✅ **Secure secret management**
- ✅ **Rollback capabilities**

### Recommended Enhancements
- [ ] **Multi-environment support** (dev, staging, prod)
- [ ] **Blue-green deployments**
- [ ] **Automated testing** integration
- [ ] **Container scanning** for security
- [ ] **Infrastructure drift detection**
- [ ] **Cost monitoring** and alerts

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review GitHub Actions logs
3. Check AWS CloudWatch logs
4. Create an issue in the repository

## 🎉 Success!

Once deployed, your application will be available at:
- **Application URL**: `http://your-instance-ip`
- **Health Check**: `http://your-instance-ip/health` (if implemented)

You'll receive email notifications for all deployment activities!
