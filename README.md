# RainGuard

RainGuard is a Flutter/Firebase capstone app for community rain, flood, risk, and safety reporting in Barangay Quiling, Talisay, Batangas. It helps users monitor local weather, view community reports on a map, submit verified reports, and receive report notifications.

## Features

- Splash, first-time onboarding, login, sign-up, and Google authentication
- Firebase Auth account handling with Firestore user profiles
- Home dashboard with Quiling/Talisay weather, flood risk context, safety tips, and hotlines
- Quiling-centered OpenStreetMap report map
- Community report submission with GPS location and multiple image support
- Firestore-based notification feed for recent reports
- Push notification token registration and Firebase Cloud Function report alerts
- Settings screen with profile details, verification status, notification/location toggles, and logout

## Tech Stack

- Flutter and Dart
- Firebase Core, Auth, Cloud Firestore, Storage, Messaging, and Cloud Functions
- `flutter_map` with OpenStreetMap tiles
- `geolocator` for device location
- `image_picker` for report images
- OpenWeather API through a Firebase Functions proxy
- Nominatim reverse geocoding
- Google Fonts Poppins

## Project Structure

```text
lib/
  main.dart
  models/
  screens/
  screens/auth/
  services/
  theme/
  utils/
  widgets/
  widgets/settings/
functions/
android/
ios/
```

Important areas:

- `lib/main.dart` initializes Firebase, app theme, and app startup.
- `lib/screens/` contains Home, Map, Notifications, Settings, Splash, and auth screens.
- `lib/services/` contains Firebase, location, weather, geocoding, storage, report, and notification token logic.
- `lib/models/` contains shared data models such as reports and user profiles.
- `functions/index.js` sends push notifications when new reports are created and proxies weather requests.

## Setup

1. Install Flutter and confirm your local toolchain:

```bash
flutter doctor
```

2. Install app dependencies:

```bash
flutter pub get
```

3. Configure Firebase for your local environment.

This project expects Firebase configuration files to exist locally, but they are intentionally ignored by Git:

- `lib/firebase_options.dart`
- `android/app/google-services.json`

Generate them with FlutterFire CLI when needed:

```bash
flutterfire configure
```

4. Install Cloud Functions dependencies when working on backend features:

```bash
cd functions
npm install
```

5. Store the OpenWeather key as a Firebase Functions secret before deploying the weather proxy:

```bash
firebase functions:secrets:set OPENWEATHER_API_KEY
```

## Running The App

Run on a connected device or emulator:

```bash
flutter run
```

For analysis:

```bash
flutter analyze
```

Run tests when available:

```bash
flutter test
```

## Firebase Notes

RainGuard uses these Firestore collections:

- `reports`
- `users`
- `users/{uid}/fcm_tokens/{token}`

Report submission should include the authenticated user's ID and display name when available. User verification statuses should remain explicit, such as `unverified`, `pending`, `verified`, and `rejected`.

Never commit local secrets, service account files, `.env`, Firebase admin credentials, database passwords, or storage secrets.

## Deployment Notes

Deploy all Cloud Functions with:

```bash
firebase deploy --only functions
```

Deploy only the weather proxy with:

```bash
firebase deploy --only functions:getWeather
```

Before pushing changes, check:

```bash
git status
```

Do not commit IDE-local files such as `.idea/workspace.xml`.
