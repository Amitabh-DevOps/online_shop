#!/bin/bash

# ============================================================================
# Online Shop CI/CD Setup Script
# ============================================================================

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

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Main setup function
main() {
    log_info "🚀 Starting Online Shop CI/CD Setup..."
    
    # Check prerequisites
    check_prerequisites
    
    # Setup GitHub repository
    setup_github_repo
    
    # Configure AWS
    configure_aws
    
    # Setup Docker Hub
    setup_docker_hub
    
    # Validate Terraform
    validate_terraform
    
    # Final instructions
    show_final_instructions
    
    log_success "🎉 CI/CD setup completed successfully!"
}

check_prerequisites() {
    log_info "🔍 Checking prerequisites..."
    
    local missing_tools=()
    
    # Check required tools
    if ! command_exists git; then
        missing_tools+=("git")
    fi
    
    if ! command_exists aws; then
        missing_tools+=("aws-cli")
    fi
    
    if ! command_exists terraform; then
        missing_tools+=("terraform")
    fi
    
    if ! command_exists docker; then
        missing_tools+=("docker")
    fi
    
    if ! command_exists gh; then
        log_warning "GitHub CLI (gh) not found. You'll need to configure secrets manually."
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Please install the missing tools and run this script again."
        exit 1
    fi
    
    log_success "✅ All prerequisites are installed"
}

setup_github_repo() {
    log_info "🐙 Setting up GitHub repository..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a Git repository. Please run this script from your project root."
        exit 1
    fi
    
    # Check if remote origin exists
    if ! git remote get-url origin > /dev/null 2>&1; then
        log_warning "No remote origin found. Please add your GitHub repository as origin:"
        log_info "git remote add origin https://github.com/username/online-shop.git"
        return
    fi
    
    local repo_url=$(git remote get-url origin)
    log_info "Repository URL: $repo_url"
    
    # Create final branch if it doesn't exist
    if ! git show-ref --verify --quiet refs/heads/final; then
        log_info "Creating 'final' branch..."
        git checkout -b final
        git push -u origin final
        git checkout main || git checkout master
        log_success "✅ Created 'final' branch"
    else
        log_info "✅ 'final' branch already exists"
    fi
}

configure_aws() {
    log_info "☁️ Configuring AWS..."
    
    # Check if AWS CLI is configured
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        log_warning "AWS CLI not configured. Please run 'aws configure' first."
        log_info "You'll need:"
        log_info "  - AWS Access Key ID"
        log_info "  - AWS Secret Access Key"
        log_info "  - Default region (e.g., us-east-1)"
        return
    fi
    
    local aws_account=$(aws sts get-caller-identity --query Account --output text)
    local aws_region=$(aws configure get region)
    
    log_success "✅ AWS configured for account: $aws_account in region: $aws_region"
    
    # Check required permissions
    log_info "🔐 Checking AWS permissions..."
    
    local permissions_ok=true
    
    # Test EC2 permissions
    if ! aws ec2 describe-instances --max-items 1 > /dev/null 2>&1; then
        log_warning "❌ Missing EC2 permissions"
        permissions_ok=false
    fi
    
    # Test IAM permissions
    if ! aws iam get-user > /dev/null 2>&1; then
        log_warning "❌ Missing IAM permissions"
        permissions_ok=false
    fi
    
    if [ "$permissions_ok" = true ]; then
        log_success "✅ AWS permissions look good"
    else
        log_warning "⚠️ Some AWS permissions may be missing. Please ensure your user has:"
        log_info "  - EC2 Full Access"
        log_info "  - IAM Limited Access"
        log_info "  - CloudWatch Logs Access"
    fi
}

setup_docker_hub() {
    log_info "🐳 Setting up Docker Hub..."
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        log_warning "Docker is not running. Please start Docker and try again."
        return
    fi
    
    log_info "Please ensure you have:"
    log_info "  1. A Docker Hub account"
    log_info "  2. Created an access token in Docker Hub"
    log_info "  3. Your Docker Hub username ready"
    
    read -p "Enter your Docker Hub username: " dockerhub_username
    
    if [ -n "$dockerhub_username" ]; then
        log_info "Testing Docker Hub access..."
        if docker login --username "$dockerhub_username" --password-stdin <<< "test" 2>/dev/null; then
            log_warning "Please use your access token, not password for GitHub Actions"
        fi
        log_success "✅ Docker Hub username: $dockerhub_username"
    fi
}

