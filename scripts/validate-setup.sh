#!/bin/bash

# ============================================================================
# CI/CD Setup Validation Script
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Test functions
test_passed() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
    ((PASSED++))
}

test_failed() {
    echo -e "${RED}❌ FAIL:${NC} $1"
    ((FAILED++))
}

test_warning() {
    echo -e "${YELLOW}⚠️  WARN:${NC} $1"
    ((WARNINGS++))
}

test_info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

# Main validation function
main() {
    echo "🔍 Validating CI/CD Setup for Online Shop"
    echo "========================================"
    echo
    
    validate_prerequisites
    validate_git_setup
    validate_aws_setup
    validate_docker_setup
    validate_terraform_setup
    validate_github_workflows
    validate_project_structure
    
    echo
    echo "📊 Validation Summary"
    echo "===================="
    echo -e "✅ Passed: ${GREEN}$PASSED${NC}"
    echo -e "❌ Failed: ${RED}$FAILED${NC}"
    echo -e "⚠️  Warnings: ${YELLOW}$WARNINGS${NC}"
    echo
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 All critical validations passed! Your setup is ready for deployment.${NC}"
        exit 0
    else
        echo -e "${RED}💥 Some validations failed. Please fix the issues before proceeding.${NC}"
        exit 1
    fi
}

validate_prerequisites() {
    echo "🛠️  Checking Prerequisites..."
    
    # Check Git
    if command -v git >/dev/null 2>&1; then
        test_passed "Git is installed ($(git --version | cut -d' ' -f3))"
    else
        test_failed "Git is not installed"
    fi
    
    # Check AWS CLI
    if command -v aws >/dev/null 2>&1; then
        test_passed "AWS CLI is installed ($(aws --version | cut -d' ' -f1 | cut -d'/' -f2))"
    else
        test_failed "AWS CLI is not installed"
    fi
    
    # Check Terraform
    if command -v terraform >/dev/null 2>&1; then
        local tf_version=$(terraform version | head -n1 | cut -d'v' -f2)
        test_passed "Terraform is installed (v$tf_version)"
    else
        test_failed "Terraform is not installed"
    fi
    
    # Check Docker
    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            test_passed "Docker is installed and running"
        else
            test_warning "Docker is installed but not running"
        fi
    else
        test_failed "Docker is not installed"
    fi
    
    # Check GitHub CLI (optional)
    if command -v gh >/dev/null 2>&1; then
        test_passed "GitHub CLI is installed (optional)"
    else
        test_warning "GitHub CLI not installed (you'll need to set secrets manually)"
    fi
    
    echo
}

validate_git_setup() {
    echo "🐙 Checking Git Setup..."
    
    # Check if in git repository
    if git rev-parse --git-dir >/dev/null 2>&1; then
        test_passed "Inside a Git repository"
    else
        test_failed "Not in a Git repository"
        return
    fi
    
    # Check remote origin
    if git remote get-url origin >/dev/null 2>&1; then
        local origin_url=$(git remote get-url origin)
        test_passed "Remote origin configured: $origin_url"
    else
        test_failed "No remote origin configured"
    fi
    
    # Check for final branch
    if git show-ref --verify --quiet refs/heads/final; then
        test_passed "Final branch exists"
    else
        test_warning "Final branch doesn't exist (will be created automatically)"
    fi
    
    # Check for uncommitted changes
    if git diff-index --quiet HEAD --; then
        test_passed "No uncommitted changes"
    else
        test_warning "You have uncommitted changes"
    fi
    
    echo
}

validate_aws_setup() {
    echo "☁️  Checking AWS Setup..."
    
    # Check AWS credentials
    if aws sts get-caller-identity >/dev/null 2>&1; then
        local account_id=$(aws sts get-caller-identity --query Account --output text)
        local user_arn=$(aws sts get-caller-identity --query Arn --output text)
        test_passed "AWS credentials configured (Account: $account_id)"
        test_info "User: $user_arn"
    else
        test_failed "AWS credentials not configured or invalid"
        return
    fi
    
    # Check AWS region
    local aws_region=$(aws configure get region)
    if [ -n "$aws_region" ]; then
        test_passed "AWS region configured: $aws_region"
    else
        test_warning "AWS region not configured (will use us-east-1 default)"
    fi
    
    # Test EC2 permissions
    if aws ec2 describe-instances --max-items 1 >/dev/null 2>&1; then
        test_passed "EC2 permissions verified"
    else
        test_failed "Missing EC2 permissions"
    fi
    
    # Test IAM permissions
    if aws iam get-user >/dev/null 2>&1; then
        test_passed "IAM permissions verified"
    else
        test_warning "Limited IAM permissions (may cause issues)"
    fi
    
    echo
}

