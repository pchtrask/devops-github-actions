#!/bin/bash

# DevOps Lesson 13 - Secure Database Deployment Script
# This script demonstrates secure deployment practices

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION=${AWS_REGION:-"eu-central-1"}
ENVIRONMENT=${ENVIRONMENT:-"dev"}
PROJECT_NAME="devops-lesson-13"

# Functions
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

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check if GitLeaks is installed
    if ! command -v gitleaks &> /dev/null; then
        log_warning "GitLeaks is not installed. Installing..."
        install_gitleaks
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials are not configured. Please run 'aws configure'."
        exit 1
    fi
    
    log_success "Prerequisites check completed"
}

install_gitleaks() {
    log_info "Installing GitLeaks..."
    
    # Detect OS
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case $ARCH in
        x86_64) ARCH="x64" ;;
        aarch64) ARCH="arm64" ;;
        arm64) ARCH="arm64" ;;
    esac
    
    # Download and install GitLeaks
    GITLEAKS_VERSION="8.18.0"
    DOWNLOAD_URL="https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_${OS}_${ARCH}.tar.gz"
    
    curl -sSL "$DOWNLOAD_URL" | tar -xz -C /tmp
    sudo mv /tmp/gitleaks /usr/local/bin/
    
    log_success "GitLeaks installed successfully"
}

run_security_scan() {
    log_info "Running security scans..."
    
    # Run GitLeaks scan
    log_info "Running GitLeaks scan..."
    if gitleaks detect --config .gitleaks.toml --verbose; then
        log_success "GitLeaks scan passed - no secrets detected"
    else
        log_error "GitLeaks scan failed - secrets detected!"
        exit 1
    fi
    
    # Run Terraform security scan (if Checkov is available)
    if command -v checkov &> /dev/null; then
        log_info "Running Checkov security scan..."
        checkov -d infrastructure/ --framework terraform
    else
        log_warning "Checkov not installed. Skipping Terraform security scan."
    fi
    
    log_success "Security scans completed"
}

prepare_lambda_package() {
    log_info "Preparing Lambda deployment package..."
    
    cd application/
    
    # Create deployment package
    if [ -f function.zip ]; then
        rm function.zip
    fi
    
    # Install dependencies
    pip install -r requirements.txt -t .
    
    # Create zip package
    zip -r function.zip . -x "tests/*" "*.pyc" "__pycache__/*" "*.zip"
    
    cd ..
    
    log_success "Lambda package prepared"
}

deploy_infrastructure() {
    log_info "Deploying infrastructure with Terraform..."
    
    cd infrastructure/
    
    # Initialize Terraform
    terraform init
    
    # Validate configuration
    terraform validate
    
    # Format check
    terraform fmt -check
    
    # Plan deployment
    log_info "Creating Terraform plan..."
    terraform plan -var="environment=$ENVIRONMENT" -var="aws_region=$AWS_REGION" -out=tfplan
    
    # Apply if approved
    read -p "Do you want to apply this plan? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Applying Terraform plan..."
        terraform apply tfplan
        log_success "Infrastructure deployed successfully"
    else
        log_warning "Deployment cancelled by user"
        exit 0
    fi
    
    cd ..
}

deploy_application() {
    log_info "Deploying Lambda function..."
    
    # Get function name from Terraform output
    FUNCTION_NAME=$(cd infrastructure && terraform output -raw lambda_function_name)
    
    # Update Lambda function code
    aws lambda update-function-code \
        --function-name "$FUNCTION_NAME" \
        --zip-file fileb://application/function.zip \
        --region "$AWS_REGION"
    
    log_success "Lambda function deployed successfully"
}

test_deployment() {
    log_info "Testing deployment..."
    
    # Get Lambda function name
    FUNCTION_NAME=$(cd infrastructure && terraform output -raw lambda_function_name)
    
    # Test health endpoint
    log_info "Testing health endpoint..."
    aws lambda invoke \
        --function-name "$FUNCTION_NAME" \
        --payload '{"httpMethod":"GET","path":"/health"}' \
        --region "$AWS_REGION" \
        response.json
    
    if grep -q '"status":"healthy"' response.json; then
        log_success "Health check passed"
    else
        log_error "Health check failed"
        cat response.json
        exit 1
    fi
    
    rm -f response.json
    
    log_success "Deployment tests completed"
}

check_secret_rotation() {
    log_info "Checking secret rotation configuration..."
    
    # Get secret ARN from Terraform output
    SECRET_ARN=$(cd infrastructure && terraform output -raw secret_arn)
    
    # Check rotation status
    ROTATION_STATUS=$(aws secretsmanager describe-secret \
        --secret-id "$SECRET_ARN" \
        --query 'RotationEnabled' \
        --output text \
        --region "$AWS_REGION")
    
    if [ "$ROTATION_STATUS" = "true" ]; then
        log_success "Secret rotation is enabled"
    else
        log_warning "Secret rotation is not enabled"
    fi
}

cleanup() {
    log_info "Cleaning up temporary files..."
    rm -f application/function.zip
    rm -f infrastructure/tfplan
    rm -f response.json
    log_success "Cleanup completed"
}

show_outputs() {
    log_info "Deployment outputs:"
    cd infrastructure/
    terraform output
    cd ..
}

main() {
    log_info "Starting DevOps Lesson 13 deployment..."
    
    # Check prerequisites
    check_prerequisites
    
    # Run security scans
    run_security_scan
    
    # Prepare application
    prepare_lambda_package
    
    # Deploy infrastructure
    deploy_infrastructure
    
    # Deploy application
    deploy_application
    
    # Test deployment
    test_deployment
    
    # Check secret rotation
    check_secret_rotation
    
    # Show outputs
    show_outputs
    
    # Cleanup
    cleanup
    
    log_success "Deployment completed successfully!"
    log_info "Your secure database application is now running with:"
    log_info "- Encrypted RDS PostgreSQL database"
    log_info "- AWS Secrets Manager for credential management"
    log_info "- KMS encryption for data at rest"
    log_info "- Lambda function with VPC security"
    log_info "- Automated secret rotation (if enabled)"
    log_info "- Security scanning with GitLeaks"
}

# Handle script interruption
trap cleanup EXIT

# Run main function
main "$@"