validate_terraform() {
    log_info "🏗️ Validating Terraform configuration..."
    
    cd terraform
    
    # Initialize Terraform
    if terraform init > /dev/null 2>&1; then
        log_success "✅ Terraform initialized successfully"
    else
        log_error "❌ Terraform initialization failed"
        return
    fi
    
    # Validate configuration
    if terraform validate > /dev/null 2>&1; then
        log_success "✅ Terraform configuration is valid"
    else
        log_error "❌ Terraform configuration validation failed"
        terraform validate
        return
    fi
    
    # Format check
    if terraform fmt -check > /dev/null 2>&1; then
        log_success "✅ Terraform formatting is correct"
    else
        log_info "🔧 Formatting Terraform files..."
        terraform fmt
        log_success "✅ Terraform files formatted"
    fi
    
    cd ..
}

setup_github_secrets() {
    log_info "🔐 Setting up GitHub Secrets..."
    
    if ! command_exists gh; then
        log_warning "GitHub CLI not found. Please set up secrets manually."
        return
    fi
    
    # Check if authenticated
    if ! gh auth status > /dev/null 2>&1; then
        log_info "Please authenticate with GitHub CLI:"
        gh auth login
    fi
    
    log_info "Setting up required secrets..."
    
    # AWS credentials
    read -p "Enter AWS Access Key ID: " aws_access_key
    read -s -p "Enter AWS Secret Access Key: " aws_secret_key
    echo
    
    if [ -n "$aws_access_key" ] && [ -n "$aws_secret_key" ]; then
        gh secret set AWS_ACCESS_KEY_ID --body "$aws_access_key"
        gh secret set AWS_SECRET_ACCESS_KEY --body "$aws_secret_key"
        log_success "✅ AWS credentials set"
    fi
    
    # Docker Hub credentials
    read -p "Enter Docker Hub username: " dockerhub_user
    read -s -p "Enter Docker Hub access token: " dockerhub_token
    echo
    
    if [ -n "$dockerhub_user" ] && [ -n "$dockerhub_token" ]; then
        gh secret set DOCKERHUB_USERNAME --body "$dockerhub_user"
        gh secret set DOCKERHUB_TOKEN --body "$dockerhub_token"
        log_success "✅ Docker Hub credentials set"
    fi
    
    # Generate SSH key for EC2
    log_info "Generating SSH key for EC2 access..."
    ssh-keygen -t rsa -b 4096 -f ./ec2-key -N "" -C "github-actions-ec2"
    
    gh secret set EC2_SSH_PRIVATE_KEY --body "$(cat ./ec2-key)"
    
    # Clean up local key files
    rm -f ./ec2-key ./ec2-key.pub
    
    log_success "✅ SSH key generated and set"
}

show_final_instructions() {
    log_info "📋 Final Setup Instructions:"
    echo
    log_info "1. 🔐 GitHub Secrets (if not set automatically):"
    log_info "   Go to: https://github.com/your-username/online-shop/settings/secrets/actions"
    log_info "   Add these secrets:"
    log_info "   - AWS_ACCESS_KEY_ID: Your AWS access key"
    log_info "   - AWS_SECRET_ACCESS_KEY: Your AWS secret key"
    log_info "   - DOCKERHUB_USERNAME: Your Docker Hub username"
    log_info "   - DOCKERHUB_TOKEN: Your Docker Hub access token"
    log_info "   - EC2_SSH_PRIVATE_KEY: SSH private key for EC2 access"
    echo
    log_info "2. 🚀 Deploy Your Application:"
    log_info "   git checkout final"
    log_info "   git merge main  # or your main branch"
    log_info "   git push origin final"
    echo
    log_info "3. 🗑️ Destroy Infrastructure (when needed):"
    log_info "   Go to GitHub Actions → 'Destroy Infrastructure' → Run workflow"
    log_info "   Type 'DESTROY' to confirm"
    echo
    log_info "4. 📊 Monitor Deployment:"
    log_info "   Check GitHub Actions tab for deployment progress"
    log_info "   Access your app at: http://<instance-ip> (shown in workflow output)"
    echo
    log_info "5. 🔧 Customize (optional):"
    log_info "   Edit .github/workflows/deploy.yml for custom settings"
    log_info "   Modify terraform/variables.tf for infrastructure changes"
    echo
}

# Run main function
main "$@"
