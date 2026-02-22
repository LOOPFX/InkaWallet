#!/bin/bash
TOKEN=$(curl -s -X POST "http://localhost:3000/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@inkawallet.com", "password": "admin123"}' | \
  grep -o '"token":"[^"]*' | cut -d'"' -f4)

echo "=== Testing Airtime Purchase ==="
curl -s -X POST "http://localhost:3000/api/services/airtime" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"phone_number":"0999123456","provider":"airtel","amount":500,"password":"admin123"}'
echo ""

echo ""
echo "=== Testing Bill Payment ==="
curl -s -X POST "http://localhost:3000/api/services/bill" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"bill_type":"tv","provider":"DStv","account_number":"TEST123","amount":3000,"password":"admin123"}'
echo ""
