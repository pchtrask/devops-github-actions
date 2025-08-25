#!/bin/bash

# Deployment script for secure infrastructure with NAT instance
set -e

echo "🚀 Deploying secure infrastructure with NAT instance..."

# Check if key pair name is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <key-pair-name>"
    echo "Example: $0 my-ec2-keypair"
    echo ""
    echo "Note: The key pair must already exist in your AWS account."
    echo "You can create one in the EC2 console or using AWS CLI:"
    echo "aws ec2 create-key-pair --key-name my-ec2-keypair --query 'KeyMaterial' --output text > my-ec2-keypair.pem"
    exit 1
fi

KEY_PAIR_NAME="$1"

echo "📋 Using key pair: $KEY_PAIR_NAME"

# Validate Terraform configuration
echo "🔍 Validating Terraform configuration..."
terraform validate

# Plan the deployment
echo "📝 Planning deployment..."
terraform plan -var="key_pair_name=$KEY_PAIR_NAME"

# Ask for confirmation
echo ""
read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled."
    exit 1
fi

# Apply the configuration
echo "🏗️  Applying Terraform configuration..."
terraform apply -var="key_pair_name=$KEY_PAIR_NAME" -auto-approve

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "📊 Infrastructure Summary:"
terraform output

echo ""
echo "🔧 NAT Instance Information:"
echo "- The NAT instance provides internet access for Lambda functions in private subnets"
echo "- Lambda can now reach AWS APIs (Secrets Manager, KMS, S3, etc.)"
echo "- SSH access to NAT instance: ssh -i $KEY_PAIR_NAME.pem ec2-user@\$(terraform output -raw nat_instance_public_ip)"
echo ""
echo "🧪 Testing Lambda function:"
echo "aws lambda invoke --function-name secure-db-function --payload '{}' response.json"
echo ""
