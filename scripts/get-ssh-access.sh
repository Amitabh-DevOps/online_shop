#!/bin/bash

# Script to get SSH access to the online-shop EC2 instance

set -e

REGION="eu-west-1"
PROJECT_TAG="online-shop"

echo "🔍 Finding online-shop EC2 instance..."

# Get instance information
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=$PROJECT_TAG" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text \
  --region $REGION)

if [ "$INSTANCE_ID" = "None" ] || [ -z "$INSTANCE_ID" ]; then
  echo "❌ No running online-shop instance found"
  exit 1
fi

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text \
  --region $REGION)

KEY_NAME=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query "Reservations[0].Instances[0].KeyName" \
  --output text \
  --region $REGION)

echo "✅ Found instance:"
echo "   Instance ID: $INSTANCE_ID"
echo "   Public IP: $PUBLIC_IP"
echo "   Key Pair: $KEY_NAME"
echo ""

# Check if we have local Terraform state
if [ -f "../terraform/terraform.tfstate" ]; then
  echo "🔑 Extracting private key from local Terraform state..."
  cd ../terraform
  terraform output -raw private_key_pem > ../ssh-key.pem
  chmod 600 ../ssh-key.pem
  cd ../scripts
  
  echo "✅ Private key saved to: ssh-key.pem"
  echo ""
  echo "🚀 You can now SSH using:"
  echo "   ssh -i ssh-key.pem ec2-user@$PUBLIC_IP"
  echo ""
  echo "📋 Or run this command directly:"
  echo "   ssh -i ssh-key.pem ec2-user@$PUBLIC_IP"
  
elif command -v terraform &> /dev/null && [ -d "../terraform" ]; then
  echo "🔑 Attempting to get private key from Terraform..."
  cd ../terraform
  
  if terraform init -backend=false >/dev/null 2>&1; then
    if terraform output -raw private_key_pem > ../ssh-key.pem 2>/dev/null; then
      chmod 600 ../ssh-key.pem
      cd ../scripts
      echo "✅ Private key saved to: ssh-key.pem"
      echo ""
      echo "🚀 You can now SSH using:"
      echo "   ssh -i ssh-key.pem ec2-user@$PUBLIC_IP"
    else
      cd ../scripts
      echo "❌ Could not extract private key from Terraform state"
      echo ""
      echo "🔧 Alternative options:"
      echo "1. Use AWS Session Manager (no key needed):"
      echo "   aws ssm start-session --target $INSTANCE_ID --region $REGION"
      echo ""
      echo "2. Download private key from GitHub Actions artifacts"
      echo "3. Create a new key pair and associate it with the instance"
    fi
  else
    cd ../scripts
    echo "❌ Could not initialize Terraform"
  fi
else
  echo "❌ No local Terraform state found"
  echo ""
  echo "🔧 Alternative access methods:"
  echo ""
  echo "1. 🖥️  AWS Session Manager (Recommended - no key needed):"
  echo "   aws ssm start-session --target $INSTANCE_ID --region $REGION"
  echo ""
  echo "2. 📥 Download private key from GitHub Actions:"
  echo "   - Go to your GitHub repository"
  echo "   - Click 'Actions' tab"
  echo "   - Find your latest deployment run"
  echo "   - Download 'ssh-private-key' artifact"
  echo "   - Extract and use the .pem file"
  echo ""
  echo "3. 🔑 Create new key pair:"
  echo "   - Create new key pair in AWS console"
  echo "   - Stop the instance"
  echo "   - Change key pair"
  echo "   - Start the instance"
fi

echo ""
echo "📊 Instance Status:"
aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query "Reservations[0].Instances[0].[State.Name,PublicIpAddress,PrivateIpAddress]" \
  --output table \
  --region $REGION

echo ""
echo "🌐 Application URL: http://$PUBLIC_IP:3000"
