#!/bin/bash

# Python Version Check Script
# Usage: ./check-python.sh

echo "🐍 Python Environment Check"
echo "==========================="

# Check if python3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ python3 is not installed or not in PATH"
    echo "💡 Please install Python 3.8+ (recommended: Python 3.12)"
    exit 1
fi

# Get Python version
PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)

echo "📋 Detected Python version: $PYTHON_VERSION"

# Check version compatibility
if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 8 ]); then
    echo "❌ Python 3.8+ is required for AWS Lambda"
    echo "💡 Current version: $PYTHON_VERSION"
    echo "💡 Please upgrade to Python 3.12 for optimal performance"
    exit 1
fi

# Version-specific messages
if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -eq 12 ]; then
    echo "✅ Python 3.12 - Perfect! This matches the Lambda runtime"
elif [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 11 ]; then
    echo "✅ Python 3.$PYTHON_MINOR - Excellent compatibility"
elif [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 9 ]; then
    echo "✅ Python 3.$PYTHON_MINOR - Good compatibility"
    echo "💡 Consider upgrading to Python 3.12 for best performance"
else
    echo "⚠️  Python 3.$PYTHON_MINOR - Minimum compatibility"
    echo "💡 Strongly recommend upgrading to Python 3.12"
fi

# Check pip
echo ""
echo "📦 Checking pip..."
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 is not available"
    echo "💡 Install with: python3 -m ensurepip --upgrade"
    exit 1
else
    PIP_VERSION=$(pip3 --version | cut -d' ' -f2)
    echo "✅ pip version: $PIP_VERSION"
fi

# Check boto3 availability
echo ""
echo "🔍 Checking AWS SDK (boto3)..."
if python3 -c "import boto3" 2>/dev/null; then
    BOTO3_VERSION=$(python3 -c "import boto3; print(boto3.__version__)" 2>/dev/null)
    echo "✅ boto3 version: $BOTO3_VERSION"
else
    echo "⚠️  boto3 not installed"
    echo "💡 Install with: pip3 install boto3"
fi

# Check virtual environment recommendation
echo ""
echo "🏠 Virtual Environment Check..."
if [ -n "$VIRTUAL_ENV" ]; then
    echo "✅ Virtual environment active: $VIRTUAL_ENV"
else
    echo "💡 Consider using a virtual environment:"
    echo "   python3 -m venv venv"
    echo "   source venv/bin/activate"
    echo "   pip install -r requirements.txt"
fi

echo ""
echo "🎯 Summary:"
echo "==========="
echo "Python Version: $PYTHON_VERSION"
echo "Lambda Runtime: python3.12"
echo "Compatibility: $([ "$PYTHON_MINOR" -ge 12 ] && echo "Perfect" || echo "Compatible")"

if [ "$PYTHON_MINOR" -ge 8 ]; then
    echo ""
    echo "✅ Your Python environment is ready for AWS Lambda development!"
    echo ""
    echo "Next steps:"
    echo "1. Install dependencies: pip3 install -r requirements.txt"
    echo "2. Validate template: ./validate-template.sh"
    echo "3. Deploy: ./deploy-local.sh dev eu-central-1"
else
    echo ""
    echo "❌ Please upgrade Python to version 3.8 or higher"
    exit 1
fi
