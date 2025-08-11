#!/bin/bash

# Local JMeter Test Runner for Lesson 9
# Usage: ./run-local-test.sh [URL]

set -e

# Default URL if none provided
DEFAULT_URL="https://httpbin.org/get"
TEST_URL="${1:-$DEFAULT_URL}"

echo "🚀 Starting JMeter Performance Test"
echo "📍 Target URL: $TEST_URL"
echo "⏱️  Duration: 60 seconds"
echo "👥 Virtual Users: 5"
echo ""

# Check if JMeter is installed
if ! command -v jmeter &> /dev/null; then
    echo "❌ JMeter is not installed or not in PATH"
    echo "Please install JMeter and ensure it's available in your PATH"
    echo "Download from: https://jmeter.apache.org/download_jmeter.cgi"
    exit 1
fi

# Create results directory
mkdir -p results reports

# Run the test
echo "🔄 Running JMeter test..."
jmeter -n \
    -t performance-test.jmx \
    -l results/results.jtl \
    -e \
    -o reports/ \
    -Jtest.url="$TEST_URL"

echo ""
echo "✅ Test completed successfully!"
echo "📊 Results saved to:"
echo "   - Raw results: results/results.jtl"
echo "   - HTML report: reports/index.html"
echo ""
echo "🌐 Open the HTML report in your browser:"
echo "   file://$(pwd)/reports/index.html"
