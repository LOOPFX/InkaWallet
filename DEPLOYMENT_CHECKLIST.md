# 🎯 QUICK DEPLOYMENT CHECKLIST

## 📋 Pre-Deployment

- [ ] Code committed to GitHub
- [ ] Database schema ready
- [ ] Environment variables documented

---

## 🖥️ BACKEND DEPLOYMENT

### 1. Create Render Web Service

- URL: https://dashboard.render.com/
- New → Web Service
- Connect GitHub repo

### 2. Configuration

```
Name: inkawallet-backend
Region: Oregon
Branch: dev
Runtime: Node
Build: cd backend && npm install && npm run build
Start: cd backend && npm start
```

### 3. Environment Variables

```
NODE_ENV=production
DB_HOST=mysql-7821ee2-inkawallet.j.aivencloud.com
DB_PORT=25328
DB_USER=avnadmin
DB_PASSWORD=[Get from Aiven dashboard]
DB_NAME=defaultdb
DB_SSL=true
JWT_SECRET=[Auto-generate]
PORT=3000
```

### 4. Verify

- [ ] Health check: `https://inkawallet-backend.onrender.com/api/health`

---

## 🌐 ADMIN DEPLOYMENT

### 1. Create Render Web Service

- New → Web Service
- Same repo

### 2. Configuration

```
Name: inkawallet-admin
Region: Oregon
Branch: dev
Runtime: Node
Build: cd admin-web && npm install && npm run build
Start: cd admin-web && npm start
```

### 3. Environment Variables

```
NODE_ENV=production
NEXT_PUBLIC_API_URL=https://inkawallet-backend.onrender.com/api
```

### 4. Update Backend CORS

Add to backend env vars:

```
CORS_ORIGIN=https://inkawallet-admin.onrender.com
```

### 5. Verify

- [ ] Admin loads: `https://inkawallet-admin.onrender.com`

---

## 🗄️ DATABASE SETUP

```bash
mysql -h mysql-7821ee2-inkawallet.j.aivencloud.com \
      -P 25328 -u avnadmin -p \
      --ssl-mode=REQUIRED defaultdb

source backend/database/schema.sql
source backend/database/credit_bnpl_schema.sql
source backend/database/seed_test_data.sql
```

- [ ] Tables created
- [ ] Test data loaded

---

## 📱 MOBILE APK BUILD

### 1. Update Config

Set `isProduction = true` in `lib/config/app_config.dart`

### 2. Build

```bash
cd mobile
flutter clean
flutter pub get
flutter build apk --release
```

### 3. Output

- [ ] APK: `build/app/outputs/flutter-apk/app-release.apk`

### 4. Distribute

Upload to:

- [ ] Google Drive / Dropbox
- [ ] Firebase App Distribution
- [ ] GitHub Releases

---

## ✅ FINAL VERIFICATION

- [ ] Backend API responding
- [ ] Admin dashboard loads
- [ ] Database connected
- [ ] Mobile APK installs
- [ ] Mobile app connects to production
- [ ] Login/registration works
- [ ] Transactions work
- [ ] Voice features work
- [ ] KYC flows work

---

## 🚀 YOU'RE LIVE!

**Your URLs:**

- Backend: `https://inkawallet-backend.onrender.com`
- Admin: `https://inkawallet-admin.onrender.com`
- Mobile: APK download link

---

**Estimated Time:** 30-45 minutes total

See detailed guides:

- RENDER_DEPLOYMENT.md (backend/admin)
- MOBILE_BUILD.md (mobile APK)
