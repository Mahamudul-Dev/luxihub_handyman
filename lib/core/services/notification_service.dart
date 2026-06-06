import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final _local = FlutterLocalNotificationsPlugin();

  static const _channelId = 'messages';
  static const _channelName = 'Messages';

  static Future<void> initialize() async {
    debugPrint('[FCM] initialize() called');

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'New message notifications',
          importance: Importance.high,
        ));

    debugPrint('[FCM] Notification channel created');
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

    final granted = settings.authorizationStatus ==
            AuthorizationStatus.authorized ||
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
      debugPrint('[FCM] getToken() returned null — is google-services.json present?');
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
        {'user_id': userId, 'token': token, 'platform': Platform.operatingSystem},
        onConflict: 'user_id,token',
      );
      debugPrint('[FCM] Token saved successfully');
    } catch (e) {
      debugPrint('[FCM] Token save error: $e');
    }
  }

  static void _onForeground(RemoteMessage message) {
    debugPrint('[FCM] Foreground message received: ${message.messageId}');
    debugPrint('[FCM]   title: ${message.notification?.title}');
    debugPrint('[FCM]   body:  ${message.notification?.body}');
    debugPrint('[FCM]   data:  ${message.data}');

    final n = message.notification;
    if (n == null) {
      debugPrint('[FCM] No notification payload — skipping local display');
      return;
    }
    _local.show(
      message.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'New message notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
