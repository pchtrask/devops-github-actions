#!/bin/bash

# API Testing Script for DevOps API Gateway
# Usage: ./test-api.sh [API_URL] [API_KEY]

#set -x

# Configuration
API_URL=${1:-""}
API_KEY=${2:-""}
ENVIRONMENT=${3:-dev}

if [ -z "$API_URL" ] || [ -z "$API_KEY" ]; then
    echo "❌ Usage: $0 <API_URL> <API_KEY> [environment]"
    echo ""
    echo "Example:"
    echo "$0 https://abc123.execute-api.eu-central-1.amazonaws.com/dev your-api-key-here"
    echo ""
    echo "💡 To get API URL and Key from deployed stack:"
    echo "aws cloudformation describe-stacks --stack-name devops-api-gateway-${ENVIRONMENT} --query 'Stacks[0].Outputs'"
    exit 1
fi

echo "🧪 Testing DevOps API Gateway"
echo "============================="
echo "API URL: $API_URL"
echo "API Key: ${API_KEY:0:10}..."
echo "Environment: $ENVIRONMENT"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run test
run_test() {
    local test_name="$1"
    local method="$2"
    local endpoint="$3"
    local data="$4"
    local expected_status="$5"

    echo -e "${BLUE}Testing: $test_name${NC}"

    if [ -n "$data" ]; then
        response=$(curl -s -w "%{http_code}" \
            -X "$method" \
            -H "X-API-Key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$API_URL$endpoint")
    else
        response=$(curl -s -w "%{http_code}" \
            -X "$method" \
            -H "X-API-Key: $API_KEY" \
            "$API_URL$endpoint")
    fi

    http_code="${response: -3}"
    response_body="${response%???}"

    if [ "$http_code" = "$expected_status" ]; then
        echo -e "${GREEN}✅ PASS${NC} - HTTP $http_code"
        if command -v jq &> /dev/null && echo "$response_body" | jq . &> /dev/null; then
            echo "$response_body" | jq '.'
        else
            echo "$response_body"
        fi
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC} - Expected HTTP $expected_status, got HTTP $http_code"
        echo "Response: $response_body"
        ((TESTS_FAILED++))
    fi
    echo ""
}

# Test without API Key (should fail)
echo -e "${YELLOW}🔐 Testing API Key Authentication${NC}"
echo "Testing without API Key (should fail)..."
response=$(curl -s -w "%{http_code}" "$API_URL/health")
http_code="${response: -3}"

if [ "$http_code" = "403" ] || [ "$http_code" = "401" ]; then
    echo -e "${GREEN}✅ PASS${NC} - API Key authentication working (HTTP $http_code)"
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ FAIL${NC} - API Key authentication not working (HTTP $http_code)"
    ((TESTS_FAILED++))
fi
echo ""

# Health Check Tests
echo -e "${YELLOW}🏥 Health Check Tests${NC}"
run_test "Health Check" "GET" "/health" "" "200"

# Users API Tests
echo -e "${YELLOW}👥 Users API Tests${NC}"
run_test "Get All Users (Empty)" "GET" "/users" "" "200"

# Create a test user
USER_DATA='{"name":"Test User","email":"test@example.com","phone":"555-1234","address":{"street":"123 Test St","city":"Test City"}}'
run_test "Create User" "POST" "/users" "$USER_DATA" "201"

# Get users again (should have our test user)
run_test "Get All Users (With Data)" "GET" "/users" "" "200"

# Get specific user (we'll use a mock ID since we don't parse the response)
run_test "Get Non-existent User" "GET" "/users/non-existent-id" "" "404"

# Try to create user with same email (should fail)
run_test "Create Duplicate User" "POST" "/users" "$USER_DATA" "409"

# Create user with invalid data
INVALID_USER='{"name":"","email":"invalid-email"}'
run_test "Create Invalid User" "POST" "/users" "$INVALID_USER" "400"

# Products API Tests
echo -e "${YELLOW}📦 Products API Tests${NC}"
run_test "Get All Products (Empty)" "GET" "/products" "" "200"

# Create a test product
PRODUCT_DATA='{"name":"Test Product","description":"A test product","price":29.99,"category":"Electronics","stock":100,"sku":"TEST-001"}'
run_test "Create Product" "POST" "/products" "$PRODUCT_DATA" "201"

# Get products again
run_test "Get All Products (With Data)" "GET" "/products" "" "200"

# Get specific product (non-existent)
run_test "Get Non-existent Product" "GET" "/products/non-existent-id" "" "404"

# Create product with invalid price
INVALID_PRODUCT='{"name":"Invalid Product","price":-10,"category":"Test"}'
run_test "Create Invalid Product (Negative Price)" "POST" "/products" "$INVALID_PRODUCT" "400"

# Create product with missing required fields
INCOMPLETE_PRODUCT='{"name":"Incomplete Product"}'
run_test "Create Incomplete Product" "POST" "/products" "$INCOMPLETE_PRODUCT" "400"

# Query Parameters Tests
echo -e "${YELLOW}🔍 Query Parameters Tests${NC}"
run_test "Filter Users by Name" "GET" "/users?name=test" "" "200"
run_test "Filter Products by Category" "GET" "/products?category=electronics" "" "200"
run_test "Filter Products by Price Range" "GET" "/products?min_price=10&max_price=50" "" "200"

# Rate Limiting Test (basic)
echo -e "${YELLOW}⚡ Rate Limiting Test${NC}"
echo "Testing rate limiting (sending 10 rapid requests)..."
rate_limit_failures=0
for i in {1..10}; do
    response=$(curl -s -w "%{http_code}" -H "X-API-Key: $API_KEY" "$API_URL/health")
    http_code="${response: -3}"
    if [ "$http_code" = "429" ]; then
        ((rate_limit_failures++))
    fi
    sleep 0.1
done

if [ $rate_limit_failures -gt 0 ]; then
    echo -e "${GREEN}✅ PASS${NC} - Rate limiting detected ($rate_limit_failures/10 requests throttled)"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}⚠️  INFO${NC} - No rate limiting detected (may be configured for higher limits)"
fi
echo ""

# CORS Test
echo -e "${YELLOW}🌐 CORS Test${NC}"
cors_response=$(curl -s -I -H "X-API-Key: $API_KEY" -H "Origin: https://example.com" "$API_URL/health")
if echo "$cors_response" | grep -i "access-control-allow-origin" > /dev/null; then
    echo -e "${GREEN}✅ PASS${NC} - CORS headers present"
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ FAIL${NC} - CORS headers missing"
    ((TESTS_FAILED++))
fi
echo ""

# Performance Test
echo -e "${YELLOW}⚡ Performance Test${NC}"
echo "Testing response times (5 requests)..."
total_time=0
for i in {1..5}; do
    start_time=$(date +%s%N)
    curl -s -H "X-API-Key: $API_KEY" "$API_URL/health" > /dev/null
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
    total_time=$((total_time + duration))
    echo "Request $i: ${duration}ms"
done

avg_time=$((total_time / 5))
if [ $avg_time -lt 2000 ]; then
    echo -e "${GREEN}✅ PASS${NC} - Average response time: ${avg_time}ms (< 2000ms)"
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ FAIL${NC} - Average response time: ${avg_time}ms (>= 2000ms)"
    ((TESTS_FAILED++))
fi
echo ""

# Summary
echo -e "${BLUE}📊 Test Summary${NC}"
echo "==============="
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo -e "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed!${NC}"
    exit 1
fi
