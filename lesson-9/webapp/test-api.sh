#!/bin/bash

# API Testing Script for Manual Verification
set -e

API_URL="${1:-http://localhost:3000}"
echo "🧪 Testing DevOps Demo API at: $API_URL"
echo "============================================"

# Test 1: Health Check
echo ""
echo "1️⃣  Testing Health Endpoint..."
HEALTH_RESPONSE=$(curl -s "$API_URL/health")
if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    echo "✅ Health check passed"
else
    echo "❌ Health check failed"
    echo "Response: $HEALTH_RESPONSE"
fi

# Test 2: API Root
echo ""
echo "2️⃣  Testing API Root..."
ROOT_RESPONSE=$(curl -s "$API_URL/")
if echo "$ROOT_RESPONSE" | grep -q "DevOps Demo API"; then
    echo "✅ API root endpoint working"
else
    echo "❌ API root endpoint failed"
    echo "Response: $ROOT_RESPONSE"
fi

# Test 3: Get Users
echo ""
echo "3️⃣  Testing Get Users..."
USERS_RESPONSE=$(curl -s "$API_URL/api/users")
if echo "$USERS_RESPONSE" | grep -q "users"; then
    echo "✅ Get users endpoint working"
    USER_COUNT=$(echo "$USERS_RESPONSE" | grep -o '"count":[0-9]*' | cut -d':' -f2)
    echo "   📊 Current user count: $USER_COUNT"
else
    echo "❌ Get users endpoint failed"
    echo "Response: $USERS_RESPONSE"
fi

# Test 4: Create User
echo ""
echo "4️⃣  Testing Create User..."
NEW_USER_DATA='{"name":"Test User","email":"test@example.com"}'
CREATE_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$NEW_USER_DATA" "$API_URL/api/users")

if echo "$CREATE_RESPONSE" | grep -q '"id"'; then
    echo "✅ Create user endpoint working"
    USER_ID=$(echo "$CREATE_RESPONSE" | grep -o '"id":[0-9]*' | cut -d':' -f2)
    echo "   🆔 Created user ID: $USER_ID"
    
    # Test 5: Get Specific User
    echo ""
    echo "5️⃣  Testing Get Specific User..."
    GET_USER_RESPONSE=$(curl -s "$API_URL/api/users/$USER_ID")
    if echo "$GET_USER_RESPONSE" | grep -q "Test User"; then
        echo "✅ Get specific user endpoint working"
    else
        echo "❌ Get specific user endpoint failed"
        echo "Response: $GET_USER_RESPONSE"
    fi
    
    # Test 6: Update User
    echo ""
    echo "6️⃣  Testing Update User..."
    UPDATE_DATA='{"name":"Updated Test User","active":false}'
    UPDATE_RESPONSE=$(curl -s -X PUT -H "Content-Type: application/json" -d "$UPDATE_DATA" "$API_URL/api/users/$USER_ID")
    if echo "$UPDATE_RESPONSE" | grep -q "Updated Test User"; then
        echo "✅ Update user endpoint working"
    else
        echo "❌ Update user endpoint failed"
        echo "Response: $UPDATE_RESPONSE"
    fi
    
    # Test 7: Delete User
    echo ""
    echo "7️⃣  Testing Delete User..."
    DELETE_RESPONSE=$(curl -s -X DELETE "$API_URL/api/users/$USER_ID" -w "%{http_code}")
    if [[ "$DELETE_RESPONSE" == "204" ]]; then
        echo "✅ Delete user endpoint working"
    else
        echo "❌ Delete user endpoint failed"
        echo "Response code: $DELETE_RESPONSE"
    fi
    
    # Test 8: Verify Deletion
    echo ""
    echo "8️⃣  Verifying User Deletion..."
    VERIFY_DELETE=$(curl -s "$API_URL/api/users/$USER_ID" -w "%{http_code}")
    if [[ "$VERIFY_DELETE" == *"404" ]]; then
        echo "✅ User successfully deleted"
    else
        echo "❌ User deletion verification failed"
        echo "Response: $VERIFY_DELETE"
    fi
    
else
    echo "❌ Create user endpoint failed"
    echo "Response: $CREATE_RESPONSE"
fi

# Test 9: Error Handling
echo ""
echo "9️⃣  Testing Error Handling..."
ERROR_RESPONSE=$(curl -s "$API_URL/api/nonexistent" -w "%{http_code}")
if [[ "$ERROR_RESPONSE" == *"404" ]]; then
    echo "✅ 404 error handling working"
else
    echo "❌ 404 error handling failed"
    echo "Response: $ERROR_RESPONSE"
fi

# Test 10: Filter Users
echo ""
echo "🔟 Testing User Filtering..."
FILTER_RESPONSE=$(curl -s "$API_URL/api/users?active=true")
if echo "$FILTER_RESPONSE" | grep -q "users"; then
    echo "✅ User filtering working"
    ACTIVE_COUNT=$(echo "$FILTER_RESPONSE" | grep -o '"count":[0-9]*' | cut -d':' -f2)
    echo "   📊 Active users count: $ACTIVE_COUNT"
else
    echo "❌ User filtering failed"
    echo "Response: $FILTER_RESPONSE"
fi

echo ""
echo "🎉 API testing complete!"
echo ""
echo "💡 Usage examples:"
echo "   • Health check: curl $API_URL/health"
echo "   • List users: curl $API_URL/api/users"
echo "   • Create user: curl -X POST -H 'Content-Type: application/json' -d '{\"name\":\"John\",\"email\":\"john@test.com\"}' $API_URL/api/users"
echo "   • Get user: curl $API_URL/api/users/1"
echo "   • Update user: curl -X PUT -H 'Content-Type: application/json' -d '{\"name\":\"Updated\"}' $API_URL/api/users/1"
echo "   • Delete user: curl -X DELETE $API_URL/api/users/1"
