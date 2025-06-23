# Online Shop Deployment Guide

This document provides comprehensive instructions for deploying the Online Shop application using the automated CI/CD pipeline.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [GitHub Secrets Configuration](#github-secrets-configuration)
4. [Deployment Process](#deployment-process)
5. [Infrastructure Destruction](#infrastructure-destruction)
6. [Monitoring and Logging](#monitoring-and-logging)
7. [Troubleshooting](#troubleshooting)
8. [Best Practices](#best-practices)

## Prerequisites

### Required Accounts and Tools

- **GitHub Account**: Repository access with Actions enabled
- **Docker Hub Account**: For storing container images
- **AWS Account**: With appropriate permissions for EC2, IAM, CloudWatch
- **AWS CLI**: Configured locally (optional, for manual operations)
- **Terraform**: Version 1.5.0 or higher (for local testing)

### AWS Permissions Required

Your AWS user/role needs the following permissions:
- EC2 full access (launch, terminate, modify instances)
- IAM role creation and management
- CloudWatch logs and metrics
- VPC and Security Group management
- Key Pair management

## Initial Setup

### 1. Repository Setup

Clone the repository and ensure all files are in place:

```bash
git clone https://github.com/your-username/online-shop.git
cd online-shop
```

### 2. Docker Hub Token

Create a Docker Hub access token:
1. Log in to Docker Hub
2. Go to Account Settings > Security
3. Create a new access token
4. Save the token securely

### 3. AWS Credentials

Ensure you have AWS credentials with the required permissions:
- AWS Access Key ID
- AWS Secret Access Key

## GitHub Secrets Configuration

Configure the following secrets in your GitHub repository:

### Required Secrets

Navigate to: `Repository Settings > Secrets and variables > Actions`

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key ID | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `DOCKER_HUB_TOKEN` | Docker Hub access token | `dckr_pat_1234567890abcdef` |

### Verification

Verify secrets are properly configured:
1. Go to repository Settings
2. Click on "Secrets and variables" > "Actions"
3. Confirm all three secrets are listed

## Deployment Process

### Automatic Deployment

The deployment is triggered automatically on:
- Push to `main` or `master` branch
- Manual workflow dispatch

### Deployment Stages

#### Stage 1: Build and Push Docker Image
- Generates semantic version (v1.0.0, v1.0.1, etc.)
- Builds multi-architecture Docker image (AMD64, ARM64)
- Pushes to Docker Hub with version tags
- Creates Git tag for the release

#### Stage 2: Infrastructure Deployment
- Initializes Terraform
- Plans infrastructure changes
- Applies Terraform configuration
- Creates EC2 instance with security groups
- Sets up IAM roles and CloudWatch logging

#### Stage 3: Application Deployment
- Installs Docker on EC2 instance
- Pulls the Docker image
- Starts the application container
- Configures monitoring and logging

#### Stage 4: Health Verification
- Waits for application startup
- Performs health checks
- Verifies application accessibility
- Reports deployment status

### Manual Deployment

To trigger deployment manually:
1. Go to repository Actions tab
2. Select "Deploy Online Shop" workflow
3. Click "Run workflow"
4. Select branch and click "Run workflow"

### Monitoring Deployment

Monitor deployment progress:
1. Go to repository Actions tab
2. Click on the running workflow
3. Expand each job to see detailed logs
4. Check for any errors or warnings

## Infrastructure Destruction

### Safety Measures

The destroy workflow includes multiple safety checks:
- Manual trigger only (no automatic destruction)
- Confirmation input required
- Pre-destruction backup creation
- Resource verification

### Destruction Process

1. Go to repository Actions tab
2. Select "Destroy Infrastructure" workflow
3. Click "Run workflow"
4. Enter "DESTROY" in the confirmation field
5. Select environment (production/staging/development)
6. Click "Run workflow"

### Post-Destruction Verification

After destruction:
- Check AWS console for remaining resources
- Verify no unexpected charges
- Review destruction report in workflow artifacts

## Monitoring and Logging

### CloudWatch Integration

The deployment automatically sets up:
- **Log Groups**: `/aws/ec2/online-shop`
- **Metrics**: CPU, Memory, Disk utilization
- **Alarms**: High CPU usage, Instance health

### Available Logs

| Log Stream | Content |
|------------|---------|
| `user-data` | Instance initialization logs |
| `docker` | Docker container logs |
| `application` | Application-specific logs |

### Accessing Logs

1. AWS Console > CloudWatch > Log groups
2. Select `/aws/ec2/online-shop`
3. Choose appropriate log stream
4. View real-time logs

### Metrics Dashboard

View metrics in CloudWatch:
1. AWS Console > CloudWatch > Dashboards
2. Create custom dashboard
3. Add widgets for EC2 metrics

## Troubleshooting

### Common Issues

#### Deployment Failures

**Issue**: Docker image build fails
- **Solution**: Check Dockerfile syntax and dependencies
- **Logs**: GitHub Actions build logs

**Issue**: Terraform apply fails
- **Solution**: Verify AWS permissions and resource limits
- **Logs**: Terraform plan output in workflow

**Issue**: Health check fails
- **Solution**: Check application startup time and port configuration
- **Logs**: EC2 instance user-data logs

#### Application Issues

**Issue**: Application not accessible
- **Solution**: 
  - Verify security group rules
  - Check application port (3000)
  - Confirm public IP assignment

**Issue**: High resource usage
- **Solution**:
  - Monitor CloudWatch metrics
  - Consider instance type upgrade
  - Check for memory leaks

### Debug Commands

SSH into EC2 instance (if needed):
```bash
# Get private key from Terraform output
terraform output -raw private_key_pem > private_key.pem
chmod 600 private_key.pem

# SSH to instance
ssh -i private_key.pem ec2-user@<public-ip>
```

Check application status:
```bash
# On EC2 instance
docker ps
docker logs online-shop-app
systemctl status online-shop
```

### Log Analysis

Common log locations on EC2:
- `/var/log/user-data.log` - Instance setup
- `/var/log/docker.log` - Docker operations
- `/var/log/application.log` - Application logs

## Best Practices

### Security

1. **Secrets Management**
   - Rotate AWS credentials regularly
   - Use least-privilege IAM policies
   - Monitor access logs

2. **Network Security**
   - Restrict SSH access to specific IPs when possible
   - Use HTTPS in production
   - Implement Web Application Firewall (WAF)

3. **Instance Security**
   - Keep AMI updated
   - Enable encryption for EBS volumes
   - Regular security patches

### Cost Optimization

1. **Instance Management**
   - Use appropriate instance types
   - Implement auto-shutdown for non-production
   - Monitor usage patterns

2. **Resource Cleanup**
   - Regular cleanup of unused resources
   - Automated backup retention policies
   - Monitor CloudWatch costs

### Operational Excellence

1. **Monitoring**
   - Set up meaningful alerts
   - Regular health checks
   - Performance monitoring

2. **Backup and Recovery**
   - Regular AMI snapshots
   - Database backups (if applicable)
   - Disaster recovery procedures

3. **Documentation**
   - Keep deployment docs updated
   - Document configuration changes
   - Maintain runbooks

### Development Workflow

1. **Version Control**
   - Use semantic versioning
   - Tag releases properly
   - Maintain changelog

2. **Testing**
   - Test deployments in staging
   - Automated testing in CI/CD
   - Load testing for production

3. **Rollback Strategy**
   - Keep previous versions available
   - Quick rollback procedures
   - Database migration rollbacks

## Support and Maintenance

### Regular Tasks

- **Weekly**: Review CloudWatch metrics and logs
- **Monthly**: Update dependencies and security patches
- **Quarterly**: Review and optimize costs

### Emergency Procedures

1. **Application Down**
   - Check health check endpoints
   - Review recent deployments
   - Check resource utilization

2. **High Costs**
   - Review resource usage
   - Check for runaway processes
   - Verify auto-scaling settings

### Getting Help

- **GitHub Issues**: Report bugs and feature requests
- **AWS Support**: For infrastructure issues
- **Community**: Stack Overflow, AWS forums

---

For additional support or questions, please refer to the project's GitHub repository or contact the development team.
