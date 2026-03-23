import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showMessageNotification({
    required String senderName,
    required String message,
    required String senderId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'nexchat_messages',
      'NexChat Messages',
      channelDescription: 'NexChat notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: senderName,
      body: message,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: senderId,
    );
  }
}
