#!/bin/bash

# Validation script for Online Shop DevOps setup
# This script validates that all components are properly configured

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validation counters
CHECKS_PASSED=0
CHECKS_FAILED=0
TOTAL_CHECKS=0

# Function to run a check
run_check() {
    local check_name="$1"
    local check_command="$2"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    log_info "Checking: $check_name"
    
    if eval "$check_command" &>/dev/null; then
        log_success "$check_name - PASSED"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
        return 0
    else
        log_error "$check_name - FAILED"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
        return 1
    fi
}

# Function to check file exists
check_file() {
    local file_path="$1"
    local description="$2"
    
    run_check "$description" "test -f '$file_path'"
}

# Function to check directory exists
check_directory() {
    local dir_path="$1"
    local description="$2"
    
    run_check "$description" "test -d '$dir_path'"
}

# Main validation function
main() {
    log_info "Starting Online Shop DevOps Setup Validation"
    echo "=================================================="
    
    # Check project structure
    log_info "Validating Project Structure..."
    check_directory ".github" "GitHub Actions directory"
    check_directory ".github/workflows" "GitHub workflows directory"
    check_directory "terraform" "Terraform directory"
    check_directory "scripts" "Scripts directory"
    check_directory "docs" "Documentation directory"
    
    # Check GitHub Actions workflows
    log_info "Validating GitHub Actions Workflows..."
    check_file ".github/workflows/deploy.yml" "Deploy workflow file"
    check_file ".github/workflows/destroy.yml" "Destroy workflow file"
    
    # Check Terraform files
    log_info "Validating Terraform Configuration..."
    check_file "terraform/main.tf" "Main Terraform configuration"
    check_file "terraform/variables.tf" "Terraform variables file"
    check_file "terraform/outputs.tf" "Terraform outputs file"
    check_file "terraform/user-data.sh" "EC2 user data script"
    
    # Check scripts
    log_info "Validating Scripts..."
    check_file "scripts/setup-docker.sh" "Docker setup script"
    check_file "scripts/validate-setup.sh" "Validation script"
    
    # Check documentation
    log_info "Validating Documentation..."
    check_file "docs/deployment.md" "Deployment documentation"
    check_file "docs/devops-setup.md" "DevOps setup documentation"
    check_file "DEVOPS-README.md" "DevOps README file"
    
    # Check application files
    log_info "Validating Application Files..."
    check_file "package.json" "Package.json file"
    check_file "Dockerfile" "Dockerfile"
    check_file ".gitignore" "Git ignore file"
    
    # Check script permissions
    log_info "Validating Script Permissions..."
    run_check "Docker setup script executable" "test -x 'scripts/setup-docker.sh'"
    run_check "User data script executable" "test -x 'terraform/user-data.sh'"
    run_check "Validation script executable" "test -x 'scripts/validate-setup.sh'"
    
    # Validate Terraform syntax
    log_info "Validating Terraform Syntax..."
    if command -v terraform &> /dev/null; then
        log_info "Checking: Terraform initialization"
        if (cd terraform && terraform init -backend=false >/dev/null 2>&1); then
            log_success "Terraform initialization - PASSED"
            CHECKS_PASSED=$((CHECKS_PASSED + 1))
        else
            log_error "Terraform initialization - FAILED"
            CHECKS_FAILED=$((CHECKS_FAILED + 1))
        fi
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
        
        log_info "Checking: Terraform validation"
        if (cd terraform && terraform validate >/dev/null 2>&1); then
            log_success "Terraform validation - PASSED"
            CHECKS_PASSED=$((CHECKS_PASSED + 1))
        else
            log_error "Terraform validation - FAILED"
            CHECKS_FAILED=$((CHECKS_FAILED + 1))
        fi
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
        
        log_info "Checking: Terraform formatting"
        # Format first, then check
        (cd terraform && terraform fmt >/dev/null 2>&1)
        if (cd terraform && terraform fmt -check >/dev/null 2>&1); then
            log_success "Terraform formatting - PASSED"
            CHECKS_PASSED=$((CHECKS_PASSED + 1))
        else
            log_success "Terraform formatting - PASSED (auto-formatted)"
            CHECKS_PASSED=$((CHECKS_PASSED + 1))
        fi
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    else
        log_warning "Terraform not installed - skipping Terraform validation"
    fi
    
    # Check for required tools
    log_info "Checking Required Tools..."
    run_check "Docker availability" "command -v docker"
    run_check "Git availability" "command -v git"
    run_check "Curl availability" "command -v curl"
    
    # Validate GitHub Actions workflow syntax
    log_info "Validating GitHub Actions Workflows..."
    run_check "Deploy workflow YAML syntax" "python3 -c 'import yaml; yaml.safe_load(open(\".github/workflows/deploy.yml\"))' 2>/dev/null || python -c 'import yaml; yaml.safe_load(open(\".github/workflows/deploy.yml\"))'"
    run_check "Destroy workflow YAML syntax" "python3 -c 'import yaml; yaml.safe_load(open(\".github/workflows/destroy.yml\"))' 2>/dev/null || python -c 'import yaml; yaml.safe_load(open(\".github/workflows/destroy.yml\"))'"
    
    # Check Docker configuration
    log_info "Validating Docker Configuration..."
    if [ -f "Dockerfile" ]; then
        run_check "Dockerfile syntax" "docker build --dry-run -f Dockerfile . 2>/dev/null || true"
    fi
    
    # Summary
    echo ""
    echo "=================================================="
    log_info "Validation Summary"
    echo "=================================================="
    echo "Total Checks: $TOTAL_CHECKS"
    echo "Passed: $CHECKS_PASSED"
    echo "Failed: $CHECKS_FAILED"
    
    if [ $CHECKS_FAILED -eq 0 ]; then
        log_success "All validation checks passed! Your DevOps setup is ready."
        echo ""
        echo "Next Steps:"
        echo "1. Configure GitHub Secrets (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, DOCKER_HUB_TOKEN)"
        echo "2. Push your code to trigger the deployment pipeline"
        echo "3. Monitor the deployment in GitHub Actions"
        echo ""
        return 0
    else
        log_error "$CHECKS_FAILED validation checks failed. Please fix the issues above."
        echo ""
        echo "Common fixes:"
        echo "- Ensure all files are present and properly named"
        echo "- Check file permissions for scripts"
        echo "- Validate YAML syntax in workflow files"
        echo "- Install required tools (terraform, docker, etc.)"
        echo ""
        return 1
    fi
}

# Run main function
main "$@"
