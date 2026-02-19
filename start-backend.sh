#!/bin/bash

echo "🚀 Starting InkaWallet Backend API..."
echo "======================================"

cd "$(dirname "$0")"

# Check if database is configured
if ! mysql -u root -e "USE inkawallet_db" 2>/dev/null; then
    echo "⚠️  Database not found! Please run:"
    echo "   mysql -u root -p < backend/database/schema.sql"
    echo ""
    read -p "Press Enter to continue anyway..."
fi

# Start backend
echo "✅ Starting backend on port 3000..."
cd backend
npm run dev
