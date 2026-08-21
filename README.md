🐕 Dojo Walker

Dojo Walker is a dog-walking service application designed to connect dog owners with verified walkers for safe and convenient dog walking.

🚀 Features

- 📱 Mobile OTP authentication
- 👤 Walker profile & verification
- 🐕 Dog and owner information
- 📍 Real-time GPS location
- 🗺️ Live walk tracking with OpenStreetMap
- 📲 QR-based walk verification
- 🚶 Insta Walk / Walk Request system
- 🔔 Custom walk request ringtone
- ✅ Accept / Reject walk requests
- 🟢 Live Walk session
- 📊 Walk distance and duration tracking
- 💩 Pee / Poop walk events
- 🛣️ Route coordinate tracking
- 📞 Owner contact during active walks
- 🔥 Firebase Authentication
- ☁️ Cloud Firestore
- 🖼️ Firebase Storage

🛠️ Technology Stack

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- OpenStreetMap
- Flutter Map
- Geolocator
- Mobile Scanner
- AudioPlayers

📦 Main Flutter Packages

firebase_core
firebase_auth
cloud_firestore
firebase_storage
shared_preferences
connectivity_plus
geolocator
flutter_map
latlong2
mobile_scanner
image_picker
url_launcher
audioplayers

🔄 Walk Request Flow

Owner creates walk request
          ↓
     Searching
          ↓
   Walker receives request
          ↓
     ┌────┴────┐
     ↓         ↓
  Accept     Reject
     ↓         ↓
 Accepted   Rejected
     ↓
 Start Live Walk
     ↓
 Active Walk
     ↓
 End Walk
     ↓
 Completed

🔔 Walk Request Alert

When a new walk request is available, the Walker app can play a custom walk-request ringtone.

The ringtone is designed specifically for walk requests and stops when the Walker accepts or rejects the request.

📍 Live Walk

During an active walk, the application can track:

- Current latitude
- Current longitude
- Walking distance
- Walk duration
- Route coordinates
- Pee count
- Poop count
- Walk events

Live walk data is synchronized with Firebase.

🔥 Firebase Collections

The application uses Firebase collections such as:

walk_requests
active_walk
liveWalkSessions
phoneAccounts

"walk_requests"

Stores owner, dog, pickup, walker assignment and walk status information.

"active_walk"

Stores the current active walk state and live walker location.

"liveWalkSessions"

Stores the live walking session, route, distance, duration and walk events.

"phoneAccounts"

Stores account information used to associate Firebase Authentication users with application-level Walker IDs.

🎨 Assets

assets/
├── DOJO_WALKER.png
├── dojo_walker_splash.png
└── audio/
    └── Dojo_Walker_Walk_Request.mp3

⚙️ Setup

Clone the repository and install dependencies:

flutter pub get

Then configure Firebase for the Android application.

Run the application:

flutter run

🧪 Testing

Before releasing the application, test the complete flow:

Login
 ↓
OTP Verification
 ↓
Walker Profile
 ↓
Walker Home
 ↓
Walk Request
 ↓
Accept / Reject
 ↓
Start Live Walk
 ↓
GPS Tracking
 ↓
End Walk
 ↓
Completed Walk

Also verify:

- Firebase data is saved correctly
- Walker ID and Firebase UID remain separate
- Location updates correctly
- Walk request ringtone starts and stops correctly
- Accept/Reject works only once
- Live walk session is created correctly
- Walk completion updates all required collections

📱 Android Build

Build a release APK:

flutter build apk --release

For smaller architecture-specific APKs:

flutter build apk --split-per-abi --release

🔐 Security

Firebase Security Rules should restrict access to authenticated users and ensure that Walker and Owner data can only be accessed according to the application's authorization requirements.

Never commit private keys, passwords, API secrets, or other sensitive credentials to GitHub.

📌 Project Status

🚧 Dojo Walker is currently under active development and testing.

Features and database structures may change during development.

👨‍💻 Developer

Dojo Walker

Built with ❤️ using Flutter and Firebase.
