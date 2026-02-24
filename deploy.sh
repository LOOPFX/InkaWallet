#!/bin/bash

# InkaWallet Production Deployment Script
# This script guides you through deploying to Render.com

set -e

echo "🚀 InkaWallet Production Deployment"
echo "===================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Push to GitHub
echo -e "${BLUE}Step 1: Pushing code to GitHub...${NC}"
git push origin dev
echo -e "${GREEN}✅ Code pushed to GitHub${NC}"
echo ""

# Step 2: Instructions for Render
echo -e "${YELLOW}Step 2: Deploy to Render.com${NC}"
echo ""
echo "🌐 Open: https://dashboard.render.com/"
echo ""
echo "OPTION A - Automated (Recommended):"
echo "  1. Click 'New +' → 'Blueprint'"
echo "  2. Select your InkaWallet repository"
echo "  3. Render will detect render.yaml"
echo "  4. Click 'Apply'"
echo "  5. Add DB_PASSWORD in backend environment (get from Aiven dashboard)"
echo ""
echo "OPTION B - Manual:"
echo "  See RENDER_DEPLOYMENT.md for detailed steps"
echo ""

read -p "Press Enter when backend is deployed and you have the URL..."

# Step 3: Get backend URL
echo ""
echo -e "${BLUE}Step 3: Backend URL${NC}"
read -p "Enter your backend URL (e.g., https://inkawallet-backend.onrender.com): " BACKEND_URL

# Validate URL
if [[ ! "$BACKEND_URL" =~ ^https:// ]]; then
  echo -e "${YELLOW}⚠️  URL should start with https://${NC}"
  read -p "Enter correct URL: " BACKEND_URL
fi

# Step 4: Verify backend
echo ""
echo -e "${BLUE}Step 4: Verifying backend...${NC}"
HEALTH_CHECK="${BACKEND_URL}/api/health"
echo "Testing: $HEALTH_CHECK"

if curl -s "$HEALTH_CHECK" | grep -q "OK"; then
  echo -e "${GREEN}✅ Backend is running!${NC}"
else
  echo -e "${YELLOW}⚠️  Backend health check failed. Continue anyway? (y/n)${NC}"
  read -p "" continue
  if [[ "$continue" != "y" ]]; then
    exit 1
  fi
fi

# Step 5: Admin deployment
echo ""
echo -e "${YELLOW}Step 5: Deploy Admin Dashboard${NC}"
echo ""
echo "In Render dashboard:"
echo "  1. Click 'New +' → 'Web Service'"
echo "  2. Name: inkawallet-admin"
echo "  3. Build: cd admin-web && npm install && npm run build"
echo "  4. Start: cd admin-web && npm start"
echo "  5. Add environment variable:"
echo "     NEXT_PUBLIC_API_URL=${BACKEND_URL}/api"
echo ""

read -p "Press Enter when admin is deployed and you have the URL..."

# Step 6: Get admin URL
echo ""
read -p "Enter your admin URL (e.g., https://inkawallet-admin.onrender.com): " ADMIN_URL

# Step 7: Update backend CORS
echo ""
echo -e "${YELLOW}Step 7: Update Backend CORS${NC}"
echo ""
echo "In Render backend service → Environment:"
echo "  Add or update: CORS_ORIGIN=${ADMIN_URL}"
echo ""
read -p "Press Enter when CORS is updated..."

# Step 8: Database setup
echo ""
echo -e "${BLUE}Step 8: Database Setup${NC}"
echo ""
echo "Run these commands to setup your Aiven database:"
echo ""
echo "mysql -h mysql-7821ee2-inkawallet.j.aivencloud.com \\"
echo "      -P 25328 -u avnadmin -p \\"
echo "      --ssl-mode=REQUIRED defaultdb"
echo ""
echo "Then run:"
echo "  source $(pwd)/backend/database/schema.sql"
echo "  source $(pwd)/backend/database/credit_bnpl_schema.sql"
echo "  source $(pwd)/backend/database/seed_test_data.sql"
echo ""
read -p "Press Enter when database is setup..."

# Step 9: Mobile app configuration
echo ""
echo -e "${BLUE}Step 9: Prepare Mobile App${NC}"
echo ""
echo "To build production APK:"
echo ""
echo "1. Edit mobile/lib/config/app_config.dart:"
echo "   Change: isProduction = false  →  isProduction = true"
echo ""
echo "2. Build APK:"
echo "   cd mobile"
echo "   flutter clean"
echo "   flutter pub get"
echo "   flutter build apk --release"
echo ""
echo "3. APK location:"
echo "   mobile/build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "See MOBILE_BUILD.md for signing and distribution."
echo ""

# Summary
echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 DEPLOYMENT COMPLETE!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""
echo "Your Production URLs:"
echo "  Backend:  ${BACKEND_URL}"
echo "  Admin:    ${ADMIN_URL}"
echo "  Database: Aiven MySQL (mysql-7821ee2-inkawallet.j.aivencloud.com)"
echo ""
echo "Next Steps:"
echo "  1. Test admin dashboard: ${ADMIN_URL}"
echo "  2. Build mobile APK (see above)"
echo "  3. Upload APK to cloud storage"
echo "  4. Share download link with users"
echo ""
echo "Documentation:"
echo "  - Full guide: RENDER_DEPLOYMENT.md"
echo "  - Mobile build: MOBILE_BUILD.md"
echo "  - Quick checklist: DEPLOYMENT_CHECKLIST.md"
echo ""
echo -e "${GREEN}Good luck! 🚀${NC}"
