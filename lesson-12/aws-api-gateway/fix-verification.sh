#!/bin/bash

# Quick verification script for SAM template fix
echo "🔍 Verifying SAM template fix..."

# Check if the problematic reference is removed
if grep -q "DevOpsAPIServerlessUsagePlan" template.yaml; then
    echo "❌ Still contains problematic reference: DevOpsAPIServerlessUsagePlan"
    exit 1
else
    echo "✅ Removed problematic reference"
fi

# Check if explicit Usage Plan is created
if grep -q "DevOpsUsagePlan:" template.yaml; then
    echo "✅ Explicit Usage Plan resource found"
else
    echo "❌ Missing explicit Usage Plan resource"
    exit 1
fi

# Check if Usage Plan Key references correct resource
if grep -q "UsagePlanId: !Ref DevOpsUsagePlan" template.yaml; then
    echo "✅ Usage Plan Key references correct resource"
else
    echo "❌ Usage Plan Key reference is incorrect"
    exit 1
fi

# Check for invalid Gateway Response types
if grep -q "FORBIDDEN:" template.yaml; then
    echo "❌ Invalid Gateway Response type: FORBIDDEN (should be ACCESS_DENIED)"
    exit 1
else
    echo "✅ No invalid Gateway Response types found"
fi

# Check for API Key stage dependency issues
if grep -A 5 "DevOpsAPIKey:" template.yaml | grep -q "StageKeys:"; then
    echo "❌ API Key contains StageKeys which can cause stage dependency issues"
    exit 1
else
    echo "✅ API Key doesn't have problematic StageKeys"
fi

# Validate template syntax
echo ""
echo "🔍 Validating template syntax..."
if command -v sam &> /dev/null; then
    sam validate --template template.yaml
    if [ $? -eq 0 ]; then
        echo "✅ Template syntax is valid"
    else
        echo "❌ Template syntax validation failed"
        exit 1
    fi
else
    echo "⚠️  SAM CLI not found, skipping syntax validation"
fi

echo ""
echo "🎉 Template fix verification completed successfully!"
echo ""
echo "Next steps:"
echo "1. Try deployment again: ./deploy-local.sh dev"
echo "2. Or validate with: sam validate --template template.yaml"
echo ""
echo "📋 Gateway Response types reference:"
echo "   - UNAUTHORIZED (401)"
echo "   - ACCESS_DENIED (403) - NOT 'FORBIDDEN'"
echo "   - THROTTLED (429)"
echo "   - INVALID_API_KEY (403)"
