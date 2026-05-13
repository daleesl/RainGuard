# RainGuard

RainGuard is a Flutter/Firebase capstone app for community rain, flood, risk, and safety reporting in Calamba, Laguna. It helps users monitor local weather, view community reports on a map, submit verified reports, and receive report notifications.

## Features

- Splash, first-time onboarding, login, sign-up, and Google authentication
- Firebase Auth account handling with Firestore user profiles
- Home dashboard with Lingga/Calamba weather, flood risk context, safety tips, and hotlines
- Calamba-centered OpenStreetMap report map
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
- OpenWeather API through `.env`
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

- `lib/main.dart` initializes environment loading, Firebase, app theme, and app startup.
- `lib/screens/` contains Home, Map, Notifications, Settings, Splash, and auth screens.
- `lib/services/` contains Firebase, location, weather, geocoding, storage, report, and notification token logic.
- `lib/models/` contains shared data models such as reports and user profiles.
- `functions/index.js` sends push notifications when new reports are created.

## Setup

1. Install Flutter and confirm your local toolchain:

```bash
flutter doctor
```

2. Install app dependencies:

```bash
flutter pub get
```

3. Create a local `.env` file in the project root:

```env
OPENWEATHER_API_KEY=your_openweather_api_key
```

4. Configure Firebase for your local environment.

This project expects Firebase configuration files to exist locally, but they are intentionally ignored by Git:

- `lib/firebase_options.dart`
- `android/app/google-services.json`

Generate them with FlutterFire CLI when needed:

```bash
flutterfire configure
```

5. Install Cloud Functions dependencies when working on notifications:

```bash
cd functions
npm install
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

Deploy Cloud Functions with:

```bash
firebase deploy --only functions
```

Before pushing changes, check:

```bash
git status
```

Do not commit IDE-local files such as `.idea/workspace.xml`.
