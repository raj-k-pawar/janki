# Janki Agro Tourism - Flutter App

## 🏗️ Project Structure

```
janki_waterpark/
├── lib/
│   ├── main.dart                    ← App entry point & routing
│   ├── models/
│   │   └── models.dart              ← User, Booking, Worker models
│   ├── services/
│   │   ├── api_service.dart         ← HTTP API client
│   │   └── auth_provider.dart       ← Auth state management
│   ├── screens/
│   │   ├── login_screen.dart        ← Login UI
│   │   ├── manager_dashboard.dart   ← Manager/Owner/Admin dashboard
│   │   ├── add_booking_screen.dart  ← New/Edit booking form (with voice input)
│   │   ├── all_customers_screen.dart← All bookings with search/filter
│   │   ├── qr_screen.dart           ← QR code display for canteen
│   │   ├── canteen_dashboard.dart   ← Canteen staff view
│   │   └── workers_screen.dart      ← Worker management
│   └── utils/
│       └── app_theme.dart           ← Colors, fonts, theme
├── api.php                          ← ⚠️ DEPLOY THIS TO YOUR HOSTING
├── android/
│   └── app/src/main/AndroidManifest.xml
└── pubspec.yaml
```

---

## 🚀 STEP 1: Deploy the PHP API

1. Login to your InfinityFree account
2. Go to your File Manager → `public_html`
3. Upload `api.php` to `public_html/api.php`
4. Test it: visit `https://yourdomain.infinityfreeapp.com/api.php`
   - You should see: `{"success":false,"message":"Unknown action: "}`

5. **Update the URL in the Flutter app:**
   Open `lib/services/api_service.dart` and change:
   ```dart
   const String BASE_URL = 'https://yourdomain.infinityfreeapp.com/api.php';
   ```
   Replace with your actual domain.

---

## 📱 STEP 2: Add Logo Image

1. Create folder: `assets/images/`
2. Copy your logo file there and name it `logo.png`
3. The logo is already referenced in `pubspec.yaml`

---

## 🔧 STEP 3: Install Flutter Dependencies

```bash
flutter pub get
```

---

## ▶️ STEP 4: Run the App

```bash
# Run on connected Android device or emulator
flutter run

# Build APK for distribution
flutter build apk --release
```

---

## 👤 Default Login Credentials

| Role    | Username  | Password    |
|---------|-----------|-------------|
| Admin   | admin     | admin123    |
| Manager | manager1  | manager123  |
| Owner   | owner1    | owner123    |
| Canteen | canteen1  | canteen123  |

> ⚠️ Change these passwords after first login by updating the database directly.

---

## 🗄️ Database

The PHP API **auto-creates** all required tables on first run:
- `users` — login credentials and roles
- `bookings` — customer bookings with all details
- `workers` — staff management

Database details used:
```
Host: sql301.infinityfree.com
DB:   if0_41504818_janki
User: if0_41504818
Pass: Janki123456
```

---

## 📋 Features Summary

### Login Screen
- Username/password login
- Auto-login with saved session
- Routes to correct dashboard by role

### Manager Dashboard
- Today's stats: bookings, guests, revenue, cash/online payments
- Quick action buttons
- Pull-to-refresh

### Add New Customer
- Voice input (hold mic icon to speak)
- Customer name, city, mobile
- Batch selection: Full Day / Morning / Afternoon
- Auto food defaults per batch
- Real-time amount calculation
- Food deductions (uncheck to deduct ₹50/₹100 per guest)
- Cash/Online payment mode
- Saves to DB → Shows QR code for canteen

### View All Customers
- Search by name/mobile/city
- Filter by batch type
- Edit and delete bookings
- View QR code for any booking

### Workers Management
- Add/edit/delete staff
- Track role, salary, status

### Canteen Dashboard
- Today's orders only
- Food items per booking
- QR code view per customer

---

## 🔊 Voice Input

Voice input uses the device microphone:
- **Hold** the mic icon to start listening
- **Release** to stop and fill the field
- Works for: Name, City, Mobile fields
- Requires microphone permission (auto-prompted)

---

## 📦 Dependencies Used

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `http` | API calls |
| `shared_preferences` | Session persistence |
| `qr_flutter` | QR code generation |
| `speech_to_text` | Voice input |
| `google_fonts` | Poppins font |
| `permission_handler` | Mic permissions |

---

## 🛠️ Troubleshooting

**"Connection error" on login:**
- Make sure `api.php` is deployed to your hosting
- Check the URL in `api_service.dart` is correct
- Verify the PHP file is accessible via browser

**Voice input not working:**
- Grant microphone permission when prompted
- Check device has working microphone
- Speech recognition requires internet connection

**QR code not showing:**
- This is generated locally — no internet needed for the QR itself
- The QR data is stored in the database when booking is saved
