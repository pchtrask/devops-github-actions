#!/bin/bash

# AWS API Gateway SAM Deployment Script
# Usage: ./deploy.sh [environment] [region]

set -e

# Configuration
ENVIRONMENT=${1:-dev}
REGION=${2:-eu-central-1}
STACK_NAME="devops-api-gateway-${ENVIRONMENT}"
S3_BUCKET="devops-sam-deployments-${REGION}-$(date +%s)"

echo "🚀 Deploying DevOps API Gateway"
echo "================================"
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo "Stack Name: $STACK_NAME"
echo ""

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
    if [ "$REGION" = "eu-central-1" ]; then
        aws s3 mb "s3://$S3_BUCKET"
    else
        aws s3 mb "s3://$S3_BUCKET" --region "$REGION"
    fi
    echo "✅ Created S3 bucket: $S3_BUCKET"
else
    echo "✅ S3 bucket already exists: $S3_BUCKET"
fi

# Build the SAM application
echo ""
echo "🔨 Building SAM application..."
sam build

if [ $? -ne 0 ]; then
    echo "❌ SAM build failed"
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
    --confirm-changeset \
    --no-fail-on-empty-changeset

if [ $? -ne 0 ]; then
    echo "❌ SAM deployment failed"
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

# Test the deployment
echo "🧪 Testing the deployment..."
echo ""

# Test health endpoint
echo "Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s -w "%{http_code}" \
    -H "X-API-Key: $API_KEY_VALUE" \
    "$API_URL/health")

HTTP_CODE="${HEALTH_RESPONSE: -3}"
RESPONSE_BODY="${HEALTH_RESPONSE%???}"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Health check passed"
    echo "Response: $RESPONSE_BODY" | jq '.' 2>/dev/null || echo "$RESPONSE_BODY"
else
    echo "❌ Health check failed (HTTP $HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
fi

echo ""

# Test users endpoint
echo "Testing users endpoint..."
USERS_RESPONSE=$(curl -s -w "%{http_code}" \
    -H "X-API-Key: $API_KEY_VALUE" \
    "$API_URL/users")

HTTP_CODE="${USERS_RESPONSE: -3}"
RESPONSE_BODY="${USERS_RESPONSE%???}"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Users endpoint test passed"
    echo "Response: $RESPONSE_BODY" | jq '.' 2>/dev/null || echo "$RESPONSE_BODY"
else
    echo "❌ Users endpoint test failed (HTTP $HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
fi

echo ""

# Test products endpoint
echo "Testing products endpoint..."
PRODUCTS_RESPONSE=$(curl -s -w "%{http_code}" \
    -H "X-API-Key: $API_KEY_VALUE" \
    "$API_URL/products")

HTTP_CODE="${PRODUCTS_RESPONSE: -3}"
RESPONSE_BODY="${PRODUCTS_RESPONSE%???}"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Products endpoint test passed"
    echo "Response: $RESPONSE_BODY" | jq '.' 2>/dev/null || echo "$RESPONSE_BODY"
else
    echo "❌ Products endpoint test failed (HTTP $HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
fi

echo ""
echo "📝 Example API calls:"
echo "===================="
echo ""
echo "# Health check"
echo "curl -H \"X-API-Key: $API_KEY_VALUE\" \"$API_URL/health\""
echo ""
echo "# Get all users"
echo "curl -H \"X-API-Key: $API_KEY_VALUE\" \"$API_URL/users\""
echo ""
echo "# Create a user"
echo "curl -X POST -H \"X-API-Key: $API_KEY_VALUE\" -H \"Content-Type: application/json\" \\"
echo "  -d '{\"name\":\"John Doe\",\"email\":\"john@example.com\"}' \\"
echo "  \"$API_URL/users\""
echo ""
echo "# Get all products"
echo "curl -H \"X-API-Key: $API_KEY_VALUE\" \"$API_URL/products\""
echo ""
echo "# Create a product"
echo "curl -X POST -H \"X-API-Key: $API_KEY_VALUE\" -H \"Content-Type: application/json\" \\"
echo "  -d '{\"name\":\"Test Product\",\"price\":29.99,\"category\":\"Electronics\"}' \\"
echo "  \"$API_URL/products\""
echo ""
echo "🔧 Management commands:"
echo "======================"
echo ""
echo "# View stack resources"
echo "aws cloudformation describe-stack-resources --stack-name $STACK_NAME --region $REGION"
echo ""
echo "# View CloudWatch logs"
echo "aws logs describe-log-groups --log-group-name-prefix '/aws/lambda/devops-api' --region $REGION"
echo ""
echo "# Delete the stack"
echo "aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION"
echo ""
echo "✅ Deployment completed successfully!"
