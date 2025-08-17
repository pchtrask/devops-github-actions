#!/bin/bash

# SAST (Static Application Security Testing) Script
# This script demonstrates how to run static code analysis using Bandit

echo "=== DevSecOps SAST Demo ==="
echo "Running Static Application Security Testing with Bandit..."
echo

# Install Bandit if not already installed
if ! command -v bandit &> /dev/null; then
    echo "Installing Bandit SAST tool..."
    pip install bandit[toml]
fi

# Create reports directory
mkdir -p reports

# Run Bandit SAST scan
echo "Running Bandit security scan..."
bandit -r . -f json -o reports/bandit-report.json -v
bandit -r . -f txt -o reports/bandit-report.txt -v

echo
echo "SAST scan completed!"
echo "Reports generated:"
echo "- JSON report: reports/bandit-report.json"
echo "- Text report: reports/bandit-report.txt"
echo

# Display summary
echo "=== SAST Results Summary ==="
if [ -f "reports/bandit-report.txt" ]; then
    echo "Found vulnerabilities:"
    grep -E "(High|Medium|Low)" reports/bandit-report.txt | head -10
else
    echo "Report file not found"
fi

echo
echo "=== Common SAST Findings in this Demo App ==="
echo "1. Hardcoded secrets (B105, B106)"
echo "2. SQL injection vulnerabilities (B608)"
echo "3. Command injection (B602, B605)"
echo "4. Insecure deserialization (B301)"
echo "5. Weak cryptographic hashes (B303)"
echo "6. Debug mode enabled (B201)"
echo "7. Insecure random generators"
echo "8. Unsafe YAML loading"
