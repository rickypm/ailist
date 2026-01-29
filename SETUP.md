# AiList Setup Guide

Complete setup instructions for developers. 

## Prerequisites

### Required Software

1. **Flutter SDK** (3.0.0+)
   ```bash
   # Windows (using Chocolatey)
   choco install flutter

   # macOS (using Homebrew)
   brew install flutter

   # Verify installation
   flutter doctor
   ```

2. **Android Studio**
   - Download from:  https://developer.android.com/studio
   - Install Android SDK, SDK Tools, and Emulator

3. **Xcode** (macOS only, for iOS development)
   - Install from App Store
   - Run:  `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`

4. **VS Code** (recommended)
   - Install Flutter and Dart extensions

## Project Setup

### 1. Clone and Install

```bash
git clone https://github.com/yourusername/ailist.git
cd ailist
flutter pub get
```

### 2. Environment Configuration

Create `lib/config/app_config. dart`:

```dart
class AppConfig {
  // Supabase
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // OpenAI
  static const String openAIApiKey = 'YOUR_OPENAI_API_KEY';

  // Razorpay
  static const String razorpayKeyId = 'YOUR_RAZORPAY_KEY_ID';

  // App Settings
  static const String appName = 'WeList';
  static const String appVersion = '1.0.0';
  static const String defaultCity = 'Shillong';
}
```

### 3. Supabase Setup

1. Create a Supabase project at https://supabase.com
2. Go to SQL Editor
3. Copy and paste contents of `supabase/schema.sql`
4. Click "Run"
5. Verify tables are created

### 4. Download Fonts

Download Poppins font family from Google Fonts:
- https://fonts.google.com/specimen/Poppins

Place these files in `assets/fonts/`:
- Poppins-Regular.ttf
- Poppins-Medium.ttf
- Poppins-SemiBold.ttf
- Poppins-Bold. ttf

### 5. Create Placeholder Assets

Create these placeholder images:
- `assets/images/logo.png` (512x512)
- `assets/images/placeholder. png` (300x300)
- `assets/icons/app_icon.png` (1024x1024)

## Running the App

### Android

```bash
# List available emulators
flutter emulators

# Launch an emulator
flutter emulators --launch <emulator_id>

# Run the app
flutter run
```

### iOS (macOS only)

```bash
# Open iOS Simulator
open -a Simulator

# Run the app
flutter run
```

### Web (for testing)

```bash
flutter run -d chrome
```

## Building for Release

### Android APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle

```bash
flutter build appbundle --release
# Output:  build/app/outputs/bundle/release/app-release.aab
```

### iOS

```bash
flutter build ios --release
# Open Xcode and archive from there
```

## Troubleshooting

### Common Issues

1. **Gradle build fails**
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter pub get
   ```

2. **iOS pod install fails**
   ```bash
   cd ios
   pod deintegrate
   pod install
   cd ..
   ```

3. **Missing SDK**
   ```bash
   flutter doctor --android-licenses
   ```

4. **Dependency conflicts**
   ```bash
   flutter pub cache repair
   flutter pub get
   ```

## Support

For issues, please open a GitHub issue or contact support@ailist.app. 