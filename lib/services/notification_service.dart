import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
        const InitializationSettings(android: android),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'vizionai', 'VizionAI Studio',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  static void showSuccess() {
    try {
      _plugin.show(0, '✅ Vidéo prête !',
          'Ouvre VizionAI pour récupérer ton lien.', _details);
    } catch (_) {}
  }

  static void showError(String msg) {
    try {
      _plugin.show(1, '❌ Erreur', msg, _details);
    } catch (_) {}
  }
}
