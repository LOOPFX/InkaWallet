# 🚀 RENDER.COM DEPLOYMENT GUIDE - InkaWallet

## Prerequisites

✅ Aiven MySQL database configured
✅ GitHub repository with latest code
✅ Render.com account (free)

---

## 🎯 DEPLOYMENT STEPS

### **Option 1: Automated Deploy (Blueprint)**

1. **Push code to GitHub**

```bash
cd /home/loopfx/InkaWallet
git add -A
git commit -m "feat: Production deployment configuration for Render.com"
git push origin dev
```

2. **Connect to Render**

- Go to https://render.com/
- Sign in with GitHub
- Click "New" → "Blueprint"
- Select your InkaWallet repository
- Render will auto-detect `render.yaml` and deploy both services

3. **Add sensitive environment variables**

- Go to Backend service → Environment
- Add: `DB_PASSWORD` = `[Get from your Aiven dashboard]`
- JWT_SECRET will auto-generate

---

### **Option 2: Manual Deploy (Recommended for learning)**

#### **A. Deploy Backend API**

1. **Create Web Service**

- Dashboard → "New +" → "Web Service"
- Connect GitHub repository
- Name: `inkawallet-backend`
- Region: Oregon (or nearest)
- Branch: `dev`
- Root Directory: Leave blank
- Runtime: `Node`
- Build Command: `cd backend && npm install && npm run build`
- Start Command: `cd backend && npm start`

2. **Environment Variables** (Add these in Render dashboard)

```
NODE_ENV=production
DB_HOST=mysql-7821ee2-inkawallet.j.aivencloud.com
DB_PORT=25328
DB_USER=avnadmin
DB_PASSWORD=[Get from your Aiven dashboard]
DB_NAME=defaultdb
DB_SSL=true
JWT_SECRET=[Click "Generate" to create secure random key]
PORT=3000
```

3. **Health Check**

- Path: `/api/health`

4. **Deploy**

- Click "Create Web Service"
- Wait 5-10 minutes for first deploy
- Your backend URL: `https://inkawallet-backend.onrender.com`

---

#### **B. Deploy Admin Dashboard**

1. **Create Web Service**

- Dashboard → "New +" → "Web Service"
- Connect same repository
- Name: `inkawallet-admin`
- Region: Oregon
- Branch: `dev`
- Root Directory: Leave blank
- Runtime: `Node`
- Build Command: `cd admin-web && npm install && npm run build`
- Start Command: `cd admin-web && npm start`

2. **Environment Variables**

```
NODE_ENV=production
NEXT_PUBLIC_API_URL=https://inkawallet-backend.onrender.com/api
```

3. **Deploy**

- Click "Create Web Service"
- Your admin URL: `https://inkawallet-admin.onrender.com`

---

#### **C. Update Backend CORS**

After admin deploys, update backend CORS:

1. Go to Backend service → Environment
2. Add/update:

```
CORS_ORIGIN=https://inkawallet-admin.onrender.com
```

3. Backend will auto-redeploy

---

## 📱 MOBILE APP CONFIGURATION

Update Flutter app to use production API:

**File:** `mobile/lib/config/app_config.dart`

Change:

```dart
static const String apiBaseUrl = 'https://inkawallet-backend.onrender.com/api';
static const String wsBaseUrl = 'wss://inkawallet-backend.onrender.com';
```

Then rebuild APK (see MOBILE_BUILD.md)

---

## 🗄️ DATABASE SETUP

**Initialize Aiven MySQL Database:**

```bash
# Connect to Aiven
mysql -h mysql-7821ee2-inkawallet.j.aivencloud.com \
      -P 25328 \
      -u avnadmin \
      -p \
      --ssl-mode=REQUIRED \
      defaultdb

# Run schema
source backend/database/schema.sql
source backend/database/credit_bnpl_schema.sql
source backend/database/seed_test_data.sql
```

Or upload via Aiven web console.

---

## ✅ VERIFICATION CHECKLIST

- [ ] Backend: `https://inkawallet-backend.onrender.com/api/health` returns OK
- [ ] Admin: `https://inkawallet-admin.onrender.com` loads
- [ ] Database: Tables created in Aiven MySQL
- [ ] Mobile: App connects to production API
- [ ] CORS: Admin can call backend API
- [ ] WebSocket: Voice features work
- [ ] SSL: All endpoints use HTTPS/WSS

---

## 🆓 FREE TIER LIMITS

**Render Free Plan:**

- ✅ Unlimited services
- ⚠️ Apps sleep after 15min inactivity (50-60s wake-up)
- ✅ 750 hours/month free (enough for 1 service)
- ✅ Auto SSL certificates

**Aiven Free MySQL:**

- ✅ 1GB storage
- ✅ Shared resources
- ✅ SSL included

**Tip:** For production, upgrade to paid plan ($7/month) to prevent sleep.

---

## 🔧 TROUBLESHOOTING

**Build fails:**

```bash
# Test locally first
cd backend && npm install && npm run build
cd admin-web && npm install && npm run build
```

**Database connection fails:**

- Check SSL is enabled in database.ts
- Verify Aiven credentials
- Check DB_SSL=true in env vars

**CORS errors:**

- Update CORS_ORIGIN with exact admin URL
- No trailing slash

---

## 📦 YOUR PRODUCTION URLS

After deployment, you'll have:

- **Backend API:** `https://inkawallet-backend.onrender.com`
- **Admin Dashboard:** `https://inkawallet-admin.onrender.com`
- **Database:** Already on Aiven
- **Mobile APK:** Build locally, distribute via link

---

## 🎉 NEXT STEPS

1. Deploy backend (10 min)
2. Deploy admin (10 min)
3. Setup database (5 min)
4. Build mobile APK (see MOBILE_BUILD.md)
5. Test everything
6. Share APK download link with users

Good luck! 🚀
