# InkaWallet App Branding - Icons and Splash Screen

## ✅ What Was Done

The app now has InkaWallet branding instead of the default Flutter logo:

### 1. **App Icon** 
- Blue background with white "IW" letters
- All sizes generated for Android and iOS
- Adaptive icon for Android 8.0+

### 2. **Splash Screen**
- Shows "InkaWallet" with tagline when app opens
- Blue themed background
- Works on Android and iOS

## 🎨 Current Icons (Placeholder)

The current icons are **simple placeholders** with:
- Blue background (#1E88E5)
- White "IW" text for app icon
- "InkaWallet - Accessible Banking for Everyone" text for splash

## 🔄 How to Test the New Icons

### Option 1: Run on Emulator
```bash
cd mobile
flutter run
```

The app will now show:
- InkaWallet icon in the launcher
- InkaWallet splash screen when opening

### Option 2: Build and Install APK
```bash
cd mobile
flutter build apk --release
```

Install the APK on a real device to see the icon in the app drawer and splash screen.

## 🎨 How to Replace with Professional Icons

When you have professional designs ready:

### Step 1: Replace Icon Files

Place your custom images in `mobile/assets/images/`:

**Required files:**
1. **app_icon.png** (1024x1024px)
   - Square PNG with your logo/design
   - Will be used for the main app icon
   
2. **app_icon_foreground.png** (1024x1024px)
   - Transparent PNG with logo centered
   - Used for adaptive icons on Android 8.0+
   
3. **splash_logo.png** (at least 512x512px)
   - Logo/branding for splash screen
   - Transparent background recommended

### Step 2: Regenerate Icons

```bash
cd mobile
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```

### Step 3: Rebuild App

```bash
flutter clean
flutter run
```

## 🎨 Design Tips for Production Icons

### App Icon Guidelines:
- **Size**: 1024x1024px minimum
- **Format**: PNG with transparency
- **Safe area**: Keep important elements within center 80%
- **Simple**: Icons look best when simple and recognizable
- **Contrast**: Ensure good contrast for visibility

### Splash Screen Guidelines:
- **Size**: 512x512px or larger
- **Format**: PNG with transparency
- **Centered**: Logo should be centered
- **Simple**: Avoid too much text

### Brand Colors to Use:
- Primary Blue: `#1E88E5`
- Dark Gray: `#424242`
- White: `#FFFFFF`
- Accent Green: `#4CAF50`

## 🔧 Icon Generation Script

If you want to regenerate placeholder icons:

```bash
cd mobile/assets/images
python3 generate_icons.py
```

Then regenerate Flutter icons:
```bash
cd ../..
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```

## 📱 Where Icons Appear

After changes, you'll see the new branding:
1. **Home screen** - App launcher icon
2. **App drawer** - Icon in all apps list  
3. **Recent apps** - Icon in task switcher
4. **Splash screen** - Logo when app opens
5. **Settings** - App icon in device settings

## 🎨 Getting Professional Icons

### Free Options:
- **Canva**: https://www.canva.com - Free templates
- **Figma**: https://www.figma.com - Design tool
- Use the Python script to customize colors/text

### Paid Options:
- **Fiverr**: $5-50 for logo design
- **99designs**: Professional contests
- **Upwork**: Hire a designer

### AI Options:
- **Logo.com**: AI-generated logos
- **Looka**: AI logo maker
- **Brandmark**: AI branding

## 📝 Configuration Files

The icon configuration is in:
- `mobile/pubspec.yaml` - Icon settings
- `mobile/assets/images/` - Source icon files
- `mobile/android/app/src/main/res/` - Generated Android icons
- `mobile/ios/Runner/Assets.xcassets/` - Generated iOS icons

## ✅ Checklist

- [x] App icon created (placeholder)
- [x] Splash screen created (placeholder)
- [x] Icons generated for all Android sizes
- [x] Icons generated for all iOS sizes
- [x] Adaptive icons configured (Android 8.0+)
- [ ] Replace with professional designs (when ready)
- [ ] Test on real device
- [ ] Verify all sizes look good

## 🚀 Next Steps

1. **For now**: The placeholder icons work fine for development and testing
2. **Before Play Store**: Replace with professional icons
3. **Test**: Run `flutter run` to see the new branding
4. **Iterate**: Easy to update icons by replacing files and regenerating
