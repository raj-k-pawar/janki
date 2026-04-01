# 🌾 Janki Agro Tourism - Flutter App

## Overview
Full-featured agro tourism management app for Android & iOS with:
- Multi-role login (Manager / Owner / Admin / Canteen)
- Manager dashboard with today's stats
- Customer booking with package selection
- QR code generation for canteen food validation
- Worker management
- MySQL database via PHP REST API

---

## 📁 Project Structure

```
janki_agro_tourism/
├── lib/
│   ├── main.dart                        # App entry point
│   ├── models/models.dart               # All data models
│   ├── services/
│   │   ├── database_service.dart        # API calls to PHP backend
│   │   └── auth_provider.dart           # Auth state management
│   ├── utils/app_theme.dart             # Colors, theme, constants
│   └── screens/
│       ├── splash_screen.dart           # Splash / auto-login
│       ├── login_screen.dart            # Login + Register
│       ├── manager/
│       │   ├── manager_dashboard.dart   # Dashboard with stats
│       │   ├── add_customer_screen.dart # Add/Edit customer form
│       │   ├── all_customers_screen.dart# View all customers
│       │   ├── workers_screen.dart      # Manage workers
│       │   └── qr_display_screen.dart   # QR after booking
│       └── canteen/
│           └── canteen_screen.dart      # QR scanner for food
├── php_api/                             # Upload to InfinityFree hosting
│   ├── db_config.php                    # DB connection + helpers
│   ├── login.php                        # POST /api/login
│   ├── register.php                     # POST /api/register
│   ├── dashboard.php                    # GET /api/dashboard
│   ├── customers.php                    # GET/POST/PUT/DELETE /api/customers
│   ├── workers.php                      # GET/POST/PUT/DELETE /api/workers
│   ├── validate_qr.php                  # POST /api/validate_qr
│   ├── setup_database.sql               # Run once in phpMyAdmin
│   └── .htaccess                        # CORS + routing rules
├── android/app/src/main/
│   └── AndroidManifest.xml              # Camera + Internet permissions
├── ios/Runner/
│   └── Info.plist                       # iOS Camera permissions
└── pubspec.yaml                         # Dependencies
```

---

## 🚀 Setup Steps

### STEP 1 – Database Setup (phpMyAdmin on InfinityFree)

1. Log in to InfinityFree → go to **phpMyAdmin**
2. Select database: `if0_41504818_janki`
3. Click **SQL** tab
4. Copy & paste the contents of `php_api/setup_database.sql`
5. Click **Go** to execute

---

### STEP 2 – Upload PHP API to InfinityFree

1. Log in to InfinityFree → **File Manager** or use **FTP** (FileZilla)
2. Navigate to `htdocs/` folder
3. Create a new folder named **`api`**
4. Upload ALL files from `php_api/` folder into `htdocs/api/`

Your API URLs will then be:
```
https://yourdomain.infinityfreeapp.com/api/login.php
https://yourdomain.infinityfreeapp.com/api/register.php
https://yourdomain.infinityfreeapp.com/api/dashboard.php
https://yourdomain.infinityfreeapp.com/api/customers.php
https://yourdomain.infinityfreeapp.com/api/workers.php
https://yourdomain.infinityfreeapp.com/api/validate_qr.php
```

---

### STEP 3 – Update BASE_URL in Flutter App

Open `lib/services/database_service.dart` and update:

```dart
static const String BASE_URL = 'https://yourdomain.infinityfreeapp.com/api';
```

Replace `yourdomain` with your actual InfinityFree subdomain.

---

### STEP 4 – Install Flutter Dependencies

```bash
cd janki_agro_tourism
flutter pub get
```

---

### STEP 5 – Run the App

**Android:**
```bash
flutter run
```

**Build APK:**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**iOS (requires Mac + Xcode):**
```bash
flutter build ios --release
```

---

## 📱 Default Login Credentials

After running `setup_database.sql`, two default users are created:

| Username  | Password    | Role    |
|-----------|-------------|---------|
| `admin`   | `admin123`  | Admin   |
| `manager` | `manager123`| Manager |

> **Note:** You can register new users via the Register screen in the app.

---

## 🔑 User Roles & Access

| Role      | Access                                      |
|-----------|---------------------------------------------|
| Manager   | Dashboard, Add/View Customers, Workers       |
| Owner     | Same as Manager (full access)                |
| Admin     | Same as Manager (full access)                |
| Canteen   | QR Scanner screen only                       |

---

## 📦 Packages (Marathi)

| Package               | Adults (10+) | Children (3-10) |
|-----------------------|-------------|-----------------|
| सकाळी हाफ डे पॅकेज   | ₹500        | ₹400            |
| सायंकाळी हाफ डे पॅकेज | ₹500        | ₹400            |
| फुल डे पॅकेज          | ₹650        | ₹500            |
| A C डिलक्स रूम        | ₹1800       | ₹1300           |
| Non A C रूम           | ₹1500       | ₹1100           |

---

## 🔲 QR Code Flow

1. Manager adds a customer → **QR code generated automatically**
2. QR code is shown on screen (valid for today only, single use)
3. Canteen staff opens the app → **Scan QR Code**
4. App validates QR via server → shows customer food details
5. QR is marked as **used** — cannot be scanned again

---

## 🛠️ Tech Stack

| Layer      | Technology                          |
|------------|-------------------------------------|
| Frontend   | Flutter (Dart) - Android & iOS      |
| State Mgmt | Provider                            |
| HTTP       | http package                        |
| QR Display | qr_flutter                          |
| QR Scan    | qr_code_scanner                     |
| Storage    | shared_preferences                  |
| Backend    | PHP 7.4+ REST API                   |
| Database   | MySQL (InfinityFree hosting)        |

---

## ⚠️ Important Notes

1. **Direct MySQL from Flutter is not supported** — the PHP REST API layer is required.
2. InfinityFree may be slow on the free plan — consider upgrading for production.
3. The QR token is generated on the server and is unique per booking.
4. QR codes are valid **today only** and can be used **once only**.
5. Make sure your InfinityFree domain has **SSL (HTTPS)** for secure API calls.

---

## 📞 Support

For any issues, check:
- PHP error logs in InfinityFree control panel
- Flutter debug console: `flutter run --verbose`
- Test API with Postman before connecting to the app
