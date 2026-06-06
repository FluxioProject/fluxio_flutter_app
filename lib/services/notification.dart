import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:tcc_flutter_mobile/backend_api/api_communication.dart';
import 'package:tcc_flutter_mobile/global/global_variables.dart';
import 'package:tcc_flutter_mobile/models/device.dart';
import 'package:tcc_flutter_mobile/mqtt/mqtt_manager.dart';
import 'package:tcc_flutter_mobile/pages/dashboard_screen/device_details_page.dart';

class FirebaseApi {
  final firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications(BuildContext context) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          defaultPresentAlert: false,
          defaultPresentBadge: false,
          defaultPresentBanner: false,
          defaultPresentSound: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          _handleNotificationClick(jsonDecode(response.payload!));
        }
      },
    );

    // Configura o listener para quando o app está em primeiro plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (defaultTargetPlatform != TargetPlatform.iOS) {
        _showNotification(
          message.notification?.title,
          message.notification?.body,
          message.data,
        );
      }
    });

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Configura o listener para quando o app está em segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message.data);
    });

    // Verificar se o app foi aberto a partir de uma notificação
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage.data);
    }
  }

  // Função para tratar o clique na notificação
  void _handleNotificationClick(Map<String, dynamic> payload) async {
    if (payload.isEmpty) return;

    try {
      await mqttManager.connect(navigatorKey.currentContext!);
    } catch (_) {
      return;
    }

    final deviceId = payload['deviceid'] as String;

    final device = Device(name: 'Carregando...', deviceId: deviceId);

    if (device.deviceId.isEmpty) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text(
            'vazio: ${payload['deviceid']} + ${device.toString()}',
          ),
        ),
      );
      return;
    }
    await navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => DeviceDetailsPage(device: device)),
    );
  }

  // Função para exibir notificação
  Future<void> _showNotification(
    String? title,
    String? body,
    Map<String, dynamic> data,
  ) async {
    // final processedBody = _processNotificationText(body);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if ((title?.isNotEmpty ?? false) || (body?.isNotEmpty ?? false))
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
        payload: jsonEncode(data),
      );
  }
}

Future<void> sendTokenToServer(String token, List<String> deviceIds) async {
  try {
    await Session().post('users/save-fcm-token', {
      'deviceids': deviceIds,
      'fcmtoken': token,
    });
  } catch (e) {}
}

Future<void> getFCMToken(List<String> deviceIds, BuildContext context) async {
  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Impede que feche ao tocar fora
      builder: (context) {
        return AlertDialog(
          title: Text('Permissão de Notificações', textAlign: TextAlign.center),
          content: Text(
            softWrap: true,
            overflow: TextOverflow.visible,
            style: TextStyle(fontSize: 14),
            'Para receber notificações, é necessário conceder permissão. Vá até as configurações do aplicativo e habilite a permissão.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              },
              child: Text(
                'Ir para configurações',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }

  try {
    final response = await Session().get('users/x3r9m2');
    final data = json.decode(response);

    // Decodificar base64 para cada campo antes de usar
    final apiKey = utf8.decode(base64Decode(data['x4r1']));
    final appIdRaw = utf8.decode(base64Decode(data['x4r2']));
    final messagingSenderId = utf8.decode(base64Decode(data['x4r3']));
    final projectId = utf8.decode(base64Decode(data['x4r4']));
    final storageBucket = utf8.decode(base64Decode(data['x4r5']));
    final databaseURL = utf8.decode(base64Decode(data['x4r6']));

    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: apiKey,
        appId: defaultTargetPlatform == TargetPlatform.iOS
            ? appIdRaw.replaceAll(':web:', ':ios:')
            : appIdRaw,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket,
        databaseURL: databaseURL,
      ),
    );
  } catch (e) {
    // showMessage(context, e.toString(), true);
    print('Erro ao inicializar Firebase: $e');
    return;
  }

  FirebaseApi firebaseApi = FirebaseApi();
  NotificationSettings settings = await firebaseApi.firebaseMessaging
      .requestPermission(alert: true, badge: true, sound: true);

  if (settings.authorizationStatus != AuthorizationStatus.authorized) {
    _showPermissionDeniedDialog(context);
    return;
  }

  token = await FirebaseMessaging.instance.getToken();

  // verificar se salva algo no shared preferences pra nao ficar enviando
  // o token toda vez
  if (token != null) {
    await sendTokenToServer(token!, deviceIds);
  }

  firebaseApi.initNotifications(context);
}
