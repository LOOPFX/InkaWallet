# 🚀 InkaWallet - Production Deployment Guide

## Project Overview

**InkaWallet** - Accessible Digital Wallet for the Blind and Upper-Limb Impaired

- **Mobile App**: Flutter (Android/iOS)
- **Backend API**: TypeScript/Node.js/Express
- **Admin Panel**: Next.js with Bootstrap CSS
- **Database**: MySQL

---

## 📋 Quick Start Guide

### 1️⃣ Setup Database (5 minutes)

```bash
# Start MySQL
sudo service mysql start

# Import database schema
mysql -u root -p < backend/database/schema.sql

# Or manually:
mysql -u root -p
# Then: SOURCE /home/loopfx/InkaWallet/backend/database/schema.sql;
```

**Default Admin Credentials:**

- Email: `admin@inkawallet.com`
- Password: `admin123`

---

### 2️⃣ Start Backend API (2 minutes)

```bash
cd backend

# Update .env file with your MySQL password if needed
# DB_PASSWORD=your_mysql_password

# Start backend server
npm run dev
```

Backend will run on: **http://localhost:3000**

**Test API:**

```bash
curl http://localhost:3000/health
# Should return: {"status":"OK","message":"InkaWallet API is running"}
```

---

### 3️⃣ Start Admin Web Panel (2 minutes)

```bash
cd admin-web

# Start Next.js development server
npm run dev
```

Admin panel will run on: **http://localhost:3001**

**Default view:** Dashboard with stats, users, and transactions

---

### 4️⃣ Run Mobile App (5 minutes)

#### Option A: On Emulator

```bash
cd mobile

# Launch emulator
flutter emulators --launch InkaWallet_AVD

# Run app (in another terminal)
flutter run
```

#### Option B: On Physical Device

```bash
cd mobile

# Enable USB debugging on your Android phone
# Connect phone via USB

# Check device is connected
flutter devices

# Run app
flutter run
```

#### Build APK for Installation

```bash
cd mobile

# Build debug APK
flutter build apk --debug

# Build release APK (for production)
flutter build apk --release

# APK location:
# mobile/build/app/outputs/flutter-apk/app-release.apk
```

**Install on device:**

```bash
# Transfer APK to phone and install
# Or use ADB:
adb install mobile/build/app/outputs/flutter-apk/app-release.apk
```

---

## 🧪 Testing the Complete System

### Test Flow 1: User Registration & Login

1. Open mobile app
2. Click "Register"
3. Fill details (email, password, name, phone: +265xxxxxxxxx)
4. User created with **MKW 100,000** balance
5. Login successful

### Test Flow 2: Send Money

1. Login to app
2. Go to "Send Money"
3. Enter receiver phone number
4. Enter amount
5. Confirm transaction
6. Check balance updated

### Test Flow 3: Accessibility Features

1. Go to Settings
2. Enable/disable voice assistance
3. Enable/disable haptic feedback
4. Test biometric authentication

### Test Flow 4: Admin Panel

1. Open http://localhost:3001
2. Auto-login as admin
3. View dashboard stats
4. View all users
5. View all transactions
6. Deactivate a user

---

## 📱 Key Features Implemented

### Mobile App Features:

- ✅ User Registration & Login
- ✅ Google Sign-In ready
- ✅ Biometric Authentication (fingerprint)
- ✅ Voice Assistance (Text-to-Speech)
- ✅ Speech-to-Text Input
- ✅ Haptic Feedback
- ✅ Send Money
- ✅ Receive Money (from external providers)
- ✅ Transaction History
- ✅ Balance Display
- ✅ Settings (Accessibility controls)
- ✅ Purple Theme
- ✅ Mock Payment Providers (Mpamba, Airtel, Banks)

### Backend API Features:

- ✅ JWT Authentication
- ✅ User Management
- ✅ Wallet Management
- ✅ Transactions (Send/Receive)
- ✅ Transaction History
- ✅ 2FA Ready
- ✅ Activity Logging
- ✅ Admin APIs

### Admin Panel Features:

- ✅ Bootstrap CSS styling
- ✅ Dashboard with stats
- ✅ User management
- ✅ Transaction monitoring
- ✅ User deactivation
- ✅ Purple theme matching mobile

---

## 🔧 Configuration Files

### Backend `.env`

```
PORT=3000
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=inkawallet_db
JWT_SECRET=inkawallet_dev_secret_key_2026
SPEECHMATICS_API_KEY=your_key
```

### Mobile `lib/config/app_config.dart`

- API URL configured for Android emulator (10.0.2.2)
- Change to real IP for physical devices

---

## 🚀 Production Deployment

### Backend Deployment

```bash
cd backend
npm run build
npm start

# Use PM2 for production:
npm install -g pm2
pm2 start dist/server.js --name inkawallet-api
```

### Admin Panel Deployment

```bash
cd admin-web
npm run build
npm start

# Or deploy to Vercel:
vercel deploy
```

### Mobile App Deployment

```bash
cd mobile

# Build production APK
flutter build apk --release

# Build App Bundle for Google Play
flutter build appbundle --release
```

---

## 📊 Default Test Data

- **Admin User**: admin@inkawallet.com / admin123
- **Default Balance**: MKW 100,000 for all new users
- **Payment Providers**: Mpamba, Airtel Money, NBM, Standard Bank, FDH

---

## 🐛 Troubleshooting

### Backend not starting?

```bash
# Check MySQL is running
sudo service mysql status

# Check database exists
mysql -u root -p -e "SHOW DATABASES;"
```

### Mobile app not connecting?

- Update `mobile/lib/config/app_config.dart`
- Use your computer's IP instead of `10.0.2.2` for physical devices
- Check backend is running on port 3000

### Build errors?

```bash
# Clean and rebuild
cd mobile
flutter clean
flutter pub get
flutter build apk
```

---

## 📞 Support

For issues or questions about the implementation, check:

1. Backend logs: Terminal running `npm run dev`
2. Mobile logs: `flutter run -v`
3. Admin panel console: Browser DevTools

---

## ✅ Production Checklist

- [ ] Database configured and seeded
- [ ] Backend running on port 3000
- [ ] Admin panel running on port 3001
- [ ] Mobile APK built successfully
- [ ] Tested user registration
- [ ] Tested money transfer
- [ ] Tested accessibility features
- [ ] Admin panel accessible
- [ ] All permissions granted on mobile

---

**Ready to deploy! 🎉**
