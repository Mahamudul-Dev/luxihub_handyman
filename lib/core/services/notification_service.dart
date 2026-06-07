import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final _local = FlutterLocalNotificationsPlugin();

  // Each notification type gets its own Android channel so users can
  // control them independently in system settings.
  static const _channels = {
    'messages': ('messages', 'Messages', 'Chat message notifications'),
    'job_request': ('job_requests', 'Job Requests', 'New job request alerts'),
    'job_update': ('job_requests', 'Job Requests', 'Job status updates'),
    'payment': ('payments', 'Payments', 'Withdrawal and payment notifications'),
    'system': ('general', 'General', 'System and admin notifications'),
    'general': ('general', 'General', 'General notifications'),
  };

  // Broadcast stream — listen to trigger a cubit refresh on foreground FCM.
  static final _foregroundController =
      StreamController<RemoteMessage>.broadcast();
  static Stream<RemoteMessage> get foregroundMessages =>
      _foregroundController.stream;

  static Future<void> initialize() async {
    debugPrint('[FCM] initialize() called');

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // Create all channels up front.
    final created = <String>{};
    for (final entry in _channels.values) {
      final id = entry.$1;
      if (created.add(id)) {
        await androidPlugin?.createNotificationChannel(
          AndroidNotificationChannel(
            id,
            entry.$2,
            description: entry.$3,
            importance: Importance.high,
          ),
        );
      }
    }

    debugPrint('[FCM] Notification channels created');
    FirebaseMessaging.onMessage.listen(_onForeground);
  }

  static Future<void> requestAndSave(
      SupabaseClient supabase, String userId) async {
    debugPrint('[FCM] requestAndSave() — userId: $userId');

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!granted) {
      debugPrint('[FCM] Permission NOT granted — aborting token save');
      return;
    }

    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('[FCM] Device token: $token');

    if (token != null) {
      await _save(supabase, userId, token);
    } else {
      debugPrint(
          '[FCM] getToken() returned null — is google-services.json present?');
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((t) {
      debugPrint('[FCM] Token refreshed: $t');
      _save(supabase, userId, t);
    });
  }

  static Future<void> _save(
      SupabaseClient supabase, String userId, String token) async {
    debugPrint('[FCM] Saving token to device_tokens for userId: $userId');
    try {
      await supabase.from('device_tokens').upsert(
        {
          'user_id': userId,
          'token': token,
          'platform': defaultTargetPlatform.name.toLowerCase(),
        },
        onConflict: 'user_id,token',
      );
      debugPrint('[FCM] Token saved successfully');
    } catch (e) {
      debugPrint('[FCM] Token save error: $e');
    }
  }

  static void _onForeground(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.messageId}');
    debugPrint('[FCM]   title: ${message.notification?.title}');
    debugPrint('[FCM]   body:  ${message.notification?.body}');
    debugPrint('[FCM]   data:  ${message.data}');

    // Notify listeners (NotificationsCubit refreshes its count).
    _foregroundController.add(message);

    final n = message.notification;
    if (n == null) return;

    final type = message.data['type'] as String? ?? 'general';
    final channel = _channels[type] ?? _channels['general']!;

    _local.show(
      message.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.$1,
          channel.$2,
          channelDescription: channel.$3,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
