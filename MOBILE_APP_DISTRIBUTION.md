# InkaWallet Mobile App Distribution Guide

## Overview

This guide covers distributing your Flutter mobile app to users via:

1. Google Play Store (Android)
2. Apple App Store (iOS)
3. Direct APK distribution (Android only)

---

## 🤖 Android Distribution

### Option 1: Google Play Store (Recommended)

#### Prerequisites

- Google Play Developer account ($25 one-time fee)
- App signing key
- Privacy policy URL
- App screenshots and promotional materials

#### Step 1: Prepare App for Release

**1. Update App Configuration**

Edit `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        applicationId "com.inkawallet.app"  // Your unique ID
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1  // Increment for each release
        versionName "1.0.0"  // User-facing version
    }
}
```

**2. Create App Icon**

- Place icon files in `android/app/src/main/res/mipmap-*/`
- Use Android Studio's Image Asset tool or https://appicon.co/

**3. Update App Name**

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:label="InkaWallet"
    android:icon="@mipmap/ic_launcher">
```

#### Step 2: Generate Signing Key

```bash
# Generate keystore (one-time setup)
keytool -genkey -v -keystore ~/inkawallet-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias inkawallet

# Keep this file secure! Back it up safely.
```

**Create `android/key.properties`:**

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=inkawallet
storeFile=/home/loopfx/inkawallet-release-key.jks
```

**Update `android/app/build.gradle`:**

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
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
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

**⚠️ Add to `.gitignore`:**

```
key.properties
*.jks
*.keystore
```

#### Step 3: Build Release APK/AAB

```bash
cd mobile

# Build App Bundle (AAB) for Play Store
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab

# Or build APK for testing
flutter build apk --release --split-per-abi

# Output: build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
#         build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
#         build/app/outputs/flutter-apk/app-x86_64-release.apk
```

#### Step 4: Google Play Store Submission

1. **Create App in Play Console**
   - Go to https://play.google.com/console
   - Create new application
   - Fill in app details

2. **Prepare Store Listing**
   - App name: InkaWallet
   - Short description (80 chars)
   - Full description (4000 chars)
   - Screenshots (minimum 2, recommended 8)
     - Phone: 1080x1920 to 7680x4320
     - Tablet: Optional
   - Feature graphic: 1024x500
   - App icon: 512x512

3. **Content Rating**
   - Fill out questionnaire
   - Financial app category

4. **Pricing & Distribution**
   - Free or Paid
   - Select countries
   - Malawi and other target markets

5. **App Content**
   - Privacy policy URL (required)
   - Target audience
   - Data safety form (what data you collect)

6. **Upload AAB**
   - Go to Production → Create new release
   - Upload `app-release.aab`
   - Add release notes
   - Submit for review

7. **Review Process**
   - Usually takes 1-7 days
   - May request changes
   - Once approved, app goes live

---

### Option 2: Direct APK Distribution

For testing or countries without Play Store access:

#### Step 1: Build APK

```bash
cd mobile
flutter build apk --release
```

#### Step 2: Distribute APK

**Options:**

1. **Your website:** Upload APK for direct download
2. **Firebase App Distribution:** Free beta testing
3. **Email/Cloud storage:** Send to specific users

**User Installation:**

1. Download APK to Android device
2. Enable "Install from Unknown Sources" in Settings
3. Tap APK file to install

**⚠️ Warning Users:**

- APKs outside Play Store trigger security warnings
- Users must manually enable installation
- No automatic updates

#### Step 3: Firebase App Distribution (Recommended for Beta)

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize Firebase
cd mobile
firebase init hosting

# Deploy
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_APP_ID \
  --release-notes "Version 1.0.0 - Initial release" \
  --groups "testers"
```

---

## 🍎 iOS Distribution (If you have Mac)

### Prerequisites

- Apple Developer account ($99/year)
- Mac computer with Xcode
- iPhone/iPad for testing

### Step 1: Prepare iOS App

**Update `ios/Runner/Info.plist`:**

```xml
<key>CFBundleDisplayName</key>
<string>InkaWallet</string>
<key>CFBundleVersion</key>
<string>1.0.0</string>
```

**Update Bundle Identifier:**
Open in Xcode:

```bash
open ios/Runner.xcworkspace
```

- Select Runner → General
- Change Bundle Identifier: `com.inkawallet.app`

### Step 2: Build Release IPA

```bash
flutter build ios --release

# Then use Xcode to archive and upload to App Store Connect
```

### Step 3: App Store Connect

1. Create app in https://appstoreconnect.apple.com
2. Fill in app information
3. Upload screenshots (6.5", 5.5" required)
4. Submit for review
5. Review takes 1-3 days

---

## 📊 Analytics & Monitoring

### Firebase Analytics

```bash
# Add to pubspec.yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_analytics: ^10.8.0

# Initialize in main.dart
await Firebase.initializeApp();
```

### Crashlytics

```bash
dependencies:
  firebase_crashlytics: ^3.4.9
```

---

## 🔄 App Updates

### Android

**1. Increment version in `build.gradle`:**

```gradle
versionCode 2  // Must be higher than previous
versionName "1.0.1"
```

**2. Build new AAB:**

```bash
flutter build appbundle --release
```

**3. Upload to Play Console:**

- Production → Create new release
- Upload new AAB
- Add release notes

### iOS

**1. Increment version in Xcode**

**2. Build and archive:**

```bash
flutter build ios --release
```

**3. Upload to App Store Connect**

---

## 📱 App Size Optimization

```bash
# Build with optimizations
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=debug-info

# Analyze size
flutter build apk --analyze-size
```

**Reduce size:**

- Remove unused packages
- Optimize images
- Use vector graphics
- Enable ProGuard/R8

---

## ✅ Pre-Launch Checklist

- [ ] App icon set for all densities
- [ ] App name configured
- [ ] Version code/name set
- [ ] Signing key generated and backed up
- [ ] API URLs point to production
- [ ] Privacy policy created
- [ ] Screenshots taken (light and dark mode)
- [ ] App tested on multiple devices
- [ ] Permissions properly requested
- [ ] Accessibility tested
- [ ] Voice features tested
- [ ] KYC flow tested end-to-end
- [ ] Payment flows tested
- [ ] Error handling verified

---

## 🆘 Common Issues

### Build Fails

- Run `flutter clean`
- Delete `build/` folder
- Run `flutter pub get`
- Check Gradle version

### Signing Issues

- Verify keystore path in `key.properties`
- Check passwords are correct
- Ensure keystore file exists

### Play Store Rejection

- Review policy violations
- Check content rating
- Verify privacy policy
- Test all features work

### Large App Size

- Use `--split-per-abi`
- Remove debug symbols
- Optimize images
- Remove unused dependencies

---

## 📚 Additional Resources

- [Flutter Deployment](https://docs.flutter.dev/deployment/android)
- [Play Console Help](https://support.google.com/googleplay/android-developer)
- [App Store Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Firebase App Distribution](https://firebase.google.com/docs/app-distribution)

---

## 🎯 Quick Start Commands

```bash
# Test release build locally
flutter run --release

# Build APK for testing
flutter build apk --release

# Build AAB for Play Store
flutter build appbundle --release

# Check app size
flutter build apk --analyze-size

# Clean build
flutter clean && flutter pub get
```
