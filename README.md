🐕 Dojo Walker

Dojo Walker is a dog-walking service application that connects dog owners with verified walkers for safe, reliable, and convenient dog walking.

The application is built with Flutter and Firebase and supports real-time walk requests, GPS tracking, live walk sessions, QR verification, and walk history.

---

🚀 Features

- 📱 Mobile OTP authentication
- 👤 Walker profile and verification
- 🐕 Dog and owner information
- 📍 Real-time GPS location tracking
- 🗺️ Live walk tracking with OpenStreetMap
- 📲 QR-based walk verification
- 🚶 Insta Walk / Walk Request system
- 🔔 Custom walk request ringtone
- ✅ Accept / Reject walk requests
- 🟢 Live Walk sessions
- 📊 Walk distance, duration and steps tracking
- 💩 Pee / Poop walk events
- 🛣️ Route coordinate tracking
- 📞 Owner contact during active walks
- 🔥 Firebase Authentication
- ☁️ Cloud Firestore
- 🖼️ Firebase Storage

---

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

---

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

---

🔄 Walk Request Flow

Owner creates walk request
          ↓
       Searching
          ↓
Walker receives walk request
          ↓
     ┌────┴────┐
     ↓         ↓
   Accept    Reject
     ↓
  Accepted
     ↓
   Reached
     ↓
 Live Walk Session
     ↓
  Active Walk
     ↓
  Complete
     ↓
   Walk History

---

🚶 Insta Walk

Insta Walk allows an online walker to receive nearby walk requests.

The current Insta Walk architecture uses:

- Walker online availability
- Explicit Insta Walk search mode
- Nearby request discovery
- 3.5 km search radius
- Accept / Reject handling
- Custom request ringtone
- GPS-based distance validation
- Canonical "DW######" Walk ID

The walker does not automatically enter search mode simply by going online. Insta Walk search is started explicitly by the walker.

---

📍 GPS & Location Lifecycle

"WalkerAvailabilityService" is the owner of the walker's availability and GPS lifecycle.

OFFLINE
   ↓
Go Online
   ↓
GPS ON
   ↓
SEARCHING / AVAILABLE
   ↓
ACCEPT
   ↓
GPS stays ON
   ↓
REACHED
   ↓
GPS stays ON
   ↓
LIVE WALK
   ↓
GPS stays ON
   ↓
COMPLETE
   ↓
Walker remains ONLINE
   ↓
Insta Walk search resumes

Important GPS Rules

- GPS is controlled centrally by "WalkerAvailabilityService".
- "WalkerLocationService" is the canonical GPS source.
- Incoming walk request services only listen for location/state.
- Live walk background services do not start or stop GPS.
- Accepting a walk does not stop GPS.
- Reaching the owner does not stop GPS.
- Completing a walk does not automatically take the walker Offline.
- A walker can manually go Offline after completing the walk.
- Active walk state must be restored from the backend after app restart, reinstall, crash, or network reconnection.

---

🆔 Walk ID

Dojo Walker uses one canonical Walk ID format:

DW######

Example:

DW000001

The same Walk ID is used across the walk lifecycle.

---

🔥 Firebase Collections

The current canonical Firestore structure uses:

walk_request
liveWalkSessions
walk_history
phoneAccounts

"walk_request"

Stores the incoming walk request and request lifecycle.

Typical lifecycle:

searching
   ↓
accepted
   ↓
reached

The document ID is the canonical "DW######" Walk ID.

---

"liveWalkSessions"

Stores the active live walk session.

It contains information such as:

- Owner
- Walker
- Dog
- Walk ID
- Current walker location
- Walk status
- Start state
- Tracking state
- Distance
- Duration
- Route coordinates
- Pee events
- Poop events
- Walk events

The document ID is the same canonical "DW######" Walk ID.

---

"walk_history"

Stores completed walk information for historical records.

The completed walk continues to use the same canonical Walk ID.

---

"phoneAccounts"

Associates Firebase Authentication accounts with application-level account information such as Walker IDs.

Firebase UID and application Walker ID remain separate identifiers.

---

🔔 Walk Request Alert

When a new walk request is available, the Walker app can play a custom walk-request ringtone.

The ringtone:

- Starts when an eligible request is received.
- Continues while the request is waiting.
- Stops after Accept or Reject.
- Is controlled independently from GPS tracking.

Asset:

assets/audio/Dojo_Walker_Walk_Request.mp3

---

🟢 Live Walk

During an active walk, Dojo Walker can track:

- Current latitude
- Current longitude
- Walking distance
- Walk duration
- Steps
- Route coordinates
- Pee count
- Poop count
- Walk events

Live walk information is synchronized with Firebase.

The walker remains GPS-enabled throughout the active walk.

---

📲 QR Walk Verification

The application supports QR-based walk verification.

The QR flow connects the walker to the canonical walk session using the existing Walk ID / request information.

After successful verification, the walker can continue into the Live Walk flow.

---

🔐 Walker Availability

Walker availability has two separate concepts:

Online / Offline

Controls whether the walker is available to operate.

Insta Walk Search

Controls whether the online walker is actively searching for nearby Insta Walk requests.

Therefore:

ONLINE
   ≠
SEARCHING

A walker can be Online without actively searching for Insta Walk requests.

During an accepted or active walk:

ONLINE
GPS ON
SEARCH LOCKED

After completion:

ONLINE
GPS ON
SEARCH AVAILABLE

---

🎨 Assets

assets/
├── DOJO_WALKER.png
├── dojo_walker_splash.png
└── audio/
    └── Dojo_Walker_Walk_Request.mp3

---

⚙️ Setup

Install Flutter dependencies:

flutter pub get

Configure Firebase for the Android application.

Run the application:

flutter run

---

🧪 Testing

Before release, test the complete flow:

Login
 ↓
OTP Verification
 ↓
Walker Profile
 ↓
Walker Home
 ↓
Go Online
 ↓
Start Insta Walk Search
 ↓
Walk Request
 ↓
Accept / Reject
 ↓
Reach Owner
 ↓
Live Walk
 ↓
GPS Tracking
 ↓
Pee / Poop Events
 ↓
Complete Walk
 ↓
Walk History

Also verify:

- Firebase data is saved correctly.
- Walker ID and Firebase UID remain separate.
- GPS starts when the walker goes Online.
- GPS remains active during Accept → Reach → Live → Complete.
- GPS location updates correctly.
- Walk request ringtone starts correctly.
- Walk request ringtone stops after Accept or Reject.
- Accept can only happen once.
- Reject can only happen once.
- Walk ID remains consistent across collections.
- "liveWalkSessions" is created correctly after Reach.
- Live location is synchronized correctly.
- Walk completion updates the required Firebase documents.
- Completing a walk does not automatically make the walker Offline.
- Insta Walk search can resume after completion.
- Active walk state can be restored after app restart or network reconnection.

---

📱 Android Build

Build a release APK:

flutter build apk --release

For architecture-specific APKs:

flutter build apk --split-per-abi --release

---

🔐 Security

Firebase Security Rules should restrict access to authenticated users and ensure that Walker, Owner, Walk Request, Live Walk and History data can only be accessed according to the application's authorization requirements.

Never commit:

- Private keys
- Passwords
- API secrets
- Service-account credentials
- Other sensitive credentials

to GitHub.

---

📌 Project Status

🚧 Dojo Walker is currently under active development and testing.

The application architecture, UI, Firebase structure and walk lifecycle may continue to evolve during development.

---

👨‍💻 Developer

Dojo Walker

Built with ❤️ using Flutter and Firebase.
