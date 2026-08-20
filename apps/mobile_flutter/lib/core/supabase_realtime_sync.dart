import 'dart:async';

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
    if (_started) return;
    _started = true;
    _subscribe();
    _authSubscription = client.auth.onAuthStateChange.listen((_) {
      _subscribe();
    });
  }

  void _subscribe() {
    final oldChannel = _channel;
    if (oldChannel != null) {
      unawaited(client.removeChannel(oldChannel));
    }

    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      _channel = null;
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
    channel.subscribe();
  }

  void _scheduleNotify() {
    if (_notifyTimer?.isActive ?? false) return;
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
    if (channel != null) await client.removeChannel(channel);
    _onChanged = null;
  }
}
