#!/bin/bash

# Quick Setup Script for AWS API Gateway (eu-central-1)
# Usage: ./quick-setup.sh

echo "🚀 Quick Setup for AWS API Gateway"
echo "=================================="
echo "Region: eu-central-1"
echo "Environment: dev"
echo ""

# Step 1: Check Python
echo "Step 1: Checking Python environment..."
./check-python.sh
if [ $? -ne 0 ]; then
    echo "❌ Python check failed. Please fix Python issues first."
    exit 1
fi

echo ""

# Step 2: Configure AWS
echo "Step 2: Configuring AWS for eu-central-1..."
./configure-aws.sh
if [ $? -ne 0 ]; then
    echo "❌ AWS configuration failed. Please fix AWS issues first."
    exit 1
fi

echo ""

# Step 3: Install dependencies
echo "Step 3: Installing Python dependencies..."
if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt --user
    echo "✅ Dependencies installed"
else
    echo "⚠️  requirements.txt not found, skipping dependency installation"
fi

echo ""

# Step 4: Validate template
echo "Step 4: Validating SAM template..."
./validate-template.sh
if [ $? -ne 0 ]; then
    echo "❌ Template validation failed. Please check template.yaml"
    exit 1
fi

echo ""

# Step 5: Deploy
echo "Step 5: Ready to deploy!"
echo "======================="
echo ""
echo "🎯 Everything is ready for deployment to eu-central-1!"
echo ""
echo "Choose your deployment method:"
echo ""
echo "Option 1 - Automated deployment:"
echo "  ./deploy-local.sh dev"
echo ""
echo "Option 2 - Interactive deployment:"
echo "  sam deploy --guided"
echo ""
echo "Option 3 - Manual steps:"
echo "  sam build"
echo "  sam deploy --stack-name devops-api-gateway-dev --region eu-central-1 --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM"
echo ""

# Ask user if they want to deploy now
read -p "🤔 Do you want to deploy now using automated script? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 Starting deployment..."
    ./deploy-local.sh dev
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "🎉 Deployment completed successfully!"
        echo ""
        echo "📋 Next steps:"
        echo "1. Check api-credentials.txt for API URL and Key"
        echo "2. Test API: source api-credentials.txt && curl -H \"X-API-Key: \$API_KEY\" \"\$API_URL/health\""
        echo "3. Run full test suite: ./test-api.sh \"\$API_URL\" \"\$API_KEY\""
        echo "4. Import postman-collection.json to Postman for manual testing"
    else
        echo ""
        echo "❌ Deployment failed. Check the error messages above."
        echo "💡 Try manual deployment: sam deploy --guided"
    fi
else
    echo ""
    echo "✅ Setup completed! You can deploy manually when ready."
fi

echo ""
echo "📚 Useful files:"
echo "================"
echo "- template.yaml           # SAM template"
echo "- samconfig.toml         # SAM configuration"
echo "- api-credentials.txt    # API credentials (after deployment)"
echo "- postman-collection.json # Postman test collection"
echo ""
echo "📞 Need help?"
echo "============="
echo "- Check TROUBLESHOOTING.md for common issues"
echo "- Validate template: ./validate-template.sh"
echo "- Check AWS config: ./configure-aws.sh"
echo "- Check Python: ./check-python.sh"
