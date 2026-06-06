---
name: flutter-mobile-architecture
description: "Explains the Fluxio Flutter mobile architecture, app state, backend API client, Android MQTT flow, notification service, dashboard pages, and logic builder. Use when: tracing mobile behavior, adding screens, debugging MQTT/FCM, or changing client contracts."
---

# Flutter Mobile Architecture

## Module Map

| Area | File(s) | Responsibility |
|---|---|---|
| App bootstrap | `lib/main.dart` | Theme, persisted login check, initial route |
| Backend API | `lib/backend_api/api_communication.dart` | HTTP calls to Fluxio backend |
| App state | `lib/services/app_state.dart` | Logged-in user, selected devices, MQTT credentials/state |
| Notifications | `lib/services/notification.dart` | FCM token handling and local notifications |
| MQTT | `lib/mqtt/mqtt_manager.dart` | TLS MQTT connect, subscribe, publish, reconnect state |
| Models | `lib/models/` | User, device, telemetry, channel config models |
| Auth pages | `lib/pages/first_screens/` | Login, registration, password recovery |
| Main pages | `lib/pages/main_screen/` | Device list and user/device management |
| Dashboard | `lib/pages/dashboard_screen/` | Details, command page, channel editor, firmware upload, logic builder |
| Shared widgets | `lib/widgets/`, `lib/global/` | UI helpers and shared global utilities |

## Startup Flow

```
main()
  -> MyApp
  -> _init()
  -> appState.tryPersistLogin(context)
  -> logged in: CardsPage
  -> not logged in: LoginPage
```

## Device Data Flow

```
User action or dashboard load
  -> appState / page controller
  -> api_communication.dart
  -> Fluxio backend
  -> appState updated
  -> pages rebuild from current state
```

## MQTT Flow

```
Selected device
  -> backend returns MQTT credentials
  -> appState.mqtt stores credentials
  -> mqttManager.initializeMqtt()
  -> MqttServerClient.withPort(host, clientId, 8883)
  -> subscribe to telemetry/control topics
  -> dashboard callbacks update UI
  -> publish commands and logic payloads
```

## Notification Flow

```
Mobile app starts or user logs in
  -> notification service obtains FCM token
  -> backend /users/save-fcm-token stores token for devices
  -> ESP32/backend alert path calls /devices/send-notification
  -> FCM delivers push notification to mobile
```

## Adding a Screen or Workflow

1. Add or update models in `lib/models/` if the backend contract changes.
2. Add backend calls in `lib/backend_api/api_communication.dart`.
3. Store shared session/device state in `appState`.
4. Add the page under the matching `lib/pages/` area.
5. Wire MQTT subscriptions through `mqttManager` when live telemetry is needed.
6. Run `flutter analyze`.

## Do Not Change Without Understanding

- `mqttManager` is shared global state; always unsubscribe or clear subscriptions when leaving device contexts.
- Mobile MQTT uses `MqttServerClient`; web uses `MqttBrowserClient`.
- Logic builder payloads must remain compatible with ESP32 block execution.
- FCM token save depends on authenticated user context and selected device IDs.
