#!/bin/bash

# SAM Template Validation Script
# Usage: ./validate-template.sh

echo "🔍 Validating SAM template..."

# Check if SAM CLI is installed
if ! command -v sam &> /dev/null; then
    echo "❌ SAM CLI is not installed. Please install it first."
    exit 1
fi

# Validate template syntax
echo "📋 Checking template syntax..."
sam validate --template template.yaml

if [ $? -eq 0 ]; then
    echo "✅ Template syntax is valid"
else
    echo "❌ Template syntax validation failed"
    exit 1
fi

# Try to build (dry run)
echo ""
echo "🔨 Testing build process..."
sam build --cached

if [ $? -eq 0 ]; then
    echo "✅ Build test successful"
    echo ""
    echo "📁 Build artifacts created in .aws-sam/build/"
    ls -la .aws-sam/build/
else
    echo "❌ Build test failed"
    exit 1
fi

echo ""
echo "🎉 Template validation completed successfully!"
echo ""
echo "Next steps:"
echo "1. Deploy with: ./deploy-local.sh dev us-east-1"
echo "2. Or use SAM CLI: sam deploy --guided"
