import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showSuccess(String? url) async {
    await _plugin.show(
      0,
      '✅ VizionAI — Vidéo prête !',
      'Ta vidéo est générée. Ouvre l\'app pour récupérer le lien.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'vizionai',
          'VizionAI',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  static Future<void> showError(String msg) async {
    await _plugin.show(
      1,
      '❌ VizionAI — Erreur',
      msg,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'vizionai',
          'VizionAI',
          importance: Importance.defaultImportance,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
