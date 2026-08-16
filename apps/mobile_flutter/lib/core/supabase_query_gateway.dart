import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:assalkom_data/assal_repository.dart';

class SupabaseQueryGateway implements ProductionQueryGateway {
  const SupabaseQueryGateway(this.client);
  static const requestTimeout = Duration(seconds: 12);
  final SupabaseClient client;

  @override
  Future<List<Map<String, Object?>>> select(String table, {Map<String, Object?> filters = const <String, Object?>{}}) async {
    final started = DateTime.now();
    developer.log('select_start table=$table filter_keys=${filters.keys.join(',')}', name: 'assalkom.network');
    try {
      var query = client.from(table).select();
      for (final entry in filters.entries) {
        final value = entry.value;
        if (value == null) continue;
        query = query.eq(entry.key, value);
      }
      final rows = await query.timeout(requestTimeout);
      final result = rows.map((row) => Map<String, Object?>.from(row)).toList(growable: false);
      developer.log('select_ok table=$table count=${result.length} elapsed_ms=${DateTime.now().difference(started).inMilliseconds}', name: 'assalkom.network');
      return result;
    } on Object catch (error, stackTrace) {
      developer.log('select_failed table=$table elapsed_ms=${DateTime.now().difference(started).inMilliseconds}', name: 'assalkom.network', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<Map<String, Object?>> insert(String table, Map<String, Object?> values) async {
    final started = DateTime.now();
    developer.log('insert_start table=$table value_keys=${values.keys.join(',')}', name: 'assalkom.network');
    try {
      final row = await client.from(table).insert(values).select().single().timeout(requestTimeout);
      developer.log('insert_ok table=$table elapsed_ms=${DateTime.now().difference(started).inMilliseconds}', name: 'assalkom.network');
      return Map<String, Object?>.from(row);
    } on Object catch (error, stackTrace) {
      developer.log('insert_failed table=$table', name: 'assalkom.network', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<Map<String, Object?>> update(String table, Map<String, Object?> values, {required String id}) async {
    final started = DateTime.now();
    developer.log('update_start table=$table value_keys=${values.keys.join(',')}', name: 'assalkom.network');
    try {
      final row = await client.from(table).update(values).eq('id', id).select().single().timeout(requestTimeout);
      developer.log('update_ok table=$table elapsed_ms=${DateTime.now().difference(started).inMilliseconds}', name: 'assalkom.network');
      return Map<String, Object?>.from(row);
    } on Object catch (error, stackTrace) {
      developer.log('update_failed table=$table', name: 'assalkom.network', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }
}
