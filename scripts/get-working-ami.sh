#!/bin/bash

# Script to get a working AMI ID for eu-west-1
echo "🔍 Finding working AMI in eu-west-1..."

# Try to get the latest Ubuntu AMI
UBUNTU_AMI=$(aws ec2 describe-images \
    --region eu-west-1 \
    --owners 099720109477 \
    --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-*" \
              "Name=state,Values=available" \
              "Name=architecture,Values=x86_64" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text 2>/dev/null)

if [ "$UBUNTU_AMI" != "None" ] && [ -n "$UBUNTU_AMI" ]; then
    echo "✅ Found Ubuntu AMI: $UBUNTU_AMI"
    echo "To use this AMI, update your terraform with:"
    echo "variable \"fallback_ami_id\" { default = \"$UBUNTU_AMI\" }"
else
    echo "❌ No Ubuntu AMI found, trying Amazon Linux 2..."
    
    # Fallback to Amazon Linux 2
    AMAZON_AMI=$(aws ec2 describe-images \
        --region eu-west-1 \
        --owners amazon \
        --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
                  "Name=state,Values=available" \
        --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
        --output text 2>/dev/null)
    
    if [ "$AMAZON_AMI" != "None" ] && [ -n "$AMAZON_AMI" ]; then
        echo "✅ Found Amazon Linux 2 AMI: $AMAZON_AMI"
        echo "To use this AMI, update your terraform with:"
        echo "variable \"fallback_ami_id\" { default = \"$AMAZON_AMI\" }"
    else
        echo "❌ No suitable AMI found"
        echo "Using hardcoded fallback: ami-0c02fb55956c7d316"
    fi
fi

echo ""
echo "🔧 Quick fix: Add this to your GitHub Actions workflow:"
echo "- name: Apply Terraform Changes"
echo "  run: terraform apply --auto-approve -var=\"use_fallback_ami=true\""
