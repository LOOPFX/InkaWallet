# InkaWallet Quick Deployment Guide

## 🚀 Deploy to Vercel (5 minutes)

### Backend Deployment

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy backend
cd backend
vercel --prod
```

**When prompted:**

- Set up and deploy? **Yes**
- Which scope? Select your account
- Link to existing project? **No**
- Project name? **inkawallet-backend**
- Directory? **./backend**
- Override settings? **No**

**After deployment, set environment variables in Vercel dashboard:**

```
DATABASE_HOST=your-database-host
DATABASE_USER=your-database-user
DATABASE_PASSWORD=your-database-password
DATABASE_NAME=inkawallet
JWT_SECRET=generate-random-32-char-string
SPEECHMATICS_API_KEY=your-api-key
NODE_ENV=production
```

### Admin Web Deployment

```bash
cd admin-web
vercel --prod
```

**Set environment variable:**

```
NEXT_PUBLIC_API_URL=https://your-backend.vercel.app/api
```

---

## 📱 Build Android App (3 minutes)

### For Testing (Direct APK)

```bash
cd mobile
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

**Share with users:**

- Upload to Google Drive/Dropbox
- Send via email
- Host on your website

### For Google Play Store

```bash
# Generate signing key (first time only)
keytool -genkey -v -keystore ~/inkawallet-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias inkawallet

# Build App Bundle
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab` to Google Play Console

---

## ✅ Post-Deployment

1. **Update mobile app config** with production API URL:

   ```dart
   // mobile/lib/config/app_config.dart
   static const String apiBaseUrl = 'https://your-backend.vercel.app/api';
   ```

2. **Test the deployment:**

   ```bash
   curl https://your-backend.vercel.app/health
   ```

3. **Run database migrations** on production database

---

## 📋 What You Need

- ✅ Vercel account (free)
- ✅ Production database (Neon/PlanetScale/Supabase - free tiers available)
- ✅ Google Play Developer account ($25) - for Play Store
- ✅ Privacy policy URL - required for app stores

For detailed instructions, see:

- `DEPLOYMENT_GUIDE_VERCEL.md` - Full backend/admin deployment
- `MOBILE_APP_DISTRIBUTION.md` - Complete mobile app guide
