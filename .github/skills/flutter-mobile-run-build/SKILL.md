---
name: flutter-mobile-run-build
description: "Run, analyze, and build the Fluxio Flutter mobile app. Use when: installing Flutter packages, launching Android, checking analyzer results, building APKs, or configuring local Dart defines."
argument-hint: "Optional: 'run', 'apk', 'analyze', or 'clean'"
---

# Flutter Mobile Run and Build

## When to Use

- Fetch Flutter dependencies
- Run the Android app
- Analyze Dart code
- Build an APK
- Clean generated artifacts
- Configure local API key defines

## Commands

```bash
# Install dependencies
flutter pub get

# Analyze
flutter analyze

# Run on default Android device or emulator
flutter run --dart-define-from-file=.env.json

# Pick a device first
flutter devices
flutter run -d <device-id> --dart-define-from-file=.env.json

# Build release APK
flutter build apk --dart-define-from-file=.env.json

# Clean build outputs
flutter clean
```

## Configuration

```bash
cp .env.json.example .env.json
```

Set `FLUXIO_API_KEY` to the same key configured as `PUBLIC_API_KEY` in the backend.

## Mobile Notes

- Android MQTT uses TLS port `8883`.
- Push notifications require Firebase Cloud Messaging setup and Android notification permissions.
- Secure session persistence is handled by the app state/backend API flow.

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| Backend returns forbidden | API key mismatch | Update `.env.json` and backend `PUBLIC_API_KEY` |
| App cannot connect to MQTT | Broker credentials not loaded or wrong port | Confirm backend `/devices/mqtt` response and port `8883` |
| Notifications do not arrive | FCM token not registered or permission missing | Check `notification.dart` and `/users/save-fcm-token` |
| Build cannot find assets | Asset path missing from `pubspec.yaml` | Keep `assets/images/` registered |
| Android build fails after dependency changes | Stale build cache | Run `flutter clean` then `flutter pub get` |

## Safety Rules

- Do not commit `.env.json`.
- Do not hardcode API keys or broker credentials.
- Do not change MQTT topic names without updating backend, web, and ESP32 consumers.
