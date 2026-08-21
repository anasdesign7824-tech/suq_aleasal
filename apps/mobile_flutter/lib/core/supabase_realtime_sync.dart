import 'dart:async';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

typedef AssalSyncChanged = void Function();

/// Keeps the active Flutter shell aware of production changes made by other
/// phones, traders, or the local admin console. The database remains the
/// source of truth; a change event only asks the UI to re-read its current
/// screen data.
class SupabaseRealtimeSync {
  SupabaseRealtimeSync(this.client);

  final SupabaseClient client;
  RealtimeChannel? _channel;
  StreamSubscription<AuthState>? _authSubscription;
  AssalSyncChanged? _onChanged;
  Timer? _notifyTimer;
  bool _started = false;

  void start(AssalSyncChanged onChanged) {
    _onChanged = onChanged;
    if (_started) {
      developer.log('realtime_start_ignored already_started=true', name: 'assalkom.realtime');
      return;
    }
    _started = true;
    developer.log('realtime_start', name: 'assalkom.realtime');
    _subscribe();
    _authSubscription = client.auth.onAuthStateChange.listen((_) {
      _subscribe();
    });
  }

  void _subscribe() {
    if (!_started) return;
    final oldChannel = _channel;
    if (oldChannel != null) {
      developer.log('realtime_remove_previous_channel', name: 'assalkom.realtime');
      unawaited(client.removeChannel(oldChannel));
    }

    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      _channel = null;
      developer.log('realtime_subscription_skipped authenticated=false', name: 'assalkom.realtime');
      return;
    }
    final channel = client.channel('assalkom-production-sync');
    final tables = <String>[
      'conversations',
      'conversation_participants',
      'messages',
      'requests',
      'request_messages',
      'notifications',
      'store_followers',
      'product_likes',
      'favorites',
      'reviews',
      'comments',
    ];

    for (final table in tables) {
      final filter = _userFilter(table, userId);
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        filter: filter,
        callback: (_) => _scheduleNotify(),
      );
    }

    _channel = channel;
    developer.log('realtime_subscribe_requested tables=${tables.length} user_scoped=true', name: 'assalkom.realtime');
    channel.subscribe();
  }

  void _scheduleNotify() {
    if (_notifyTimer?.isActive ?? false) {
      developer.log('realtime_event_coalesced debounce_ms=180', name: 'assalkom.realtime');
      return;
    }
    developer.log('realtime_event_scheduled debounce_ms=180', name: 'assalkom.realtime');
    _notifyTimer = Timer(const Duration(milliseconds: 180), () {
      _notifyTimer = null;
      _onChanged?.call();
    });
  }

  PostgresChangeFilter? _userFilter(String table, String? userId) {
    if (userId == null) return null;
    final column = switch (table) {
      'reviews' || 'comments' => 'author_id',
      'requests' => 'requester_id',
      'request_messages' => 'sender_id',
      _ => 'user_id',
    };
    return switch (table) {
      'notifications' || 'store_followers' || 'product_likes' || 'favorites' ||
      'reviews' || 'comments' || 'conversation_participants' || 'requests' ||
      'request_messages' => PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: column,
          value: userId,
        ),
      _ => null,
    };
  }

  Future<void> dispose() async {
    _started = false;
    _notifyTimer?.cancel();
    _notifyTimer = null;
    await _authSubscription?.cancel();
    _authSubscription = null;
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      await client.removeChannel(channel);
      developer.log('realtime_disposed channel_removed=true', name: 'assalkom.realtime');
    } else {
      developer.log('realtime_disposed channel_removed=false', name: 'assalkom.realtime');
    }
    _onChanged = null;
  }
}
