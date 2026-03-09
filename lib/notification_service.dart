import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer' as dev;

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Pede permissão
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // 2. Configurações Iniciais
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        dev.log("Notificação clicada!");
      },
    );

    // 3. Ouvir mensagens em primeiro plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
  }

  // --- O MÉTODO QUE ESTAVA FALTANDO ESTÁ AQUI ABAIXO ---
  void showTestNotification() {
    const androidDetails = AndroidNotificationDetails(
      'stride_channel',
      'Notificações Stride',
      channelDescription: 'Canal de testes do Gabriel',
      importance: Importance.max,
      priority: Priority.high,
    );

    _localNotifications.show(
      id: 99,
      title: "Saza-chan avisando! 📢",
      body: "O sistema de notificações está ativo e operante!",
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }

  void _showLocalNotification(RemoteMessage message) {
    const androidDetails = AndroidNotificationDetails(
      'stride_channel',
      'Notificações Stride',
      channelDescription: 'Alertas de compras e metas',
      importance: Importance.max,
      priority: Priority.high,
    );

    _localNotifications.show(
      id: 0,
      title: message.notification?.title ?? "Stride Shopping",
      body: message.notification?.body ?? "Novidade na sua lista!",
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }

  Future<String?> getToken() async => await _fcm.getToken();
}