validate_docker_setup() {
    echo "🐳 Checking Docker Setup..."
    
    if ! command -v docker >/dev/null 2>&1; then
        test_failed "Docker not installed"
        return
    fi
    
    # Check if Docker daemon is running
    if docker info >/dev/null 2>&1; then
        test_passed "Docker daemon is running"
    else
        test_failed "Docker daemon is not running"
        return
    fi
    
    # Test Docker build
    if docker build -t test-build -f - . >/dev/null 2>&1 <<EOF
FROM alpine:latest
RUN echo "test"
EOF
    then
        test_passed "Docker build test successful"
        docker rmi test-build >/dev/null 2>&1
    else
        test_failed "Docker build test failed"
    fi
    
    # Check Dockerfile
    if [ -f "Dockerfile" ]; then
        test_passed "Dockerfile exists"
        
        # Basic Dockerfile validation
        if grep -q "FROM" Dockerfile && grep -q "EXPOSE" Dockerfile; then
            test_passed "Dockerfile has required instructions"
        else
            test_warning "Dockerfile may be incomplete"
        fi
    else
        test_failed "Dockerfile not found"
    fi
    
    echo
}

validate_terraform_setup() {
    echo "🏗️  Checking Terraform Setup..."
    
    if ! command -v terraform >/dev/null 2>&1; then
        test_failed "Terraform not installed"
        return
    fi
    
    # Check terraform directory
    if [ -d "terraform" ]; then
        test_passed "Terraform directory exists"
    else
        test_failed "Terraform directory not found"
        return
    fi
    
    cd terraform
    
    # Check required files
    local required_files=("main.tf" "variables.tf" "versions.tf" "user-data.sh")
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            test_passed "Required file exists: $file"
        else
            test_failed "Missing required file: $file"
        fi
    done
    
    # Terraform init
    if terraform init >/dev/null 2>&1; then
        test_passed "Terraform initialization successful"
    else
        test_failed "Terraform initialization failed"
        cd ..
        return
    fi
    
    # Terraform validate
    if terraform validate >/dev/null 2>&1; then
        test_passed "Terraform configuration is valid"
    else
        test_failed "Terraform configuration validation failed"
    fi
    
    # Terraform format check
    if terraform fmt -check >/dev/null 2>&1; then
        test_passed "Terraform formatting is correct"
    else
        test_warning "Terraform files need formatting (run 'terraform fmt')"
    fi
    
    cd ..
    echo
}

validate_github_workflows() {
    echo "⚙️  Checking GitHub Workflows..."
    
    # Check workflows directory
    if [ -d ".github/workflows" ]; then
        test_passed "GitHub workflows directory exists"
    else
        test_failed "GitHub workflows directory not found"
        return
    fi
    
    # Check required workflow files
    local workflows=("deploy.yml" "destroy.yml")
    for workflow in "${workflows[@]}"; do
        if [ -f ".github/workflows/$workflow" ]; then
            test_passed "Workflow file exists: $workflow"
            
            # Basic YAML validation
            if command -v python3 >/dev/null 2>&1; then
                if python3 -c "import yaml; yaml.safe_load(open('.github/workflows/$workflow'))" 2>/dev/null; then
                    test_passed "Workflow YAML is valid: $workflow"
                else
                    test_failed "Invalid YAML syntax in: $workflow"
                fi
            fi
        else
            test_failed "Missing workflow file: $workflow"
        fi
    done
    
    # Check for required secrets documentation
    if grep -q "secrets\." .github/workflows/deploy.yml; then
        test_passed "Deploy workflow uses GitHub secrets"
    else
        test_warning "Deploy workflow may not be using secrets properly"
    fi
    
    echo
}

validate_project_structure() {
    echo "📁 Checking Project Structure..."
    
    # Check required directories
    local required_dirs=(".github/workflows" "terraform" "src" "public")
    for dir in "${required_dirs[@]}"; do
        if [ -d "$dir" ]; then
            test_passed "Required directory exists: $dir"
        else
            test_failed "Missing required directory: $dir"
        fi
    done
    
    # Check required files
    local required_files=("package.json" "Dockerfile" "README.md")
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            test_passed "Required file exists: $file"
        else
            test_failed "Missing required file: $file"
        fi
    done
    
    # Check package.json scripts
    if [ -f "package.json" ]; then
        if grep -q '"build"' package.json && grep -q '"dev"' package.json; then
            test_passed "Package.json has required scripts"
        else
            test_warning "Package.json may be missing required scripts"
        fi
    fi
    
    # Check for setup script
    if [ -f "scripts/setup-cicd.sh" ]; then
        test_passed "Setup script exists"
        if [ -x "scripts/setup-cicd.sh" ]; then
            test_passed "Setup script is executable"
        else
            test_warning "Setup script is not executable"
        fi
    else
        test_warning "Setup script not found"
    fi
    
    echo
}

# Run main function
main "$@"
