# Janki Agro Tourism - Flutter App
### Water Park Management System (Android + iOS)

---

## 📁 Project Structure

```
janki_waterpark/
├── lib/
│   ├── main.dart
│   ├── models/models.dart
│   ├── services/
│   │   ├── api_service.dart        ← UPDATE THE URL HERE
│   │   └── auth_provider.dart
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── manager_dashboard.dart
│   │   ├── add_booking_screen.dart
│   │   ├── all_customers_screen.dart
│   │   ├── qr_screen.dart
│   │   ├── canteen_dashboard.dart
│   │   └── workers_screen.dart
│   └── utils/app_theme.dart
├── android/                        ← Full Android project (v2 embedding)
├── ios/                            ← Full iOS project (Swift, CocoaPods)
├── api.php                         ← Deploy this to InfinityFree hosting
├── codemagic.yaml                  ← CI/CD for Codemagic builds
└── pubspec.yaml
```

---

## 🚀 STEP 1 — Deploy PHP API

1. Login to InfinityFree → File Manager → `public_html`
2. Upload `api.php` to `public_html/api.php`
3. Visit `https://yourdomain.infinityfreeapp.com/api.php` in browser
   - You should see: `{"success":false,"message":"Unknown action: "}`
   - This confirms the API is working ✅

4. Open `lib/services/api_service.dart` and update line 4:
```dart
const String BASE_URL = 'https://YOUR-DOMAIN.infinityfreeapp.com/api.php';
```

---

## 📱 STEP 2 — Add App Logo

1. Create folder `assets/images/` in the project root
2. Copy your logo file as `assets/images/logo.png`

---

## 🔧 STEP 3 — Local Development

```bash
# Install dependencies
flutter pub get

# Run on Android device/emulator
flutter run

# Run on iOS simulator (Mac only)
flutter run -d ios

# Build Android APK
flutter build apk --release

# Build Android App Bundle (for Play Store)
flutter build appbundle --release

# Build iOS (requires Mac + Xcode)
cd ios && pod install && cd ..
flutter build ios --release
```

---

## ☁️ STEP 4 — Build on Codemagic

The `codemagic.yaml` file is already included.

### For Android:
1. Push project to GitHub/GitLab/Bitbucket
2. Login to codemagic.io → Add app → Select repo
3. Codemagic auto-detects `codemagic.yaml`
4. Run `android-workflow`
5. Download the `.apk` or `.aab` from artifacts

### For iOS:
1. Same repo, run `ios-workflow`
2. For App Store distribution, add your Apple Developer certificate
   and provisioning profile in Codemagic → Code signing
3. Download `.ipa` from artifacts

---

## 👤 Default Login Credentials

| Role    | Username  | Password    |
|---------|-----------|-------------|
| Admin   | admin     | admin123    |
| Manager | manager1  | manager123  |
| Owner   | owner1    | owner123    |
| Canteen | canteen1  | canteen123  |

> ⚠️ Change these in your database after first login.

---

## 📋 Feature Summary

| Feature | Description |
|---------|-------------|
| Login | Role-based login with session persistence |
| Dashboard | Today's bookings, guests, revenue, cash/online split |
| Add Customer | Voice input + auto calculations + food deductions |
| Batch Types | Full Day (10-6), Morning (10-3), Afternoon (3-8) |
| Food Options | Auto-selected per batch, deductions on uncheck |
| QR Code | Generated after booking for canteen |
| All Customers | Search, filter, edit, delete |
| Workers | Add/edit/delete staff with roles |
| Canteen View | Today's food orders only |

---

## 🔌 Android Permissions (AndroidManifest.xml)
- `INTERNET` — API calls
- `RECORD_AUDIO` — Voice input
- `ACCESS_NETWORK_STATE` — Network check
- Speech recognition query (Android 11+)

## 🍎 iOS Permissions (Info.plist)
- `NSMicrophoneUsageDescription` — Voice input
- `NSSpeechRecognitionUsageDescription` — Speech to text
- `NSAppTransportSecurity` — HTTP API calls

---

## 🗄️ Database Tables (auto-created by api.php)

- `users` — Login credentials & roles
- `bookings` — All customer bookings
- `workers` — Staff records

---

## ❓ Troubleshooting

**Build error on Codemagic Android:**
- Make sure `codemagic.yaml` is in root of repo
- Ensure `java: 17` is set in environment

**iOS CocoaPods error:**
- Run `cd ios && pod install` locally first
- Commit the `Pods/` folder (or add `Pods/` to git)

**"Connection error" in app:**
- Confirm `api.php` is deployed and accessible
- Confirm URL in `api_service.dart` is correct (no trailing slash)

**Voice input not working on iOS:**
- Check that microphone permission was granted
- Go to Settings → Janki Agro Tourism → Microphone → Allow
