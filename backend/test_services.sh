#!/bin/bash

# Test script for new service features
# Make sure backend server is running first!

BASE_URL="http://localhost:3000/api"

# Login to get token (using existing admin user)
echo "=== Logging in ==="
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@inkawallet.com", "password": "admin123"}')

TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)
echo "Token: ${TOKEN:0:50}..."

if [ -z "$TOKEN" ]; then
  echo "Login failed!"
  exit 1
fi

echo ""
echo "=== Testing QR Generation ==="
curl -s -X GET "$BASE_URL/qr/me" \
  -H "Authorization: Bearer $TOKEN" | head -c 200
echo ""

echo ""
echo "=== Testing Bill Providers (TV) ==="
curl -s -X GET "$BASE_URL/services/providers/tv" \
  -H "Authorization: Bearer $TOKEN"
echo ""

echo ""
echo "=== Testing Bill Providers (Water) ==="
curl -s -X GET "$BASE_URL/services/providers/water" \
  -H "Authorization: Bearer $TOKEN"
echo ""

echo ""
echo "=== Testing Airtime Purchase ==="
curl -s -X POST "$BASE_URL/services/airtime" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "phone_number": "0999123456",
    "provider": "airtel",
    "amount": 500,
    "password": "admin123"
  }'
echo ""

echo ""
echo "=== Testing Bill Payment ==="
curl -s -X POST "$BASE_URL/services/bill" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "bill_type": "tv",
    "provider": "DStv",
    "account_number": "12345678",
    "amount": 5000,
    "password": "admin123"
  }'
echo ""

echo ""
echo "=== Testing Top-up ==="
curl -s -X POST "$BASE_URL/services/topup" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "source": "mpamba",
    "amount": 10000,
    "source_reference": "MPAMBA123456789"
  }'
echo ""

echo ""
echo "=== Testing Airtime History ==="
curl -s -X GET "$BASE_URL/services/history/airtime" \
  -H "Authorization: Bearer $TOKEN" | head -c 300
echo ""

echo ""
echo "=== All tests completed! ==="
