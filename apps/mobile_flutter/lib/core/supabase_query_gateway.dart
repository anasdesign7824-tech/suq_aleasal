import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:assalkom_data/assal_repository.dart';

class SupabaseQueryGateway implements ProductionQueryGateway {
  const SupabaseQueryGateway(this.client);
  final SupabaseClient client;

  @override
  Future<List<Map<String, Object?>>> select(String table, {Map<String, Object?> filters = const <String, Object?>{}}) async {
    var query = client.from(table).select();
    for (final entry in filters.entries) {
      query = query.eq(entry.key, entry.value);
    }
    final rows = await query;
    return rows.map((row) => Map<String, Object?>.from(row)).toList(growable: false);
  }

  @override
  Future<Map<String, Object?>> insert(String table, Map<String, Object?> values) async {
    final row = await client.from(table).insert(values).select().single();
    return Map<String, Object?>.from(row);
  }

  @override
  Future<Map<String, Object?>> update(String table, Map<String, Object?> values, {required String id}) async {
    final row = await client.from(table).update(values).eq('id', id).select().single();
    return Map<String, Object?>.from(row);
  }
}
