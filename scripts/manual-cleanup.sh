#!/bin/bash

# Manual cleanup script for online-shop AWS resources
# Run this script to delete all resources before redeployment

set -e

REGION="eu-west-1"
PROJECT_TAG="online-shop"

echo "🔥 Starting manual cleanup of online-shop resources in $REGION..."
echo "=================================================="

# 1. Terminate EC2 instances
echo "1. Terminating EC2 instances..."
INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=$PROJECT_TAG" "Name=instance-state-name,Values=running,stopped,stopping" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text \
  --region $REGION)

if [ -n "$INSTANCE_IDS" ] && [ "$INSTANCE_IDS" != "None" ]; then
  echo "Found instances to terminate: $INSTANCE_IDS"
  aws ec2 terminate-instances --instance-ids $INSTANCE_IDS --region $REGION
  echo "Waiting for instances to terminate..."
  aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS --region $REGION || echo "Wait timeout, continuing..."
  echo "✅ Instances terminated"
else
  echo "ℹ️  No EC2 instances found"
fi

# 2. Delete Security Groups
echo ""
echo "2. Deleting security groups..."
SG_IDS=$(aws ec2 describe-security-groups \
  --filters "Name=tag:Project,Values=$PROJECT_TAG" \
  --query "SecurityGroups[?GroupName!='default'].GroupId" \
  --output text \
  --region $REGION)

if [ -n "$SG_IDS" ] && [ "$SG_IDS" != "None" ]; then
  echo "Found security groups to delete: $SG_IDS"
  for sg_id in $SG_IDS; do
    aws ec2 delete-security-group --group-id $sg_id --region $REGION && echo "✅ Deleted security group: $sg_id" || echo "❌ Could not delete security group: $sg_id"
  done
else
  echo "ℹ️  No security groups found"
fi

# 3. Delete IAM roles and policies
echo ""
echo "3. Deleting IAM roles..."
ROLE_NAMES=$(aws iam list-roles \
  --query "Roles[?contains(RoleName, '$PROJECT_TAG')].RoleName" \
  --output text)

if [ -n "$ROLE_NAMES" ] && [ "$ROLE_NAMES" != "None" ]; then
  echo "Found IAM roles to delete: $ROLE_NAMES"
  for role_name in $ROLE_NAMES; do
    echo "Processing role: $role_name"
    
    # Detach managed policies
    aws iam list-attached-role-policies --role-name $role_name \
      --query "AttachedPolicies[].PolicyArn" --output text | \
      xargs -r -I {} aws iam detach-role-policy --role-name $role_name --policy-arn {}
    
    # Delete inline policies
    aws iam list-role-policies --role-name $role_name \
      --query "PolicyNames[]" --output text | \
      xargs -r -I {} aws iam delete-role-policy --role-name $role_name --policy-name {}
    
    # Remove role from instance profiles
    aws iam list-instance-profiles-for-role --role-name $role_name \
      --query "InstanceProfiles[].InstanceProfileName" --output text | \
      xargs -r -I {} aws iam remove-role-from-instance-profile --instance-profile-name {} --role-name $role_name
    
    # Delete the role
    aws iam delete-role --role-name $role_name && echo "✅ Deleted role: $role_name" || echo "❌ Could not delete role: $role_name"
  done
else
  echo "ℹ️  No IAM roles found"
fi

# 4. Delete Instance Profiles
echo ""
echo "4. Deleting instance profiles..."
PROFILE_NAMES=$(aws iam list-instance-profiles \
  --query "InstanceProfiles[?contains(InstanceProfileName, '$PROJECT_TAG')].InstanceProfileName" \
  --output text)

if [ -n "$PROFILE_NAMES" ] && [ "$PROFILE_NAMES" != "None" ]; then
  echo "Found instance profiles to delete: $PROFILE_NAMES"
  for profile_name in $PROFILE_NAMES; do
    aws iam delete-instance-profile --instance-profile-name $profile_name && echo "✅ Deleted instance profile: $profile_name" || echo "❌ Could not delete instance profile: $profile_name"
  done
