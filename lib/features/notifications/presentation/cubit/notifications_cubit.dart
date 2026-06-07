import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:luxihub_handyman/features/notifications/domain/entities/notification_item.dart';

// ── State ────────────────────────────────────────────────────────────────────

class NotificationsState {
  final List<NotificationItem> notifications;
  final int unreadCount;
  final bool isLoading;

  const NotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
  });

  NotificationsState copyWith({
    List<NotificationItem>? notifications,
    int? unreadCount,
    bool? isLoading,
  }) =>
      NotificationsState(
        notifications: notifications ?? this.notifications,
        unreadCount: unreadCount ?? this.unreadCount,
        isLoading: isLoading ?? this.isLoading,
      );
}

// ── Cubit ────────────────────────────────────────────────────────────────────

class NotificationsCubit extends Cubit<NotificationsState> {
  final SupabaseClient _client;
  RealtimeChannel? _channel;
  String? _userId;

  NotificationsCubit(this._client) : super(const NotificationsState());

  Future<void> load(String userId) async {
    _userId = userId;
    emit(state.copyWith(isLoading: true));
    await _fetch();
    _subscribe(userId);
  }

  Future<void> refresh() async => _fetch();

  Future<void> markAllRead() async {
    if (_userId == null) return;
    try {
      await _client.from('notification_cursors').upsert({
        'user_id': _userId,
        'last_read_at': DateTime.now().toUtc().toIso8601String(),
      });
      final updated = state.notifications
          .map((n) => NotificationItem(
                id: n.id,
                title: n.title,
                body: n.body,
                type: n.type,
                targetType: n.targetType,
                data: n.data,
                createdAt: n.createdAt,
                isRead: true,
              ))
          .toList();
      emit(state.copyWith(notifications: updated, unreadCount: 0));
    } catch (e) {
      debugPrint('[Notifications] markAllRead error: $e');
    }
  }

  Future<void> _fetch() async {
    if (_userId == null) return;
    try {
      final cursorRes = await _client
          .from('notification_cursors')
          .select('last_read_at')
          .eq('user_id', _userId!)
          .maybeSingle();

      final lastReadAt = cursorRes != null
          ? DateTime.parse(cursorRes['last_read_at'] as String).toLocal()
          : DateTime(2020);

      final data = await _client
          .from('notifications')
          .select()
          .or('target_type.eq.all,and(target_type.eq.user,target_user_id.eq.$_userId)')
          .order('created_at', ascending: false)
          .limit(50);

      final items = (data as List)
          .map((e) => NotificationItem.fromJson(
              e as Map<String, dynamic>, lastReadAt))
          .toList();

      emit(state.copyWith(
        notifications: items,
        unreadCount: items.where((n) => !n.isRead).length,
        isLoading: false,
      ));
    } catch (e) {
      debugPrint('[Notifications] fetch error: $e');
      emit(state.copyWith(isLoading: false));
    }
  }

  void _subscribe(String userId) {
    _channel?.unsubscribe();
    _channel = _client
        .channel('notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (_) => _fetch(),
        )
        .subscribe();
  }

  @override
  Future<void> close() {
    _channel?.unsubscribe();
    return super.close();
  }
}
