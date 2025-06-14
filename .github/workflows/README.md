# 🚀 GitHub Actions CI/CD Workflows

This directory contains the GitHub Actions workflows for the Online Shop project's CI/CD pipeline.

## 📁 Workflow Files

### 🔧 `deploy.yml` - Infrastructure Provisioning & Application Deployment

**Trigger**: Push to `final` branch or manual dispatch

**What it does**:
1. **🐳 Build & Push Docker Image**
   - Builds the application Docker image
   - Pushes to Docker Hub with proper tagging
   - Uses build cache for optimization

2. **🏗️ Provision Infrastructure**
   - Uses Terraform to create AWS resources
   - Provisions EC2 instance with security groups
   - Sets up IAM roles and policies
   - Configures networking and storage

3. **🚀 Deploy Application**
   - Connects to EC2 instance via SSH
   - Pulls Docker image from Docker Hub
   - Runs the containerized application
   - Performs health checks

4. **📊 Deployment Summary**
   - Provides comprehensive deployment report
   - Shows all created resources and access URLs

### 🗑️ `destroy.yml` - Infrastructure Teardown

**Trigger**: Manual dispatch only (with confirmation)

**What it does**:
1. **🔍 Validate Destruction Request**
   - Requires typing "DESTROY" to confirm
   - Safety measure to prevent accidental destruction

2. **💾 Pre-Destruction Backup**
   - Exports current Terraform state
   - Creates backup artifacts for recovery

3. **🗑️ Destroy Infrastructure**
   - Uses Terraform to destroy all resources
   - Supports force destroy option
   - Handles resource dependencies properly

4. **✅ Post-Destruction Verification**
   - Verifies all resources are properly cleaned up
   - Generates destruction report

## 🔐 Required GitHub Secrets

Configure these secrets in your GitHub repository settings:

### AWS Credentials
```
AWS_ACCESS_KEY_ID       # Your AWS Access Key ID
AWS_SECRET_ACCESS_KEY   # Your AWS Secret Access Key
```

### Docker Hub Credentials
```
DOCKERHUB_USERNAME      # Your Docker Hub username
DOCKERHUB_TOKEN         # Your Docker Hub access token
```

### SSH Access
```
EC2_SSH_PRIVATE_KEY     # Private key for EC2 SSH access (auto-generated)
```

## 🛠️ Setup Instructions

### 1. Configure AWS Credentials

Create an IAM user with the following permissions:
- EC2 Full Access
- IAM Limited Access (for roles and policies)
- CloudWatch Logs Access

### 2. Configure Docker Hub

1. Create a Docker Hub account
2. Generate an access token
3. Add credentials to GitHub secrets

### 3. Customize Configuration

Edit the environment variables in the workflow files:
- `AWS_REGION`: Your preferred AWS region
- `EC2_INSTANCE_TYPE`: Instance type for your needs
- `DOCKER_IMAGE_NAME`: Your Docker image name

### 4. Terraform Backend (Optional)

For production use, configure remote state backend:

```hcl
# In terraform/main.tf
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "online-shop/terraform.tfstate"
    region = "us-east-1"
  }
}
```

## 🚀 Usage

### Deploy Infrastructure and Application

1. Push code to the `final` branch:
   ```bash
   git checkout -b final
   git push origin final
   ```

2. Or trigger manually from GitHub Actions tab

### Destroy Infrastructure

1. Go to GitHub Actions tab
2. Select "🗑️ Destroy Infrastructure" workflow
3. Click "Run workflow"
4. Type "DESTROY" in the confirmation field
5. Click "Run workflow"

## 📊 Monitoring and Logs

### Application Access
- **URL**: `http://<instance-ip>`
- **Health Check**: `http://<instance-ip>/health`

### AWS Resources Created
- EC2 Instance (t3.micro by default)
- Security Group (HTTP, HTTPS, SSH access)
- IAM Role and Instance Profile
- Key Pair for SSH access
- CloudWatch Log Group

### Logs and Monitoring
- Application logs: CloudWatch Logs
- System metrics: CloudWatch Metrics
- SSH access: `ssh -i key.pem ec2-user@<instance-ip>`

## 🔧 Troubleshooting

### Common Issues

1. **Docker Build Fails**
   - Check Dockerfile syntax
   - Verify all dependencies are available

2. **Terraform Apply Fails**
   - Check AWS credentials and permissions
   - Verify region availability
   - Check for resource limits

3. **Application Not Accessible**
   - Verify security group rules
   - Check container status: `docker ps`
   - Review application logs: `docker logs online-shop`

4. **SSH Connection Issues**
   - Verify key pair is correctly configured
   - Check security group SSH rules
   - Ensure instance is in running state

### Debug Commands

Connect to EC2 instance:
```bash
ssh -i ~/.ssh/id_rsa ec2-user@<instance-ip>
```

Check application status:
```bash
sudo docker ps
sudo docker logs online-shop
curl http://localhost
```

View system information:
```bash
/opt/online-shop/system-info.sh
```

## 🔄 Workflow Customization

### Environment Variables

Modify these in the workflow files for customization:
- `AWS_REGION`: Target AWS region
- `EC2_INSTANCE_TYPE`: Instance size
- `TERRAFORM_VERSION`: Terraform version to use

### Multi-Environment Support

To support multiple environments (dev, staging, prod):
1. Create separate branches for each environment
2. Modify workflow triggers
3. Use environment-specific variable files
4. Configure separate Terraform workspaces

### Security Enhancements

1. **Restrict SSH Access**: Modify security group to allow SSH only from specific IPs
2. **Use HTTPS**: Configure SSL/TLS certificates
3. **Enable VPC**: Use custom VPC instead of default
4. **Backup Strategy**: Implement automated backups
5. **Monitoring**: Add comprehensive monitoring and alerting

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Docker Hub Documentation](https://docs.docker.com/docker-hub/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)

## 🤝 Contributing

When contributing to the CI/CD workflows:
1. Test changes in a fork first
2. Document any new requirements
3. Update this README with changes
4. Follow security best practices
5. Test both deploy and destroy workflows
