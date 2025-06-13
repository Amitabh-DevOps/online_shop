# GitHub Secrets Setup Guide

This document explains how to set up the required GitHub secrets for the CI/CD pipeline.

## 🔐 Required Secrets

### AWS Configuration
```
AWS_ACCESS_KEY_ID=your_aws_access_key_id
AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key
STATE_BUCKET_NAME=your-terraform-state-bucket-name
DYNAMODB_TABLE_NAME=your-terraform-locks-table-name
```

### DockerHub Configuration
```
DOCKERHUB_USERNAME=your_dockerhub_username
DOCKERHUB_TOKEN=your_dockerhub_access_token
```

### EC2 SSH Configuration
```
EC2_PUBLIC_KEY=your_ssh_public_key_content
EC2_PRIVATE_KEY=your_ssh_private_key_content
```

### Email Notifications
```
MAIL_USERNAME=your_gmail@gmail.com
MAIL_PASSWORD=your_gmail_app_password
MAIL_FROM=your_gmail@gmail.com
MAIL_TO=recipient@gmail.com
```

## 📋 How to Add Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with the exact name and value

## 🔑 Generating SSH Keys

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f online-shop-key

# Public key (for EC2_PUBLIC_KEY secret)
cat online-shop-key.pub

# Private key (for EC2_PRIVATE_KEY secret)
cat online-shop-key
```

## 🐳 DockerHub Access Token

1. Login to [hub.docker.com](https://hub.docker.com)
2. Go to **Account Settings** → **Security**
3. Click **New Access Token**
4. Copy the token (not your password!)

## 📧 Gmail App Password

1. Enable 2-Factor Authentication on your Google account
2. Go to [myaccount.google.com](https://myaccount.google.com)
3. **Security** → **2-Step Verification** → **App passwords**
4. Generate password for "Mail"
5. Use the 16-character password

## 🪣 S3 Bucket and DynamoDB Names

Choose unique names for your Terraform backend:
```
STATE_BUCKET_NAME=my-company-terraform-state-12345
DYNAMODB_TABLE_NAME=my-company-terraform-locks
```

## ✅ Verification

After adding all secrets, your repository should have:
- ✅ AWS_ACCESS_KEY_ID
- ✅ AWS_SECRET_ACCESS_KEY  
- ✅ STATE_BUCKET_NAME
- ✅ DYNAMODB_TABLE_NAME
- ✅ DOCKERHUB_USERNAME
- ✅ DOCKERHUB_TOKEN
- ✅ EC2_PUBLIC_KEY
- ✅ EC2_PRIVATE_KEY
- ✅ MAIL_USERNAME
- ✅ MAIL_PASSWORD
- ✅ MAIL_FROM
- ✅ MAIL_TO

## 🚀 Ready to Deploy!

Once all secrets are configured, push to the `master` branch to trigger the deployment pipeline.
