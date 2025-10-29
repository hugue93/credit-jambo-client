import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static bool _initialized = false;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance',
    'High Importance Notifications',
    description: 'Used for important notifications like login and transactions',
    importance: Importance.max,
  );

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      // For mobile, default options from native files are used.
      // For web, users should configure FirebaseOptions via index.html or a web config.
      await Firebase.initializeApp();
      if (!kIsWeb) {
        const initSettingsAndroid = AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        );
        const initSettings = InitializationSettings(
          android: initSettingsAndroid,
        );
        await _local.initialize(initSettings);
        await _local
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(_channel);
      }
      _initialized = true;
    } catch (_) {
      // Ignore init errors in dev if not configured
    }
  }

  static Future<String?> getFcmToken() async {
    await _ensureInitialized();
    try {
      final messaging = FirebaseMessaging.instance;
      if (kIsWeb) {
        // Web requires permission; pass VAPID key for token retrieval
        await NotificationService.requestPermission();
        final vapidKey = const String.fromEnvironment(
          'BLoS0RALMyEZ0CDq40Kme2QG6UVHdkyX9Jy5hqwA0GivRx0z0Rr4D6g-o_01vyIITwEs2eRt9IxLpXLtjyI03OI',
          defaultValue: '',
        );
        final token = await messaging.getToken(
          vapidKey: vapidKey.isEmpty ? null : vapidKey,
        );
        return token;
      }
      final token = await messaging.getToken();
      return token;
    } catch (_) {
      return null;
    }
  }

  static Future<void> requestPermission() async {
    try {
      await _ensureInitialized();
      await FirebaseMessaging.instance.requestPermission();
      // On Android 13+, request runtime notifications permission
      if (!kIsWeb) {
        try {
          final status = await ph.Permission.notification.status;
          if (!status.isGranted) {
            await ph.Permission.notification.request();
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  static Future<void> showLocal(RemoteMessage message) async {
    if (kIsWeb) return; // web shows browser notifications via other path
    final notif = message.notification;
    final title = notif?.title ?? 'Notification';
    final body = notif?.body ?? '';
    await _local.show(
      message.messageId.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: message.data['type'] ?? '',
    );
  }
}
