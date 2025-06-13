# Deployment Guide

This guide explains how to deploy the Online Shop application using the automated CI/CD pipeline.

## Prerequisites

### 1. AWS Account Setup
- AWS account with appropriate permissions
- AWS Access Key ID and Secret Access Key
- Permissions for EC2, S3, DynamoDB, and IAM

### 2. DockerHub Account
- DockerHub account for storing container images
- DockerHub username and access token

### 3. GitHub Secrets Configuration

Add the following secrets to your GitHub repository:

```
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
DOCKERHUB_USERNAME=your_dockerhub_username
DOCKERHUB_TOKEN=your_dockerhub_token
```

## Architecture Overview

The deployment consists of:

1. **Terraform Backend**: S3 bucket and DynamoDB table for state management
2. **Infrastructure**: EC2 instance with security groups and key pairs
3. **Application**: Dockerized React application deployed to EC2
4. **CI/CD Pipeline**: GitHub Actions workflow for automated deployment

## Deployment Process

### Automatic Deployment

1. **Push to Branch**: Push code to the `github-action` branch
2. **Pipeline Execution**: GitHub Actions automatically:
   - Sets up Terraform backend (S3 + DynamoDB)
   - Provisions EC2 infrastructure
   - Builds and pushes Docker image
   - Deploys application to EC2
   - Performs health checks

### Manual Deployment Steps

If you need to deploy manually:

#### 1. Setup Backend Infrastructure

```bash
cd terraform/terraform_backend
terraform init
terraform plan -var="create_backend=true"
terraform apply -var="create_backend=true"
```

#### 2. Deploy Application Infrastructure

```bash
cd terraform/terraform_resources
terraform init
terraform plan
terraform apply
```

#### 3. Build and Deploy Application

```bash
# Build Docker image
docker build -t your-username/online-shop:latest .

# Push to DockerHub
docker push your-username/online-shop:latest

# Deploy to EC2 (replace IP with your instance IP)
ssh -i terraform/terraform_resources/github-action-key ubuntu@YOUR_EC2_IP
sudo docker pull your-username/online-shop:latest
sudo docker run -d --name online-shop -p 80:3000 --restart unless-stopped your-username/online-shop:latest
```

## Configuration Details

### Environment Variables

The pipeline uses these environment variables:

- `AWS_REGION`: eu-west-1
- `S3_BUCKET`: github-actions-buckets-new
- `DYNAMODB_TABLE`: github-actions-dbs-new

### Infrastructure Components

#### EC2 Instance
- **Type**: t2.medium
- **OS**: Ubuntu 22.04 LTS
- **Storage**: 30GB GP3 encrypted
- **Security**: IMDSv2 enabled

#### Security Group Rules
- SSH (22): Open to all (consider restricting)
- HTTP (80): Open to all
- HTTPS (443): Open to all
- App Port (3000): Open to all

#### S3 Backend
- **Versioning**: Enabled
- **Encryption**: AES256
- **Public Access**: Blocked

## Monitoring and Maintenance

### Health Checks

The pipeline includes automated health checks:
- Application availability on port 80
- Response time monitoring
- Automatic retry logic

### Logs and Monitoring

- Docker container logs: `docker logs online-shop`
- System logs: `/var/log/user-data.log`
- Application health: `/home/ubuntu/health-check.sh`

### Updates and Rollbacks

#### Rolling Updates
1. Push new code to `github-action` branch
2. Pipeline automatically builds and deploys new version
3. Zero-downtime deployment with health checks

#### Manual Rollback
```bash
# SSH to EC2 instance
ssh -i terraform/terraform_resources/github-action-key ubuntu@YOUR_EC2_IP

# Stop current container
sudo docker stop online-shop
sudo docker rm online-shop

# Run previous version
sudo docker run -d --name online-shop -p 80:3000 --restart unless-stopped your-username/online-shop:previous-tag
```

## Cleanup and Destruction

### Automatic Cleanup

Use the destroy workflow:
1. Go to GitHub Actions
2. Run "Destroy All Infrastructure" workflow
3. Enter "destroy" when prompted

### Manual Cleanup

```bash
# Destroy application resources
cd terraform/terraform_resources
terraform destroy

# Destroy backend resources
cd terraform/terraform_backend
terraform destroy -var="create_backend=true"

# Clean up S3 bucket contents
aws s3 rm s3://github-actions-buckets-new --recursive
```

## Troubleshooting

### Common Issues

#### 1. S3 Bucket Region Mismatch
**Error**: `requested bucket from "eu-west-1", actual location "us-east-2"`
**Solution**: Ensure all configurations use the same region (eu-west-1)

#### 2. DynamoDB Table Parameter Deprecated
**Warning**: `dynamodb_table parameter is deprecated`
**Solution**: Updated to use latest Terraform AWS provider

#### 3. SSH Key Permissions
**Error**: SSH connection refused
**Solution**: Ensure key file has correct permissions: `chmod 400 github-action-key`

#### 4. Docker Permission Denied
**Error**: Permission denied while trying to connect to Docker daemon
**Solution**: User data script adds ubuntu user to docker group

### Debug Commands

```bash
# Check EC2 instance status
aws ec2 describe-instances --region eu-west-1

# Check S3 bucket
aws s3 ls s3://github-actions-buckets-new

# Check DynamoDB table
aws dynamodb describe-table --table-name github-actions-dbs-new --region eu-west-1

# SSH to instance and check logs
ssh -i terraform/terraform_resources/github-action-key ubuntu@YOUR_EC2_IP
sudo docker logs online-shop
```

## Security Considerations

### Current Security Measures
- Encrypted EBS volumes
- IMDSv2 enabled
- Security groups with specific port access
- Private key authentication

### Recommended Improvements
- Restrict SSH access to specific IP ranges
- Use AWS Systems Manager Session Manager instead of SSH
- Implement AWS WAF for web application protection
- Use AWS Certificate Manager for HTTPS
- Enable VPC Flow Logs
- Implement AWS Config for compliance monitoring

## Cost Optimization

### Current Costs (Approximate)
- EC2 t2.medium: ~$30/month
- EBS GP3 30GB: ~$3/month
- S3 storage: <$1/month
- DynamoDB: <$1/month

### Optimization Tips
- Use t3.micro for development/testing
- Enable EC2 Instance Scheduler
- Use Spot Instances for non-production
- Implement auto-scaling for production loads

## Support

For issues or questions:
1. Check GitHub Actions logs
2. Review AWS CloudTrail for API calls
3. Check EC2 instance logs
4. Contact the development team

## Version History

- **v1.0**: Initial deployment setup
- **v1.1**: Updated to latest GitHub Actions versions
- **v1.2**: Enhanced security and monitoring
- **v1.3**: Added comprehensive error handling and health checks
