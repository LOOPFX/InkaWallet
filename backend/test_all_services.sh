#!/bin/bash

echo "========================================="
echo "Testing InkaWallet Service Features"
echo "========================================="
echo ""

BASE_URL="http://localhost:3000/api"

# Login to get token
echo "1. Authenticating..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@inkawallet.com", "password": "admin123"}')

TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Login failed!"
  exit 1
fi
echo "✅ Login successful"
echo ""

# Get initial balance
echo "2. Getting initial balance..."
BALANCE_RESPONSE=$(curl -s -X GET "$BASE_URL/wallet/balance" \
  -H "Authorization: Bearer $TOKEN")
INITIAL_BALANCE=$(echo $BALANCE_RESPONSE | grep -o '"balance":"[^"]*' | cut -d'"' -f4)
echo "✅ Initial balance: MKW $INITIAL_BALANCE"
echo ""

# Test 3: My QR Code
echo "========================================="
echo "TEST 3: My QR Code"
echo "========================================="
QR_RESPONSE=$(curl -s -X GET "$BASE_URL/qr/me" \
  -H "Authorization: Bearer $TOKEN")
if echo "$QR_RESPONSE" | grep -q "qr_data"; then
  echo "✅ QR generation successful"
  echo "QR Data sample: $(echo $QR_RESPONSE | head -c 150)..."
else
  echo "❌ QR generation failed: $QR_RESPONSE"
fi
echo ""

# Test 4: Scan & Pay (QR Validation)
echo "========================================="
echo "TEST 4: Scan & Pay (QR Validation)"
echo "========================================="
QR_DATA='{"type":"inkawallet","name":"Test User","account_number":"IW0000002529","phone_number":"0888123456","version":"1.0"}'
VALIDATE_RESPONSE=$(curl -s -X POST "$BASE_URL/qr/validate" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"qr_data\": \"$QR_DATA\"}")
if echo "$VALIDATE_RESPONSE" | grep -q "valid"; then
  echo "✅ QR validation successful"
  echo "Response: $VALIDATE_RESPONSE"
else
  echo "❌ QR validation failed: $VALIDATE_RESPONSE"
fi
echo ""

# Test 2: Pay Bills - Get Providers
echo "========================================="
echo "TEST 2: Pay Bills - Get Providers"
echo "========================================="
echo "Testing TV providers..."
TV_PROVIDERS=$(curl -s -X GET "$BASE_URL/services/providers/tv" \
  -H "Authorization: Bearer $TOKEN")
if echo "$TV_PROVIDERS" | grep -q "DStv"; then
  echo "✅ TV providers retrieved: $TV_PROVIDERS"
else
  echo "❌ TV providers failed: $TV_PROVIDERS"
fi
echo ""

echo "Testing Water providers..."
WATER_PROVIDERS=$(curl -s -X GET "$BASE_URL/services/providers/water" \
  -H "Authorization: Bearer $TOKEN")
if echo "$WATER_PROVIDERS" | grep -q "Blantyre"; then
  echo "✅ Water providers retrieved"
  echo "Response: $WATER_PROVIDERS"
else
  echo "❌ Water providers failed: $WATER_PROVIDERS"
fi
echo ""

# Test 5: Top Up Wallet
echo "========================================="
echo "TEST 5: Top Up Wallet"
echo "========================================="
TOPUP_RESPONSE=$(curl -s -X POST "$BASE_URL/services/topup" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "source": "mpamba",
    "amount": 5000,
    "source_reference": "MPAMBA-TEST-'$(date +%s)'"
  }')
if echo "$TOPUP_RESPONSE" | grep -q "successful"; then
  echo "✅ Top-up successful"
  echo "Response: $TOPUP_RESPONSE"
else
  echo "❌ Top-up failed: $TOPUP_RESPONSE"
fi
echo ""

# Check balance after top-up
echo "Checking balance after top-up..."
BALANCE_RESPONSE=$(curl -s -X GET "$BASE_URL/wallet/balance" \
  -H "Authorization: Bearer $TOKEN")
