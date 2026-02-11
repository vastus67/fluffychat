# Afterdamage Logo Asset Required

## 📍 Required File

Place your Afterdamage mascot logo here:

**Filename**: `afterdamage-logo.png`  
**Full path**: `assets/afterdamage-logo.png`

## 📐 Specifications

- **Format**: PNG with transparency
- **Size**: 1024x1024px minimum (square aspect ratio required)
- **Content**: The red anime-style character mascot in a speech bubble on transparent or black background
- **Background compatibility**: Image will be displayed on pure black (#000000) background

## 🎨 Design Notes

The logo you provided shows:
- Red/coral colored anime character with X on face
- Inside a speech bubble shape
- Black/dark background
- High contrast suitable for splash screen

This image should be centered on the splash screen and will NOT be stretched.

## 🔄 After Adding the Logo

Once you've placed `afterdamage-logo.png` in this directory, run:

```bash
flutter clean
flutter pub get
flutter pub run flutter_native_splash:create
```

This will generate all platform-specific splash screen assets automatically.

## 🗑️ You Can Delete This File

After placing `afterdamage-logo.png`, you can delete this `AFTERDAMAGE_LOGO_PLACEHOLDER.md` file.
