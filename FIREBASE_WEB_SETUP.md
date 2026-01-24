# Firebase Web Configuration Required

## Issue
The app is failing to initialize Firebase on web because the web app configuration is missing.

## Solution Options

### Option 1: Use FlutterFire CLI (Recommended)

1. Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

2. Configure Firebase for all platforms:
```bash
flutterfire configure
```

3. This will automatically generate `lib/firebase_options.dart` with all platform configurations.

### Option 2: Manual Configuration from Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **IST-FLUTTER-ANDROID-APP**
3. Click the gear icon → **Project settings**
4. Scroll to **"Your apps"** section
5. If you don't see a Web app:
   - Click **"Add app"** → Select **Web** (</> icon)
   - Register the app (nickname: "LegitBuy Web" or similar)
   - Copy the `firebaseConfig` object
6. If you already have a Web app, click on it to see the config

7. Update `lib/core/config/firebase_options.dart` with the web appId:
   - Find the `appId` in the config (format: `1:410774179221:web:XXXXXXXX`)
   - Replace `YOUR_WEB_APP_ID` in the file with the actual appId

### Quick Fix (Temporary - for testing only)

If you just want to test on Android for now, you can temporarily disable web support or run:
```bash
flutter run -d android
```

## After Configuration

Once you have the correct web appId, update `lib/core/config/firebase_options.dart` line 52:
```dart
appId: '1:410774179221:web:YOUR_ACTUAL_APP_ID', // Replace with actual ID
```

Then run the app again.
