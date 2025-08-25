#!/bin/bash

# AWS Configuration Script for eu-central-1
# Usage: ./configure-aws.sh

echo "🌍 AWS Configuration for eu-central-1"
echo "====================================="

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed"
    echo "💡 Install with:"
    echo "   # macOS"
    echo "   brew install awscli"
    echo "   # Ubuntu/Debian"
    echo "   sudo apt install awscli"
    echo "   # pip"
    echo "   pip install awscli"
    exit 1
fi

echo "✅ AWS CLI is installed"
AWS_VERSION=$(aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2)
echo "📋 AWS CLI version: $AWS_VERSION"

# Check current configuration
echo ""
echo "🔍 Current AWS Configuration:"
echo "=============================="

CURRENT_REGION=$(aws configure get region 2>/dev/null || echo "not set")
CURRENT_PROFILE=$(aws configure get profile 2>/dev/null || echo "default")

echo "Current region: $CURRENT_REGION"
echo "Current profile: $CURRENT_PROFILE"

# Check if credentials are configured
if aws sts get-caller-identity &>/dev/null; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
    echo "✅ AWS credentials are configured"
    echo "Account ID: $ACCOUNT_ID"
    echo "User/Role: $USER_ARN"
else
    echo "❌ AWS credentials are not configured"
    echo ""
    echo "💡 Configure AWS credentials:"
    echo "   aws configure"
    echo ""
    echo "You'll need:"
    echo "- AWS Access Key ID"
    echo "- AWS Secret Access Key"
    echo "- Default region: eu-central-1"
    echo "- Default output format: json"
    exit 1
fi

# Set region to eu-central-1 if different
if [ "$CURRENT_REGION" != "eu-central-1" ]; then
    echo ""
    echo "🌍 Setting default region to eu-central-1..."
    aws configure set region eu-central-1
    echo "✅ Default region updated to eu-central-1"
else
    echo "✅ Region is already set to eu-central-1"
fi

# Verify region-specific services
echo ""
echo "🔍 Verifying eu-central-1 services..."
echo "====================================="

# Test S3 access
echo "Testing S3 access..."
if aws s3 ls --region eu-central-1 &>/dev/null; then
    echo "✅ S3 access working"
else
    echo "⚠️  S3 access issues (may be permissions)"
fi

# Test CloudFormation access
echo "Testing CloudFormation access..."
if aws cloudformation list-stacks --region eu-central-1 --max-items 1 &>/dev/null; then
    echo "✅ CloudFormation access working"
else
    echo "⚠️  CloudFormation access issues (may be permissions)"
fi

# Test Lambda access
echo "Testing Lambda access..."
if aws lambda list-functions --region eu-central-1 --max-items 1 &>/dev/null; then
    echo "✅ Lambda access working"
else
    echo "⚠️  Lambda access issues (may be permissions)"
fi

# Test API Gateway access
echo "Testing API Gateway access..."
if aws apigateway get-rest-apis --region eu-central-1 --limit 1 &>/dev/null; then
    echo "✅ API Gateway access working"
else
    echo "⚠️  API Gateway access issues (may be permissions)"
fi

# Test DynamoDB access
echo "Testing DynamoDB access..."
if aws dynamodb list-tables --region eu-central-1 --limit 1 &>/dev/null; then
    echo "✅ DynamoDB access working"
else
    echo "⚠️  DynamoDB access issues (may be permissions)"
fi

echo ""
echo "🎯 Configuration Summary:"
echo "========================"
echo "Region: eu-central-1"
echo "Account: $ACCOUNT_ID"
echo "Profile: $CURRENT_PROFILE"

echo ""
echo "✅ AWS is configured for eu-central-1!"
echo ""
echo "Next steps:"
echo "1. Check Python environment: ./check-python.sh"
echo "2. Validate SAM template: ./validate-template.sh"
echo "3. Deploy to eu-central-1: ./deploy-local.sh dev"
echo ""
echo "💡 Useful commands:"
echo "   aws configure list                    # Show current config"
echo "   aws sts get-caller-identity          # Show current user/role"
echo "   aws s3 ls --region eu-central-1      # Test S3 access"
