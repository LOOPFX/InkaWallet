# InkaWallet App Icons and Images

## Required Images

Place the following images in this directory:

### 1. **app_icon.png** (1024x1024px)

- Main app icon
- Should be square with InkaWallet logo
- Recommended: Blue gradient background with white "IW" or wallet icon
- PNG format with transparency

### 2. **app_icon_foreground.png** (1024x1024px)

- Foreground layer for adaptive icons (Android 8.0+)
- Transparent background
- InkaWallet logo/symbol centered
- PNG format with transparency

### 3. **splash_logo.png** (512x512px or larger)

- Logo shown on splash screen when app opens
- Transparent background
- InkaWallet branding
- PNG format with transparency

## Quick Image Creation Options

### Option 1: Online Tools (Easiest)

- **Canva**: https://www.canva.com (free templates)
- **Figma**: https://www.figma.com (design tool)
- **Logo.com**: Generate AI logos

### Option 2: Use ImageMagick (Create placeholder)

```bash
# Create a simple blue icon with "IW" text
convert -size 1024x1024 xc:"#1E88E5" \
  -gravity center \
  -pointsize 400 -font Arial-Bold \
  -fill white -annotate +0+0 "IW" \
  app_icon.png

# Create splash logo
convert -size 512x512 xc:transparent \
  -gravity center \
  -pointsize 200 -font Arial-Bold \
  -fill "#1E88E5" -annotate +0-50 "InkaWallet" \
  -pointsize 80 \
  -fill "#424242" -annotate +0+100 "Accessible Banking" \
  splash_logo.png
```

### Option 3: Professional Design

Hire a designer on:

- Fiverr ($5-50)
- Upwork
- 99designs

## Color Scheme

- Primary Blue: #1E88E5
- Dark: #424242
- White: #FFFFFF
- Accent: #4CAF50 (green for money/growth)

## After Adding Images

Run these commands to generate icons:

```bash
cd mobile
flutter pub get
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```
