#!/bin/bash

# AWS API Gateway SAM Deployment Script (Local Build)
# Usage: ./deploy-local.sh [environment] [region]

set -e

# Configuration
ENVIRONMENT=${1:-dev}
REGION=${2:-eu-central-1}
STACK_NAME="devops-api-gateway-${ENVIRONMENT}"

echo "🚀 Deploying DevOps API Gateway (Local Build)"
echo "=============================================="
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo "Stack Name: $STACK_NAME"
echo ""

# Check Python version
echo "🐍 Checking Python version..."
PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
echo "Python version: $PYTHON_VERSION"

if [[ "$PYTHON_VERSION" < "3.8" ]]; then
    echo "❌ Python 3.8+ is required for AWS Lambda. Current version: $PYTHON_VERSION"
    echo "💡 Python 3.12 is recommended for best performance"
    exit 1
fi

if [[ "$PYTHON_VERSION" == "3.12" ]]; then
    echo "✅ Python 3.12 detected - optimal for Lambda runtime"
elif [[ "$PYTHON_VERSION" > "3.11" ]]; then
    echo "✅ Python $PYTHON_VERSION detected - compatible with Lambda"
else
    echo "⚠️  Python $PYTHON_VERSION detected - consider upgrading to 3.12 for best performance"
fi

# Check if required Python packages are available
echo "📦 Checking Python dependencies..."
python3 -c "import boto3, json, uuid, os, datetime, decimal" 2>/dev/null || {
    echo "❌ Required Python packages not found. Installing boto3..."
    pip3 install boto3 --user
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if SAM CLI is installed
if ! command -v sam &> /dev/null; then
    echo "❌ SAM CLI is not installed. Please install it first."
    echo "💡 Install with: pip install aws-sam-cli"
    exit 1
fi

# Check AWS credentials
echo "🔐 Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "✅ AWS Account: $ACCOUNT_ID"
echo ""

# Create S3 bucket for SAM artifacts (if it doesn't exist)
echo "📦 Creating S3 bucket for SAM artifacts..."
S3_BUCKET="devops-sam-deployments-${ACCOUNT_ID}-${REGION}"

if ! aws s3 ls "s3://$S3_BUCKET" 2>/dev/null; then
    if [ "$REGION" = "us-east-1" ]; then
        aws s3 mb "s3://$S3_BUCKET"
    else
        aws s3 mb "s3://$S3_BUCKET" --region "$REGION"
    fi
    echo "✅ Created S3 bucket: $S3_BUCKET"
else
    echo "✅ S3 bucket already exists: $S3_BUCKET"
fi

# Build the SAM application (without container)
echo ""
echo "🔨 Building SAM application (local build)..."
sam build

if [ $? -ne 0 ]; then
    echo "❌ SAM build failed"
    echo "💡 Try installing dependencies manually:"
    echo "   pip3 install boto3 --user"
    exit 1
fi

echo "✅ SAM build completed"

# Deploy the SAM application
echo ""
echo "🚀 Deploying SAM application..."
sam deploy \
    --stack-name "$STACK_NAME" \
    --s3-bucket "$S3_BUCKET" \
    --region "$REGION" \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --parameter-overrides \
        Environment="$ENVIRONMENT" \
        ApiKeyName="DevOpsAPIKey-${ENVIRONMENT}" \
    --no-confirm-changeset \
    --no-fail-on-empty-changeset

if [ $? -ne 0 ]; then
    echo "❌ SAM deployment failed"
    echo "💡 Check CloudFormation console for detailed error messages"
    exit 1
fi

echo "✅ SAM deployment completed"

# Get stack outputs
echo ""
echo "📋 Getting stack outputs..."
API_URL=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
    --output text)

API_KEY_ID=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiKeyId`].OutputValue' \
    --output text)

# Get the actual API key value
echo "🔑 Retrieving API Key..."
API_KEY_VALUE=$(aws apigateway get-api-key \
    --api-key "$API_KEY_ID" \
    --include-value \
    --region "$REGION" \
    --query 'value' \
    --output text)

echo ""
echo "🎉 Deployment Successful!"
echo "========================"
echo "API Gateway URL: $API_URL"
echo "API Key ID: $API_KEY_ID"
echo "API Key Value: $API_KEY_VALUE"
echo ""

# Save credentials to file for easy access
cat > api-credentials.txt << EOF
API_URL=$API_URL
API_KEY=$API_KEY_VALUE
ENVIRONMENT=$ENVIRONMENT
REGION=$REGION
EOF

echo "💾 API credentials saved to: api-credentials.txt"
echo ""

# Test the deployment
echo "🧪 Testing the deployment..."
echo ""

# Test health endpoint
echo "Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s -w "%{http_code}" \
    -H "X-API-Key: $API_KEY_VALUE" \
    "$API_URL/health" 2>/dev/null || echo "000")

if [[ "$HEALTH_RESPONSE" == *"200" ]]; then
    echo "✅ Health check passed"
    HTTP_CODE="${HEALTH_RESPONSE: -3}"
    RESPONSE_BODY="${HEALTH_RESPONSE%???}"
    echo "Response: $RESPONSE_BODY" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE_BODY"
else
    echo "❌ Health check failed"
    echo "Response: $HEALTH_RESPONSE"
fi

echo ""
echo "📝 Quick test commands:"
echo "======================"
echo ""
echo "# Source credentials"
echo "source api-credentials.txt"
echo ""
echo "# Health check"
echo "curl -H \"X-API-Key: \$API_KEY\" \"\$API_URL/health\""
echo ""
echo "# Get users"
echo "curl -H \"X-API-Key: \$API_KEY\" \"\$API_URL/users\""
echo ""
echo "# Create user"
echo "curl -X POST -H \"X-API-Key: \$API_KEY\" -H \"Content-Type: application/json\" \\"
echo "  -d '{\"name\":\"Test User\",\"email\":\"test@example.com\"}' \\"
echo "  \"\$API_URL/users\""
echo ""
echo "# Run full test suite"
echo "./test-api.sh \"\$API_URL\" \"\$API_KEY\""
echo ""
echo "✅ Deployment completed successfully!"
