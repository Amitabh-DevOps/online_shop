# GitHub Secrets Setup Guide

You need to add the following secrets to your GitHub repository for the CI/CD pipeline to work properly.

## 🔐 Required GitHub Secrets

### 1. AWS Credentials
```
AWS_ACCESS_KEY_ID=your_aws_access_key_id
AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key
```

### 2. DockerHub Credentials
```
DOCKERHUB_USERNAME=your_dockerhub_username
DOCKERHUB_TOKEN=your_dockerhub_access_token
```

### 3. SSH Private Key
```
EC2_SSH_PRIVATE_KEY=your_private_key_content
```

## 📋 How to Add Secrets

### Step 1: Go to Repository Settings
1. Navigate to your GitHub repository
2. Click on **Settings** tab
3. In the left sidebar, click **Secrets and variables** → **Actions**

### Step 2: Add Each Secret
Click **New repository secret** for each of the following:

#### AWS_ACCESS_KEY_ID
- **Name**: `AWS_ACCESS_KEY_ID`
- **Secret**: Your AWS Access Key ID

#### AWS_SECRET_ACCESS_KEY
- **Name**: `AWS_SECRET_ACCESS_KEY`
- **Secret**: Your AWS Secret Access Key

#### DOCKERHUB_USERNAME
- **Name**: `DOCKERHUB_USERNAME`
- **Secret**: Your DockerHub username

#### DOCKERHUB_TOKEN
- **Name**: `DOCKERHUB_TOKEN`
- **Secret**: Your DockerHub access token (not password!)

#### EC2_SSH_PRIVATE_KEY
- **Name**: `EC2_SSH_PRIVATE_KEY`
- **Secret**: Content of your private key file

## 🔑 Getting the SSH Private Key

The private key is located at:
```
terraform/terraform_resources/github-action-key
```

### To get the private key content:

#### Option 1: Using cat command
```bash
cat terraform/terraform_resources/github-action-key
```

#### Option 2: Using a text editor
Open the file `terraform/terraform_resources/github-action-key` in any text editor.

### Copy the entire content including:
```
-----BEGIN OPENSSH PRIVATE KEY-----
[key content]
-----END OPENSSH PRIVATE KEY-----
```

⚠️ **Important**: Copy the ENTIRE key including the BEGIN and END lines!

## 🐳 Getting DockerHub Access Token

### Step 1: Login to DockerHub
1. Go to [hub.docker.com](https://hub.docker.com)
2. Login to your account

### Step 2: Create Access Token
1. Click on your username → **Account Settings**
2. Go to **Security** tab
3. Click **New Access Token**
4. Give it a name (e.g., "GitHub Actions")
5. Copy the generated token

⚠️ **Important**: Use the access token, NOT your DockerHub password!

## ✅ Verification

After adding all secrets, your repository secrets should look like:
- ✅ AWS_ACCESS_KEY_ID
- ✅ AWS_SECRET_ACCESS_KEY
- ✅ DOCKERHUB_USERNAME
- ✅ DOCKERHUB_TOKEN
- ✅ EC2_SSH_PRIVATE_KEY

## 🚀 Test the Pipeline

Once all secrets are added:
1. Make any small change to your code
2. Commit and push to the `github-action` branch
3. Check GitHub Actions tab to see the pipeline running

## 🔧 Troubleshooting

### SSH Permission Denied
- Ensure `EC2_SSH_PRIVATE_KEY` contains the complete private key
- Check that the key format is correct (OpenSSH format)

### Docker Login Failed
- Verify `DOCKERHUB_USERNAME` is correct
- Ensure `DOCKERHUB_TOKEN` is an access token, not password
- Check that the token has push permissions

### AWS Access Denied
- Verify AWS credentials are correct
- Ensure the AWS user has necessary permissions for EC2, S3, DynamoDB

## 📞 Need Help?

If you encounter issues:
1. Check the GitHub Actions logs for specific error messages
2. Verify all secrets are correctly set
3. Ensure the private key matches the public key used by Terraform
