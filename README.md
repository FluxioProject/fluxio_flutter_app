# Fluxio Flutter Mobile

Mobile app for the Fluxio IoT platform. It provides the same device management and telemetry workflows as the web dashboard, plus secure cookie storage and push notification support through Firebase Cloud Messaging.

## Features

- Email/password login backed by the Fluxio Firebase API
- Secure cookie persistence with `flutter_secure_storage`
- Device list with add, edit, and delete workflows
- Live MQTT telemetry and command publishing
- Analog and digital channel monitoring
- Visual logic builder for device automation
- Firmware upload flow
- Firebase Cloud Messaging token registration and local notifications

## Requirements

- Flutter SDK 3.8.1 or newer
- Android toolchain for mobile builds
- A running Fluxio backend
- A shared Fluxio API key configured in the backend as `PUBLIC_API_KEY`

## Configuration

The app reads the API key from a Dart define named `FLUXIO_API_KEY`.

Create a local define file from the example:

```bash
cp .env.json.example .env.json
```

Edit `.env.json` with the same key configured in the backend. This file is ignored by Git.

## Development

```bash
flutter pub get
flutter run --dart-define-from-file=.env.json
```

Run on a specific Android device:

```bash
flutter devices
flutter run -d <device-id> --dart-define-from-file=.env.json
```

## Build

```bash
flutter build apk --dart-define-from-file=.env.json
```

## Project Structure

- `lib/backend_api/` - HTTP session client for the Fluxio API
- `lib/mqtt/` - MQTT connection manager
- `lib/services/` - app state and notification services
- `lib/pages/first_screens/` - login, registration, and account recovery screens
- `lib/pages/main_screen/` - device list and account/device management
- `lib/pages/dashboard_screen/` - telemetry, command, channel, firmware, and logic views
- `lib/models/` - device, telemetry, user, and channel models
- `android/` - Android project files

## Security Notes

Do not hardcode API keys in Dart files. Keep local define files such as `.env.json` out of source control and rotate the shared key if it is exposed.
