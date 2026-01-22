# InkaWallet - Quick Reference Card

## 🚀 Start Everything (3 Terminals)

### Terminal 1: Backend

```bash
cd backend
npm run dev
# Running on http://localhost:3000
```

### Terminal 2: Mobile

```bash
cd mobile
flutter run
# Select your device/emulator
```

### Terminal 3: Admin Dashboard

```bash
cd admin
npm run dev
# Running on http://localhost:3001
```

---

## 📱 Test User Credentials

Create via app or API:

- **Email:** test@inkawallet.com
- **Phone:** +265999000001
- **Password:** Test@1234
- **Initial Balance:** 10,000 MWK (auto-assigned)

---

## 🔑 Key URLs

- **Backend API:** http://localhost:3000
- **API Docs:** http://localhost:3000/api
- **Admin Dashboard:** http://localhost:3001
- **Health Check:** http://localhost:3000/health

---

## 📋 Mobile App Navigation Flow

```
Splash → Onboarding → Login/Register → Home
                                        ├── Send Money
                                        ├── Transaction History
                                        └── Settings
```

---

## 🎯 Quick Test Scenarios

### 1. Register & Login (2 min)

1. Open mobile app
2. Complete onboarding (3 screens)
3. Tap "Register"
4. Fill form and submit
5. Auto-redirect to Home

### 2. Send Money (2 min)

1. From Home, tap "Send Money"
2. Enter recipient phone
3. Enter amount (e.g., 500)
4. Select provider (InkaWallet)
5. Add description (optional)
6. Confirm and send

### 3. Admin Dashboard (3 min)

1. Open http://localhost:3001
2. Login with user credentials
3. View Dashboard stats
4. Browse Users table
5. Check Transactions
6. Export data to CSV

---

## 🔧 Common Commands

### Backend

```bash
npm run dev        # Development mode
npm run build      # Build TypeScript
npm start          # Run production build
```

### Mobile

```bash
flutter run                    # Run app
flutter run -v                 # Verbose output
flutter clean                  # Clean build
flutter pub get                # Get dependencies
flutter build apk              # Build Android APK
```

### Admin

```bash
npm run dev        # Development mode
npm run build      # Production build
npm run preview    # Preview production build
```

### Database

```bash
# Connect to database
mysql -u inkawallet_user -p inkawallet_db

# Check tables
SHOW TABLES;

# View users
SELECT * FROM users;

# View transactions
SELECT * FROM transactions ORDER BY created_at DESC LIMIT 10;
```

---

## 🐛 Troubleshooting

### Backend won't start

```bash
# Check if port 3000 is in use
lsof -ti:3000
# Kill process
kill -9 $(lsof -ti:3000)
```

### Database connection failed

```bash
# Test MySQL connection
mysql -u inkawallet_user -p
# Re-import schema if needed
mysql -u inkawallet_user -p inkawallet_db < backend/database/schema.sql
```

### Mobile app build errors

```bash
cd mobile
flutter clean
flutter pub get
flutter run
```

### Admin can't connect to API

- Check backend is running on port 3000
- Verify CORS settings in backend
- Check proxy config in `admin/vite.config.ts`

---

## 📊 Database Quick Queries

```sql
-- Total users
SELECT COUNT(*) FROM users;

-- Active users
SELECT COUNT(*) FROM users WHERE is_active = 1;

-- Today's transactions
SELECT COUNT(*), SUM(amount) FROM transactions
WHERE DATE(created_at) = CURDATE();

-- Failed transactions
SELECT * FROM transactions WHERE status = 'failed';

-- Top senders
SELECT sender_id, COUNT(*) as txn_count, SUM(amount) as total_sent
FROM transactions
GROUP BY sender_id
ORDER BY total_sent DESC
LIMIT 5;
```

---

## 🎨 Color Scheme

- **Primary Purple:** #6B46C1
- **Success Green:** #10B981
- **Error Red:** #EF4444
- **Warning Orange:** #F59E0B
- **Info Blue:** #3B82F6

---

## 🔐 Environment Variables (.env)

```env
# Database
DB_HOST=localhost
DB_PORT=3306
DB_NAME=inkawallet_db
DB_USER=inkawallet_user
DB_PASSWORD=your_password

# JWT
JWT_SECRET=your_32_char_secret
JWT_REFRESH_SECRET=your_another_secret
JWT_EXPIRES_IN=1h
JWT_REFRESH_EXPIRES_IN=7d

# App
PORT=3000
NODE_ENV=development

# Encryption
ENCRYPTION_KEY=your_32_char_encryption_key

# Speechmatics (optional)
SPEECHMATICS_API_KEY=your_api_key
```

---

## 📦 Package Versions

### Backend

- Node.js: 18+
- TypeScript: 5.2+
- Express: 4.18+
- MySQL: 8.0+

### Mobile

- Flutter: 3.0+
- Dart: 3.0+

### Admin

- React: 18.2+
- TypeScript: 5.2+
- Vite: 5.0+
- Material-UI: 5.15+

---

## 📞 Support & Documentation

- **Full Setup:** `docs/SETUP.md`
- **API Reference:** `docs/API.md`
- **Security Docs:** `docs/SECURITY.md`
- **Accessibility:** `docs/ACCESSIBILITY.md`
- **Quick Start:** `QUICKSTART.md`
- **Project Summary:** `PROJECT_SUMMARY.md`
- **Implementation Status:** `IMPLEMENTATION_COMPLETE.md`

---

## ✅ Pre-Flight Checklist

Before starting development:

- [ ] MySQL server running
- [ ] Node.js 18+ installed
- [ ] Flutter SDK installed
- [ ] Android Studio / Xcode set up
- [ ] Database created and schema imported
- [ ] Backend .env file configured
- [ ] All dependencies installed

---

**Quick Reference v1.0 - InkaWallet Inclusive Digital Wallet**

_Print this page for easy reference during development and testing_
