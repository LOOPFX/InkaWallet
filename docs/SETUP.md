# InkaWallet Setup Guide

## Prerequisites

Before you begin, ensure you have the following installed:

### Mobile Development

- **Flutter SDK** (>= 3.0.0)
- **Android Studio** with Android SDK
- **Java Development Kit (JDK)** 11 or higher
- **Git**

### Backend Development

- **Node.js** (>= 18.x)
- **MySQL** (>= 8.0)
- **npm** or **yarn**

### Development Tools

- **Visual Studio Code** (recommended) or any IDE
- **Postman** or similar API testing tool

## Backend Setup

### 1. Database Configuration

First, set up the MySQL database:

```bash
# Login to MySQL
mysql -u root -p

# Create database and user
CREATE DATABASE inkawallet_db;
CREATE USER 'inkawallet_user'@'localhost' IDENTIFIED BY 'your_secure_password';
GRANT ALL PRIVILEGES ON inkawallet_db.* TO 'inkawallet_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 2. Run Database Schema

```bash
# Navigate to backend directory
cd backend

# Import database schema
mysql -u inkawallet_user -p inkawallet_db < database/schema.sql
```

### 3. Install Backend Dependencies

```bash
cd backend
npm install
```

### 4. Configure Environment Variables

Create a `.env` file in the backend directory:

```bash
cp .env.example .env
```

Edit `.env` and update the following:

```env
# Database
DB_HOST=localhost
DB_PORT=3306
DB_USER=inkawallet_user
DB_PASSWORD=your_secure_password
DB_NAME=inkawallet_db

# JWT Secrets (generate secure keys)
JWT_SECRET=your_very_secure_jwt_secret_key_minimum_32_characters
JWT_REFRESH_SECRET=your_very_secure_refresh_secret_key_minimum_32_characters

# Encryption Keys (generate secure keys)
ENCRYPTION_KEY=your_32_character_encryption_key_change_this
ENCRYPTION_IV=your_16_char_iv_

# Speechmatics API
SPEECHMATICS_API_KEY=your_speechmatics_api_key_here
```

**Important**: Generate secure keys using:

```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### 5. Build and Run Backend

```bash
# Development mode with auto-reload
npm run dev

# Production build
npm run build
npm start
```

Backend will run on `http://localhost:3000`

## Mobile App Setup

### 1. Install Flutter Dependencies

```bash
cd mobile
flutter pub get
```

### 2. Configure API Endpoint

Edit `lib/utils/constants.dart` and update:

```dart
static const String baseUrl = 'http://10.0.2.2:3000/api'; // For Android emulator
// or
static const String baseUrl = 'http://localhost:3000/api'; // For iOS simulator
// or
static const String baseUrl = 'http://YOUR_COMPUTER_IP:3000/api'; // For physical device
```

### 3. Get Speechmatics API Key

1. Visit [Speechmatics](https://www.speechmatics.com/)
2. Sign up for an account
3. Get your API key from the dashboard
4. Update in `lib/utils/constants.dart`:

```dart
static const String speechmaticsApiKey = 'YOUR_SPEECHMATICS_API_KEY';
```

### 4. Run the Mobile App

```bash
# Check connected devices
flutter devices

# Run on Android emulator/device
flutter run

# Run with specific device
flutter run -d <device_id>

# Build APK
flutter build apk --release
```

## Testing

### Backend Testing

```bash
cd backend
npm test
```

### API Testing with Postman

1. Import the API collection from `docs/postman_collection.json`
2. Set base URL to `http://localhost:3000`
3. Test endpoints in order:
   - Register user
   - Login
   - Get balance
   - Send money
   - Get transaction history

### Test Credentials

After setup, you can create test users through the app or use these SQL commands:

```sql
-- Insert test user (password: Test@1234)
INSERT INTO users (id, first_name, last_name, email, phone, password_hash, is_verified)
VALUES (
  UUID(),
  'Test',
  'User',
  'test@inkawallet.com',
  '+265999000001',
  '$2a$12$abcdefghijklmnopqrstuvwxyz123456789',  -- Replace with actual bcrypt hash
  TRUE
);

-- Create wallet for test user
INSERT INTO wallets (id, user_id, balance, account_number)
VALUES (
  UUID(),
  'USER_ID_FROM_ABOVE',
  10000.00,
  '265999000001'
);
```

## Troubleshooting

### Backend Issues

**Database Connection Failed**

```bash
# Check MySQL is running
sudo systemctl status mysql

# Test connection
mysql -u inkawallet_user -p inkawallet_db
```

**Port Already in Use**

```bash
# Find process using port 3000
lsof -i :3000

# Kill process
kill -9 <PID>

# Or change port in .env
PORT=3001
```

### Mobile App Issues

**Flutter Dependencies**

```bash
flutter clean
flutter pub get
```

**Android Build Issues**

```bash
cd android
./gradlew clean
cd ..
flutter run
```

**iOS Build Issues**

```bash
cd ios
pod install
cd ..
flutter run
```

**Network Connection Issues**

- Ensure backend is running
- Check firewall settings
- For physical devices, use computer's IP address instead of localhost
- Verify API endpoint in `constants.dart`

## Development Workflow

### 1. Start Backend

```bash
cd backend
npm run dev
```

### 2. Start Mobile App

```bash
cd mobile
flutter run
```

### 3. Monitor Logs

Backend logs: `backend/logs/app.log`

Mobile logs: Check terminal or Android Studio/Xcode console

## Production Deployment

### Backend Deployment

1. **Configure Production Environment**

```bash
NODE_ENV=production
```

2. **Use Process Manager**

```bash
npm install -g pm2
pm2 start dist/server.js --name inkawallet-api
pm2 save
pm2 startup
```

3. **Set up HTTPS**

- Use Let's Encrypt or similar SSL certificate
- Configure reverse proxy (Nginx/Apache)

4. **Database Optimization**

- Enable query caching
- Set up database backups
- Configure replication if needed

### Mobile App Deployment

1. **Android Release Build**

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

2. **Update Version**
   Edit `pubspec.yaml`:

```yaml
version: 1.0.1+2 # version+build_number
```

3. **Sign APK**

- Create keystore
- Configure signing in `android/app/build.gradle`

4. **Submit to Play Store**

- Create developer account
- Upload signed AAB
- Complete store listing

## Security Checklist

- [ ] Change all default passwords
- [ ] Generate new JWT secrets
- [ ] Generate new encryption keys
- [ ] Enable HTTPS in production
- [ ] Set up firewall rules
- [ ] Regular security updates
- [ ] Enable database backups
- [ ] Monitor logs for suspicious activity
- [ ] Implement rate limiting
- [ ] Use environment variables for secrets

## Support

For issues or questions:

- Check documentation in `docs/` folder
- Review API documentation in `docs/API.md`
- Check security guidelines in `docs/SECURITY.md`
- Review accessibility features in `docs/ACCESSIBILITY.md`

## Next Steps

1. Set up admin web interface
2. Configure automated backups
3. Set up monitoring and alerts
4. Implement CI/CD pipeline
5. Conduct security audit
6. Perform accessibility testing
7. Load testing and optimization
