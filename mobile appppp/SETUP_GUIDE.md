# Flutter App Setup & Run Guide

## System Requirements

- Flutter SDK 3.0.0 or higher
- Dart SDK (comes with Flutter)
- Android Studio or Xcode (for Android/iOS development)
- Java Development Kit (JDK) 11 or higher
- Git

## Installation Steps

### 1. Verify Flutter Installation

```bash
flutter --version
flutter doctor
```

Ensure all required components are installed. You should see green checkmarks.

### 2. Get Dependencies

Navigate to the project directory:

```bash
cd d:\civic-grievance-system\mobile\ appppp
flutter pub get
```

### 3. Configure Backend Connection

Edit `lib/config/constants.dart` and verify the API base URL:

```dart
static const String apiBaseUrl = 'http://localhost:5000';
```

Update if your backend is running on a different port or server.

### 4. Ensure Backend is Running

Before running the app, start the Flask backend:

```bash
# From the civic-grievance-system directory
python3 run_project.py
```

The backend should be running on `http://localhost:5000`

## Running the App

### Android

**Using Android Emulator:**
```bash
# List available emulators
flutter emulators --list

# Launch an emulator
flutter emulators --launch <emulator_name>

# Run the app
flutter run
```

**Using Physical Device:**
1. Enable Developer Mode on your device
2. Connect via USB and enable USB Debugging
3. Run: `flutter run`

### iOS (macOS Only)

```bash
# Install pods
cd ios
pod install
cd ..

# Run the app
flutter run -d iPhone

# Or specify a device
flutter run -d "iPhone 14 Pro"
```

### Web (Chrome)

```bash
flutter run -d chrome
```

### Web (Firefox)

```bash
flutter run -d firefox
```

## Building Release Versions

### Android APK

```bash
# Build single APK
flutter build apk --release

# Or split by architecture
flutter build apk --split-per-abi --release
```

Output: `build/app/outputs/flutter-apk/`

### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/`

### iOS (requires macOS)

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

Output: `build/web/`

## Testing

### Run Unit Tests

```bash
flutter test
```

### Run Integration Tests

```bash
flutter test integration_test
```

## Troubleshooting

### Issue: "Target of URI doesn't exist: 'package:flutter/material.dart'"

**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: Android Build Fails

**Solution:**
```bash
flutter clean
rm -rf android/.gradle
flutter run
```

### Issue: iOS Build Fails

**Solution:**
```bash
flutter clean
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..
flutter run
```

### Issue: Connection Refused Error

**Verify:**
1. Backend is running on `http://localhost:5000`
2. Device/emulator has network access
3. Firewall is not blocking the connection
4. Update API URL in `constants.dart` if needed

### Issue: App Crashes on Startup

**Check:**
1. Flutter version matches (3.0+)
2. All dependencies installed: `flutter pub get`
3. Android/iOS build files are clean
4. No errors in console logs: `flutter run -v`

## Development Tips

### Hot Reload
- Press `r` during `flutter run` to hot reload
- Press `R` to hot restart

### Verbose Logging
```bash
flutter run -v
```

### Device Logs
```bash
flutter logs
```

### Debugging
Press `l` in the console for DevTools browser

## Project Structure Reference

```
lib/
├── config/          # Constants and theme
├── models/          # Data models
├── services/        # API and authentication services
├── screens/         # App screens (auth, citizen, admin)
├── widgets/         # Reusable UI components
├── utils/           # Utilities (format, validators)
└── main.dart        # Entry point
```

## API Integration

The app communicates with the Flask backend on `http://localhost:5000`. Key endpoints:

- `POST /auth/login` - User authentication
- `POST /auth/register` - User registration
- `POST /complaints` - Submit new complaint
- `GET /complaints` - Get all complaints
- `GET /complaints/mine` - Get user's complaints
- `GET /analytics/summary` - Get analytics data

## Demo Credentials

| Role | Username | Password |
|------|----------|----------|
| Citizen | user1 | pass123 |
| Admin | admin | admin123 |

## Performance Optimization

### Enable Production Mode

```bash
flutter run --release
```

### Use Build Cache

```bash
flutter pub cache repair
```

### Analyze Performance

```bash
flutter run --profile
```

## Deployment Checklist

- [ ] Update app version in `pubspec.yaml`
- [ ] Update build number in Android/iOS config
- [ ] Generate app icon and splash screen
- [ ] Test on multiple devices
- [ ] Verify backend connectivity
- [ ] Test all features (auth, submit, track, admin)
- [ ] Check error handling
- [ ] Review API keys and sensitive data
- [ ] Build release version
- [ ] Sign the app (Android)
- [ ] Create distribution certificates (iOS)

## Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Flutter Widget Catalog](https://flutter.dev/docs/development/ui/widgets)
- [pub.dev Packages](https://pub.dev)

## Support & Debugging

For detailed logs:
```bash
flutter run -v > debug.log
```

Check logs in:
- Android: `adb logcat`
- iOS: Xcode console
- Web: Browser DevTools (F12)

---

For more help, refer to the main README.md or the project guide.
