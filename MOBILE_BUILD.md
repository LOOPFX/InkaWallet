# 📱 MOBILE APK BUILD & DISTRIBUTION GUIDE

## 🎯 Build Production APK (Direct Distribution)

### **Step 1: Update API Configuration**

Edit `lib/config/app_config.dart`:

```dart
class AppConfig {
  // Production API
  static const String apiBaseUrl = 'https://inkawallet-backend.onrender.com/api';
  static const String wsBaseUrl = 'wss://inkawallet-backend.onrender.com';

  // Voice WebSocket
  static const String voiceWebSocketUrl = '$wsBaseUrl/ws/voice';

  // Keep other settings same
  static const String appName = 'InkaWallet';
  static const String defaultCurrency = 'MKW';
  static const double defaultBalance = 100000.00;
  static const bool enableVoiceByDefault = true;
}
```

---

### **Step 2: Update App Version**

Edit `pubspec.yaml`:

```yaml
version: 1.0.0+1 # Format: major.minor.patch+buildNumber
```

---

### **Step 3: Generate Signing Key (First time only)**

```bash
cd /home/loopfx/InkaWallet/mobile/android/app

# Generate keystore
keytool -genkey -v -keystore inkawallet-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias inkawallet

# Enter details:
# Password: [Choose strong password]
# Name: InkaWallet
# Organization: Your Company
# City: Your City
# State: Your State
# Country: MW (or your country code)
```

**Save these for future builds:**

- Keystore password
- Key alias: `inkawallet`
- Key password

---

### **Step 4: Configure Signing**

Create `android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=inkawallet
storeFile=inkawallet-release-key.jks
```

⚠️ **Security:** Add to `.gitignore`:

```bash
echo "android/key.properties" >> .gitignore
echo "android/app/*.jks" >> .gitignore
```

---

### **Step 5: Update build.gradle**

Edit `android/app/build.gradle`:

Add before `android {` block:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Inside `android { ... }`, add:

```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}

buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled false
        shrinkResources false
    }
}
```

---

### **Step 6: Build APK**

```bash
cd /home/loopfx/InkaWallet/mobile

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# Or build App Bundle (smaller, recommended)
flutter build appbundle --release
```

**Build output:**

- APK: `build/app/outputs/flutter-apk/app-release.apk` (~50-80MB)
- Bundle: `build/app/outputs/bundle/release/app-release.aab` (~30-40MB)

---

## 📤 DISTRIBUTION OPTIONS

### **Option 1: Direct Download Link (Easiest)**

Upload APK to cloud storage:

**Google Drive:**

```bash
# Upload APK to Google Drive
# Share link: https://drive.google.com/file/d/FILE_ID/view?usp=sharing
# Change to direct download: /file/d/FILE_ID/view → /uc?export=download&id=FILE_ID
```

**Dropbox:**

```bash
# Upload to Dropbox
# Change: dl=0 → dl=1 for direct download
```

**Your own server:**

```bash
# Upload to any web server
scp build/app/outputs/flutter-apk/app-release.apk user@server:/var/www/downloads/
# Share: https://yourserver.com/downloads/app-release.apk
```

---

### **Option 2: Firebase App Distribution (Better)**

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize Firebase in mobile folder
cd mobile
firebase init appdistribution

# Upload APK
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_FIREBASE_APP_ID \
  --groups "testers" \
  --release-notes "Initial production release"
```

Users get email with download link.

---

### **Option 3: GitHub Releases**

```bash
# Create release on GitHub
git tag v1.0.0
git push origin v1.0.0

# Upload APK to GitHub release
# Go to: https://github.com/YOUR_REPO/releases/new
# Attach app-release.apk
```

---

## 📲 USER INSTALLATION INSTRUCTIONS

**Create a simple webpage or message:**

```markdown
# Install InkaWallet App

1. **Enable Unknown Sources**
   - Go to Settings → Security
   - Enable "Install unknown apps" or "Unknown sources"
   - Allow your browser to install apps

2. **Download APK**
   - Click: [Download InkaWallet](YOUR_DOWNLOAD_LINK)
   - File: app-release.apk (50MB)

3. **Install**
   - Open downloaded file
   - Tap "Install"
   - Tap "Open"

4. **Start Using**
   - Create account or login
   - Enjoy accessible banking!

📱 Requirements:

- Android 6.0 or higher
- 100MB free space
- Internet connection

🔒 Security:

- Official InkaWallet app
- No Google Play required
- Updates via same link
```

---

## 🔄 UPDATES & VERSIONING

**For each new version:**

1. Update `pubspec.yaml`:

```yaml
version: 1.0.1+2 # Increment version
```

2. Update code

3. Rebuild APK:

```bash
flutter build apk --release
```

4. Upload new APK with version in filename:

```bash
cp build/app/outputs/flutter-apk/app-release.apk inkawallet-v1.0.1.apk
```

5. Users download and install over old version (data preserved)

---

## ✅ PRE-DISTRIBUTION CHECKLIST

Before sharing APK:

- [ ] API points to production backend
- [ ] App version updated in pubspec.yaml
- [ ] Signing configured (release builds)
- [ ] Test on real Android device
- [ ] Test login/registration
- [ ] Test voice features
- [ ] Test payments/transactions
- [ ] Test KYC flow
- [ ] Check app icon shows correctly
- [ ] Verify no development logs in release build

---

## 📊 ANALYTICS & CRASH REPORTING (Optional)

**Add Firebase Crashlytics:**

```bash
cd mobile
flutter pub add firebase_core firebase_crashlytics firebase_analytics
```

This helps you track:

- Crashes in production
- User analytics
- Performance issues

---

## 🚀 QUICK BUILD COMMANDS

**Development build (for testing):**

```bash
flutter run --release
```

**Production APK:**

```bash
flutter build apk --release --target-platform android-arm,android-arm64
```

**Smaller APK (per-ABI):**

```bash
flutter build apk --release --split-per-abi
# Creates 3 APKs: arm64-v8a, armeabi-v7a, x86_64
```

**App Bundle (for future Play Store):**

```bash
flutter build appbundle --release
```

---

## 🔍 TROUBLESHOOTING

**Build fails:**

```bash
flutter clean
flutter pub get
flutter build apk --release --verbose
```

**Signing issues:**

- Verify key.properties exists
- Check keystore file path
- Confirm passwords match

**App crashes on startup:**

- Check API URL is correct (HTTPS not HTTP)
- Verify backend is running
- Check logs: `flutter logs`

**Large APK size:**

- Use `--split-per-abi` for smaller files
- Remove unused dependencies
- Enable code shrinking (ProGuard)

---

## 📦 YOUR BUILD ARTIFACTS

After successful build:

- **APK Location:** `mobile/build/app/outputs/flutter-apk/app-release.apk`
- **Size:** ~50-80MB (uncompressed)
- **Platforms:** Android 6.0+ (API 23+)
- **Architecture:** ARM, ARM64, x86

---

Good luck with your launch! 🎉
