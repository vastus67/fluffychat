# Afterdamage Splash Screen Rebrand Guide

This document outlines all changes made to rebrand FluffyChat's splash/launch screens to Afterdamage branding.

## Files Modified

### 1. **pubspec.yaml**
- **Change**: Updated `flutter_native_splash` configuration
- **Details**:
  - Changed `color` from `#ffffff` to `#000000` (pure black background for light mode)
  - Changed `color_dark` remains `#000000` (pure black for dark mode)
  - Changed `image` from `assets/info-logo.png` to `assets/afterdamage-logo.png`

### 2. **lib/widgets/lock_screen.dart**
- **Change**: Updated logo asset reference
- **Details**:
  - Changed `Image.asset('assets/info-logo.png', width: 256)` to `Image.asset('assets/afterdamage-logo.png', width: 256)`

## Required Assets

### Primary Splash Logo
**Location**: `assets/afterdamage-logo.png`
**Requirements**:
- Save the provided Afterdamage mascot image (red anime character in speech bubble on black background)
- Recommended size: 1024x1024px or larger (square aspect ratio)
- Format: PNG with transparency
- The image should work well centered on a pure black (#000000) background

## Asset Regeneration Commands

After placing the `afterdamage-logo.png` file in the `assets/` directory, you MUST run the following commands to regenerate platform-specific splash screens:

### Step 1: Clean existing build artifacts
```bash
flutter clean
```

### Step 2: Get dependencies
```bash
flutter pub get
```

### Step 3: Generate splash screens
```bash
flutter pub run flutter_native_splash:create
```

This will automatically update:
- **Android**: 
  - `android/app/src/main/res/drawable*/splash.png` (all densities: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
  - `android/app/src/main/res/drawable*/background.png`
  - `android/app/src/main/res/drawable*/launch_background.xml`
  
- **iOS**:
  - `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png` (@1x, @2x, @3x)
  - `ios/Runner/Assets.xcassets/LaunchBackground.imageset/background.png`
  - `ios/Runner/Assets.xcassets/LaunchBackground.imageset/darkbackground.png`
  
- **Web**:
  - `web/splash/img/light-*.png` (1x through 4x)
  - `web/splash/img/dark-*.png` (1x through 4x)

## Platform-Specific Details

### Android
- **Pre-Android 12**: Uses `launch_background.xml` layer-list with pure black background and centered splash image
- **Android 12+**: Currently uses same approach (no values-v31 theme detected)
- **Background**: Pure black (#000000)
- **Image scaling**: Center gravity, no stretching
- **App Icon**: Still uses FluffyChat cat logo (see App Icon Rebrand section below if you want to change this)

### iOS
- **Launch Screen**: `ios/Runner/Base.lproj/LaunchScreen.storyboard`
- Uses `LaunchBackground` (pure black) and `LaunchImage` (Afterdamage mascot)
- Image content mode: `center` (no stretching)
- **App Icon**: Still uses FluffyChat cat logo (see App Icon Rebrand section below)

### Web
- **Splash images**: Generated in light and dark variants (even though both use black background now)
- **App icons**: `web/icons/Icon-192.png` and `Icon-512.png` still use FluffyChat branding
- **Favicon**: `web/favicon.png` still uses FluffyChat branding

## Verification Checklist

After running the regeneration commands, verify:

- [ ] `assets/afterdamage-logo.png` exists and contains the Afterdamage mascot
- [ ] All Android `splash.png` files show Afterdamage mascot (check drawable-mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- [ ] All Android `background.png` files are pure black
- [ ] iOS `LaunchImage.png` (@1x, @2x, @3x) show Afterdamage mascot
- [ ] iOS `background.png` and `darkbackground.png` are pure black
- [ ] Web splash images (light-*.png and dark-*.png) show Afterdamage mascot on black
- [ ] Run app on Android device/emulator and verify splash shows Afterdamage mascot on black background
- [ ] Run app on iOS device/simulator and verify splash shows Afterdamage mascot on black background
- [ ] Run app on web and verify splash shows Afterdamage mascot on black background

## App Icon Rebrand (Optional - Not Included in This Change)

If you also want to replace the app launcher icons with Afterdamage branding, you'll need to:

### Android App Icon
- Replace/update `android/app/src/main/res/drawable/ic_launcher_foreground.xml` (current FluffyChat cat vector)
- Update `android/app/src/main/res/mipmap-*/ic_launcher.png` files for all densities
- Consider using an icon generator tool or flutter_launcher_icons package

### iOS App Icon  
- Replace images in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Provide all required sizes (20pt through 1024pt at various scales)

### Web Icons
- Replace `web/icons/Icon-192.png`
- Replace `web/icons/Icon-512.png`
- Replace `web/favicon.png`
- Update `web/manifest.json` if icon names change

## Additional Branding Assets (For Reference)

The following assets exist but are NOT changed by this splash screen rebrand:

- `assets/banner.png` - Used in intro/login pages
- `assets/banner_transparent.png` - Used in intro/login pages (Hero animation tag: 'info-logo')
- `assets/logo.png` - Generic logo
- `assets/logo.svg` - SVG version
- `assets/logo_transparent.png` - Logo with transparency
- `assets/favicon.png` - Favicon

If you want to rebrand these as well, create Afterdamage versions and update references in:
- `lib/pages/login/login_view.dart` (line ~37: uses 'assets/banner_transparent.png')
- `lib/pages/intro/intro_page.dart` (line ~87: uses './assets/banner_transparent.png')

## Troubleshooting

### Splash not updating after regeneration
1. Run `flutter clean`
2. Delete build folders: `build/`, `android/app/build/`, `ios/build/`
3. Restart IDE/editor
4. Rebuild app completely

### Black screen instead of logo
- Verify `afterdamage-logo.png` is in `assets/` directory
- Check file is not corrupted
- Ensure image has proper contrast against black background
- Verify pubspec.yaml has `assets/` in the assets list

### Logo stretched or distorted
- Ensure source image is square aspect ratio (1:1)
- Check image resolution is at least 1024x1024px
- Verify flutter_native_splash config doesn't have `fill: true`

## Notes

- The hero animation tag 'info-logo' is kept unchanged in login/intro pages (it's just an animation identifier)
- Package identifiers remain unchanged (chat.fluffy.fluffychat)
- Only visual branding updated, no functional changes
- The Dracula theme colors remain (#282A36, #44475A, #F8F8F2, #6272A4)
