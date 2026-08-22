import 'dart:typed_data';

import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_data/demo_repository.dart';
import 'package:assalkom_data/production_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ProductionRepository reads per-user product interaction state', () async {
    final repository = ProductionRepository(gateway: _InteractionGateway());

    final result = await repository.loadProductInteractionState('u1', 'p1');

    expect(result, isA<AssalData<AssalProductInteractionState>>());
    final state = (result as AssalData<AssalProductInteractionState>).value;
    expect(state.isLiked, isTrue);
    expect(state.isFavorited, isFalse);
  });

  test('ProductionRepository parses privacy-safe follower page', () async {
    final repository = ProductionRepository(gateway: _InteractionGateway());

    final result = await repository.listStoreFollowers('s1');

    expect(result, isA<AssalData<AssalStoreFollowersPage>>());
    final page = (result as AssalData<AssalStoreFollowersPage>).value;
    expect(page.total, 1);
    expect(page.items.single.displayName, 'عميل عام');
    expect(page.items.single.avatarUrl, 'https://example.com/avatar.png');
  });

  test('DemoRepository keeps interaction state after local toggle', () async {
    const catalog = '{"stores": [], "products": []}';
    final repository = DemoRepository(
      loader: const InMemoryDemoCatalogLoader(catalog),
    );

    final before = await repository.loadProductInteractionState('u1', 'p1');
    expect((before as AssalData<AssalProductInteractionState>).value.isLiked,
        isFalse);

    final toggled = await repository.toggleLike('u1', 'p1');
    expect((toggled as AssalData<bool>).value, isTrue);

    final after = await repository.loadProductInteractionState('u1', 'p1');
    expect((after as AssalData<AssalProductInteractionState>).value.isLiked,
        isTrue);
  });
}

class _InteractionGateway implements ProductionQueryGateway {
  @override
  Future<List<Map<String, Object?>>> select(
    String table, {
    Map<String, Object?> filters = const <String, Object?>{},
  }) async {
    if (table == 'product_likes') {
      return filters['user_id'] == 'u1' && filters['product_id'] == 'p1'
          ? <Map<String, Object?>>[
              <String, Object?>{'user_id': 'u1', 'product_id': 'p1'},
            ]
          : const <Map<String, Object?>>[];
    }
    if (table == 'favorites') return const <Map<String, Object?>>[];
    throw StateError('unexpected select: $table');
  }

  @override
  Future<Map<String, Object?>> rpc(
    String function,
    Map<String, Object?> params,
  ) async {
    expect(function, 'customer_list_store_followers');
    expect(params['p_store_id'], 's1');
    return <String, Object?>{
      'items': <Map<String, Object?>>[
        <String, Object?>{
          'display_name': 'عميل عام',
          'avatar_url': 'https://example.com/avatar.png',
          'followed_at': '2026-08-22T10:00:00Z',
        },
      ],
      'total': 1,
      'limit': 50,
      'offset': 0,
    };
  }

  @override
  Future<Map<String, Object?>> insert(
    String table,
    Map<String, Object?> values,
  ) => throw UnimplementedError();

  @override
  Future<Map<String, Object?>> update(
    String table,
    Map<String, Object?> values, {
    required String id,
  }) => throw UnimplementedError();

  @override
  Future<void> delete(
    String table, {
    Map<String, Object?> filters = const <String, Object?>{},
  }) => throw UnimplementedError();

  @override
  Future<Map<String, Object?>> upsert(
    String table,
    Map<String, Object?> values, {
    String? onConflict,
  }) => throw UnimplementedError();

  @override
  Future<String> uploadPublicImage(
    String path,
    Uint8List bytes,
    String extension,
  ) => throw UnimplementedError();

  @override
  Future<String> uploadPrivateImage(
    String path,
    Uint8List bytes,
    String extension,
  ) => throw UnimplementedError();
}
