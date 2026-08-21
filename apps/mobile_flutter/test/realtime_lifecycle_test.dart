import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:assalkom/core/supabase_realtime_sync.dart';

void main() {
  test('RealtimeSync start is idempotent and dispose is safe without auth', () async {
    final client = SupabaseClient('https://example.supabase.co', 'test-anon-key');
    final sync = SupabaseRealtimeSync(client);
    var changeCallbacks = 0;

    sync.start(() => changeCallbacks++);
    sync.start(() => changeCallbacks++);
    await sync.dispose();

    expect(changeCallbacks, 0);
  });
}
