#!/bin/bash
TOKEN=$(curl -s -X POST "http://localhost:3000/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@inkawallet.com", "password": "admin123"}' | \
  grep -o '"token":"[^"]*' | cut -d'"' -f4)

echo "Testing QR Validation..."
curl -s -X POST "http://localhost:3000/api/qr/validate" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"qr_data":"{\"type\":\"inkawallet\",\"name\":\"Maria Silva\",\"account_number\":\"IW0000002529\",\"phone_number\":\"0888123456\",\"version\":\"1.0\"}"}'
echo ""
