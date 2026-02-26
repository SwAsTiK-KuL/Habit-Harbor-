import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // ADD missing import

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'habit_reminders',
      'Habit Reminders',
      description: 'Daily reminders to log your habit progress',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          // FIX: was missing
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    const InitializationSettings initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(initSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'habit_reminders',
              'Habit Reminders',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    print('✅ NotificationService initialized');
  }

  Future<String?> getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      print('📱 FCM Token: $token');
      return token;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  void onTokenRefresh(Function(String) callback) {
    _firebaseMessaging.onTokenRefresh.listen(callback);
  }

  void onNotificationTap(Function(String screen) onTap) {
    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        final screen = message.data['screen'] ?? 'home';
        onTap(screen);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final screen = message.data['screen'] ?? 'home';
      onTap(screen);
    });
  }
}
