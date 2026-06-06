# Fluxio Flutter Mobile - Agent Instructions

## Project Overview

Flutter Android app for the Fluxio IoT platform. It handles login, persistent sessions, device management, MQTT telemetry and commands, channel configuration, visual logic editing, firmware upload coordination, and mobile push notifications.

## Build & Test

```bash
flutter pub get
flutter analyze

# Run on an Android device or emulator
flutter run --dart-define-from-file=.env.json

# Build release APK
flutter build apk --dart-define-from-file=.env.json
```

Create `.env.json` from `.env.json.example` before running. The file must define `FLUXIO_API_KEY`.

## Architecture

```
lib/main.dart                         - app bootstrap, theme, persisted login gate
lib/backend_api/api_communication.dart - HTTP client for Fluxio backend
lib/mqtt/mqtt_manager.dart            - TLS MQTT client for Android
lib/services/app_state.dart           - global session/device/MQTT state
lib/services/notification.dart        - FCM/local notification setup
lib/widgets/                          - shared UI widgets
lib/global/                           - global helpers and variables
lib/models/                           - user, device, telemetry, channel models
lib/pages/first_screens/              - login, registration, forgot password
lib/pages/main_screen/                - device list and account/device management
lib/pages/dashboard_screen/           - device details, commands, channels, firmware, logic builder
android/                              - Android Gradle project and native entry point
assets/images/                        - logo and background images
```

## Key Conventions

- Keep backend calls in `lib/backend_api/api_communication.dart`.
- Keep MQTT connection, subscriptions, publishing, and disconnect behavior in `lib/mqtt/mqtt_manager.dart`.
- Keep session-wide state in `appState`; avoid duplicating user/device/MQTT state in pages.
- Use `--dart-define-from-file=.env.json` for `FLUXIO_API_KEY`; never hardcode API keys in Dart.
- Mobile MQTT uses `MqttServerClient` with TLS on broker port `8883`.
- Web MQTT differs from mobile; do not copy mobile MQTT code into the web project without adapting the client type and WebSocket URL.
- FCM and local notification behavior belong in `lib/services/notification.dart`.
- Keep visual logic block models compatible with the ESP32 firmware logic JSON format.

## Security Notes

- Do not commit `.env.json`, API keys, cookies, auth tokens, or broker credentials.
- Keep persisted session data in secure storage where the existing code already uses it.
- Rotate the shared API key if it is exposed.

## Do Not Change Without Understanding

- `main.dart` waits for `appState.tryPersistLogin(context)` before choosing `CardsPage` or `LoginPage`.
- `mqttManager` is a global singleton used by dashboard pages.
- Topic names and payloads must stay compatible with the ESP32 firmware MQTT contract.
- Android notification permissions and FCM token registration are mobile-only concerns.
