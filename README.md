# Yadavindra Public School - Event Companion App

This package is a standalone, dedicated Flutter mobile application for the **78th Annual Sports Day & School Events** of Yadavindra Public School, Patiala.

## What is Included
- **Home Dashboard & Spotlight**: Live countdown, featured event hero, school contact info, quick navigation.
- **Events & Photos**: High-resolution event galleries, sub-event category filters, performer rosters.
- **Schedules Timeline**: Complete 28-step event sequence with live badges and time slots.
- **Achievers**: Hall of fame, student accolades, house tags.
- **Campus Parking & Gates**: Interactive campus layout map, Nalagarh Gate instructions, parking tips.
- **Event Medical Station**: Campus first-aid contact numbers, ambulance hotline, medical instructions.
- **Parent & Guest Feedback**: Direct feedback form with star ratings.

## How to Build and Upload

### 1. Android (Google Play Store)
Open terminal in this directory and run:
```bash
flutter pub get
flutter build appbundle --release
```
The output file will be at:
`build/app/outputs/bundle/release/app-release.aab`
Upload this `.aab` file to your Google Play Console under **Production > Create new release**.

### 2. iOS (Apple App Store)
On a Mac:
1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select your Apple Developer Team and Bundle Identifier under **Signing & Capabilities**.
3. Select **Product > Archive**.
4. In the Organizer window, click **Distribute App** to upload directly to **App Store Connect**.

## Backend Server
- Hosted at: `http://168.144.112.34`
- API single source of truth: `lib/constants.dart`