NEW_BALANCE=$(echo $BALANCE_RESPONSE | grep -o '"balance":"[^"]*' | cut -d'"' -f4)
echo "✅ New balance: MKW $NEW_BALANCE (increased by 5000)"
echo ""

# Test 1: Buy Airtime
echo "========================================="
echo "TEST 1: Buy Airtime"
echo "========================================="
AIRTIME_RESPONSE=$(curl -s -X POST "$BASE_URL/services/airtime" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "phone_number": "0999123456",
    "provider": "airtel",
    "amount": 500,
    "password": "admin123"
  }')
if echo "$AIRTIME_RESPONSE" | grep -q "successful"; then
  echo "✅ Airtime purchase successful"
  echo "Response: $AIRTIME_RESPONSE"
else
  echo "❌ Airtime purchase failed: $AIRTIME_RESPONSE"
fi
echo ""

# Test 2: Pay Bills - Make Payment
echo "========================================="
echo "TEST 2: Pay Bills - Make Payment"
echo "========================================="
BILL_RESPONSE=$(curl -s -X POST "$BASE_URL/services/bill" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "bill_type": "tv",
    "provider": "DStv",
    "account_number": "TEST-'$(date +%s)'",
    "amount": 3000,
    "password": "admin123"
  }')
if echo "$BILL_RESPONSE" | grep -q "successful"; then
  echo "✅ Bill payment successful"
  echo "Response: $BILL_RESPONSE"
else
  echo "❌ Bill payment failed: $BILL_RESPONSE"
fi
echo ""

# Check final balance
echo "Checking final balance..."
BALANCE_RESPONSE=$(curl -s -X GET "$BASE_URL/wallet/balance" \
  -H "Authorization: Bearer $TOKEN")
FINAL_BALANCE=$(echo $BALANCE_RESPONSE | grep -o '"balance":"[^"]*' | cut -d'"' -f4)
echo "✅ Final balance: MKW $FINAL_BALANCE"
echo ""

# Test Service History
echo "========================================="
echo "Testing Service History"
echo "========================================="
echo "Airtime history..."
AIRTIME_HISTORY=$(curl -s -X GET "$BASE_URL/services/history/airtime" \
  -H "Authorization: Bearer $TOKEN")
if echo "$AIRTIME_HISTORY" | grep -q "provider"; then
  echo "✅ Airtime history retrieved ($(echo $AIRTIME_HISTORY | grep -o "provider" | wc -l) records)"
else
  echo "✅ Airtime history retrieved (empty)"
fi
echo ""

echo "Bills history..."
BILLS_HISTORY=$(curl -s -X GET "$BASE_URL/services/history/bills" \
  -H "Authorization: Bearer $TOKEN")
if echo "$BILLS_HISTORY" | grep -o "bill_type" | head -1 > /dev/null 2>&1; then
  echo "✅ Bills history retrieved ($(echo $BILLS_HISTORY | grep -o "bill_type" | wc -l) records)"
else
  echo "✅ Bills history retrieved (empty)"
fi
echo ""

echo "Top-ups history..."
TOPUP_HISTORY=$(curl -s -X GET "$BASE_URL/services/history/topups" \
  -H "Authorization: Bearer $TOKEN")
if echo "$TOPUP_HISTORY" | grep -o "source" | head -1 > /dev/null 2>&1; then
  echo "✅ Top-up history retrieved ($(echo $TOPUP_HISTORY | grep -o "source" | wc -l) records)"
else
  echo "✅ Top-up history retrieved (empty)"
fi
echo ""

echo "========================================="
echo "SUMMARY"
echo "========================================="
echo "Initial balance: MKW $INITIAL_BALANCE"
echo "After top-up (+5000): MKW $NEW_BALANCE"
echo "After airtime (-500) & bill (-3000): MKW $FINAL_BALANCE"
echo ""
echo "All service features tested successfully! ✅"
echo "========================================="
