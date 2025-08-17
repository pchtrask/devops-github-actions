#!/bin/bash

# DAST (Dynamic Application Security Testing) Script
# This script demonstrates how to run dynamic security testing using OWASP ZAP

echo "=== DevSecOps DAST Demo ==="
echo "Running Dynamic Application Security Testing with OWASP ZAP..."
echo

# Check if the application is running
APP_URL="http://172.22.86.174:5000"
if ! curl -s "$APP_URL" > /dev/null; then
    echo "Application is not running at $APP_URL"
    echo "Please start the application first:"
    echo "  python app.py"
    echo "Or using Docker:"
    echo "  docker build -t vulnerable-app ."
    echo "  docker run -p 5000:5000 vulnerable-app"
    exit 1
fi

# Create reports directory
mkdir -p reports

echo "Application is running at $APP_URL"
echo "Starting OWASP ZAP scan..."

# Check if ZAP is available via Docker
if command -v docker &> /dev/null; then
    echo "Running OWASP ZAP via Docker..."
    
    # -t owasp/zap2docker-stable zap-baseline.py \
    # Run ZAP baseline scan
    docker run -v $(pwd)/reports:/zap/wrk/:rw \
        -t zaproxy/zap-stable zap-baseline.py \
        -t $APP_URL \
        -J zap-baseline-report.json \
        -r zap-baseline-report.html \
        -x zap-baseline-report.xml || true
    


    # # Run ZAP full scan (more comprehensive but takes longer)
    echo "Running ZAP full scan..."
    docker run -v $(pwd)/reports:/zap/wrk/:rw \
        -t zaproxy/zap-stable zap-full-scan.py \
        -t $APP_URL \
        -J zap-full-report.json \
        -r zap-full-report.html \
        -x zap-full-report.xml || true
        
elif command -v zap.sh &> /dev/null; then
    echo "Running OWASP ZAP locally..."
    
    # Run ZAP in daemon mode and perform scan
    zap.sh -daemon -port 8080 -config api.disablekey=true &
    ZAP_PID=$!
    
    # Wait for ZAP to start
    sleep 10
    
    # Spider the application
    curl "http://localhost:8080/JSON/spider/action/scan/?url=$APP_URL"
    
    # Wait for spider to complete
    sleep 30
    
    # Run active scan
    curl "http://localhost:8080/JSON/ascan/action/scan/?url=$APP_URL"
    
    # Wait for scan to complete
    sleep 60
    
    # Generate reports
    curl "http://localhost:8080/JSON/core/view/htmlreport/" > reports/zap-report.html
    curl "http://localhost:8080/JSON/core/view/jsonreport/" > reports/zap-report.json
    
    # Stop ZAP
    kill $ZAP_PID
    
else
    echo "OWASP ZAP not found. Please install it or use Docker."
    echo "Docker installation: docker pull owasp/zap2docker-stable"
    echo "Local installation: https://www.zaproxy.org/download/"
    exit 1
fi

echo
echo "DAST scan completed!"
echo "Reports generated in reports/ directory"

echo
echo "=== DAST Test Scenarios ==="
echo "You can manually test these vulnerabilities:"
echo
echo "1. SQL Injection:"
echo "   curl '$APP_URL/api/users?id=1 OR 1=1'"
echo
echo "2. XSS:"
echo "   curl '$APP_URL/api/search?q=<script>alert(1)</script>'"
echo
echo "3. Command Injection:"
echo "   curl -X POST -H 'Content-Type: application/json' \\"
echo "        -d '{\"command\":\"ls -la\"}' $APP_URL/api/execute"
echo
echo "4. SSRF:"
echo "   curl -X POST -H 'Content-Type: application/json' \\"
echo "        -d '{\"url\":\"http://localhost:22\"}' $APP_URL/api/proxy"
echo
echo "5. Information Disclosure:"
echo "   curl '$APP_URL/api/debug'"
