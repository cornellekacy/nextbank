import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase shows the notification automatically from the payload.
  // No need to display a duplicate local notification.
}

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static String? _cachedToken;

  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _requestPermission();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    _initialized = true;

    _cachedToken = await _messaging.getToken();

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTapData);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationData(initialMessage.data);
    }
  }

  static Future<void> saveTokenAfterLogin() async {
    _cachedToken ??= await _messaging.getToken();
    if (_cachedToken != null) {
      await _saveToken(_cachedToken!);
    }
    _messaging.onTokenRefresh.listen(_saveToken);
  }

  static Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _saveToken(String token) async {
    try {
      await ApiService.saveDeviceToken(token);
    } catch (e) {
      debugPrint('FCM token save error: $e');
    }
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
      await _showLocalNotification(
        notification.title ?? '',
        notification.body ?? '',
        message.data,
      );
    }
  }

  static bool _initialized = false;

  static Future<void> showNotification(String title, String body, {Map<String, dynamic>? data}) async {
    if (!_initialized) {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      await _localNotifications.initialize(
        const InitializationSettings(android: androidSettings, iOS: iosSettings),
      );
      _initialized = true;
    }
    const androidDetails = AndroidNotificationDetails(
      'nextbank_channel',
      'NextBank Notifications',
      channelDescription: 'Banking notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: data?.toString(),
    );
  }

  static Future<void> _showLocalNotification(String title, String body, Map<String, dynamic> data) async {
    await showNotification(title, body, data: data);
  }

  static void _onNotificationTap(NotificationResponse response) {}

  static void _onNotificationTapData(RemoteMessage message) {
    _handleNotificationData(message.data);
  }

  static void _handleNotificationData(Map<String, dynamic> data) {}
}