else
  echo "ℹ️  No instance profiles found"
fi

# 5. Delete CloudWatch Log Groups
echo ""
echo "5. Deleting CloudWatch log groups..."
LOG_GROUPS=$(aws logs describe-log-groups \
  --log-group-name-prefix "/aws/ec2/$PROJECT_TAG" \
  --query "logGroups[].logGroupName" \
  --output text \
  --region $REGION)

if [ -n "$LOG_GROUPS" ] && [ "$LOG_GROUPS" != "None" ]; then
  echo "Found log groups to delete: $LOG_GROUPS"
  for log_group in $LOG_GROUPS; do
    aws logs delete-log-group --log-group-name $log_group --region $REGION && echo "✅ Deleted log group: $log_group" || echo "❌ Could not delete log group: $log_group"
  done
else
  echo "ℹ️  No log groups found"
fi

# 6. Delete CloudWatch Alarms
echo ""
echo "6. Deleting CloudWatch alarms..."
ALARM_NAMES=$(aws cloudwatch describe-alarms \
  --query "MetricAlarms[?contains(AlarmName, '$PROJECT_TAG')].AlarmName" \
  --output text \
  --region $REGION)

if [ -n "$ALARM_NAMES" ] && [ "$ALARM_NAMES" != "None" ]; then
  echo "Found alarms to delete: $ALARM_NAMES"
  aws cloudwatch delete-alarms --alarm-names $ALARM_NAMES --region $REGION && echo "✅ Deleted CloudWatch alarms" || echo "❌ Could not delete alarms"
else
  echo "ℹ️  No CloudWatch alarms found"
fi

# 7. Delete Key Pairs
echo ""
echo "7. Deleting key pairs..."
KEY_NAMES=$(aws ec2 describe-key-pairs \
  --filters "Name=tag:Project,Values=$PROJECT_TAG" \
  --query "KeyPairs[].KeyName" \
  --output text \
  --region $REGION)

if [ -n "$KEY_NAMES" ] && [ "$KEY_NAMES" != "None" ]; then
  echo "Found key pairs to delete: $KEY_NAMES"
  for key_name in $KEY_NAMES; do
    aws ec2 delete-key-pair --key-name $key_name --region $REGION && echo "✅ Deleted key pair: $key_name" || echo "❌ Could not delete key pair: $key_name"
  done
else
  echo "ℹ️  No key pairs found"
fi

# Final verification
echo ""
echo "🔍 Final verification..."
echo "=================================================="

REMAINING_INSTANCES=$(aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=$PROJECT_TAG" "Name=instance-state-name,Values=running,stopped,stopping" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text \
  --region $REGION | wc -w)

REMAINING_SG=$(aws ec2 describe-security-groups \
  --filters "Name=tag:Project,Values=$PROJECT_TAG" \
  --query "SecurityGroups[?GroupName!='default'].GroupId" \
  --output text \
  --region $REGION | wc -w)

REMAINING_ROLES=$(aws iam list-roles \
  --query "Roles[?contains(RoleName, '$PROJECT_TAG')].RoleName" \
  --output text | wc -w)

echo "Remaining resources:"
echo "- EC2 Instances: $REMAINING_INSTANCES"
echo "- Security Groups: $REMAINING_SG"
echo "- IAM Roles: $REMAINING_ROLES"

TOTAL_REMAINING=$((REMAINING_INSTANCES + REMAINING_SG + REMAINING_ROLES))

if [ $TOTAL_REMAINING -eq 0 ]; then
  echo ""
  echo "🎉 SUCCESS: All online-shop resources have been deleted!"
  echo "You can now safely run a new deployment."
else
  echo ""
  echo "⚠️  WARNING: $TOTAL_REMAINING resources may still exist"
  echo "Check AWS console for any remaining resources"
fi

echo ""
echo "🚀 Cleanup completed!"
echo "=================================================="
