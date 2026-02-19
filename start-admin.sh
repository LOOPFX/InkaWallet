#!/bin/bash

echo "🌐 Starting InkaWallet Admin Panel..."
echo "======================================"

cd "$(dirname "$0")/admin-web"

echo "✅ Starting admin panel on port 3001..."
npm run dev
