import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_data/production_repository.dart';

void main() {
  test('customer read models preserve projected fields and canonical view names', () async {
    final gateway = _ReadModelsGateway();
    final repository = ProductionRepository(gateway: gateway);

    final products = await repository.listProducts();
    final favorites = await repository.listFavoriteProducts('u1');
    final followed = await repository.listFollowedStores('u1');
    final stores = await repository.listStores();
    final comments = await repository.listComments('p1');
    final conversations = await repository.listConversations('u1');

    final product = (products as AssalData<List<AssalProductSummary>>).value.single;
    expect(product.components, ['عسل سدر', 'شمع نحل']);
    expect(product.gradeLevels, [4, 5]);
    expect(product.gradeLabels, ['ممتاز', 'فاخر']);
    expect(product.shelfLifeLabelAr, '24 شهرًا');
    expect(product.productionDate, DateTime(2026, 1, 2));
    expect(product.packagedDate, DateTime(2026, 1, 3));

    final favorite = (favorites as AssalData<List<AssalProductSummary>>).value.single;
    expect(favorite.components, ['عسل سدر']);
    expect((followed as AssalData<List<AssalStoreSummary>>).value.single.nameAr, 'متجر متابَع');
    expect((stores as AssalData<List<AssalStoreSummary>>).value.single.galleryUrls, ['gallery.png']);
    expect((comments as AssalData<List<AssalCommentSummary>>).value.single.authorName, 'مستخدم');
    expect((conversations as AssalData<List<AssalConversationSummary>>).value.single.participantIds, ['u1', 'm1']);

    expect(
      gateway.selectedTables,
      containsAll(<String>[
        'customer_products',
        'customer_favorite_products',
        'customer_followed_stores',
        'customer_stores',
        'customer_comments',
        'customer_conversations',
      ]),
    );
  });
}

class _ReadModelsGateway implements ProductionQueryGateway {
  final List<String> selectedTables = <String>[];

  @override
  Future<List<Map<String, Object?>>> select(
    String table, {
    Map<String, Object?> filters = const <String, Object?>{},
  }) async {
    selectedTables.add(table);
    return switch (table) {
      'customer_products' => <Map<String, Object?>>[
          {
            'id': 'p1',
            'store_id': 's1',
            'name_ar': 'عسل غني بالبيانات',
            'product_type': 'honey',
            'status': 'active',
            'grade_level': 4,
            'grade_levels': [4, 5],
            'grade_labels': ['ممتاز', 'فاخر'],
            'components': ['عسل سدر', 'شمع نحل'],
            'shelf_life_label_ar': '24 شهرًا',
            'production_date': '2026-01-02',
            'packaged_date': '2026-01-03',
          },
        ],
      'customer_favorite_products' => <Map<String, Object?>>[
          {
            'user_id': 'u1',
            'id': 'p1',
            'store_id': 's1',
            'name_ar': 'عسل محفوظ',
            'product_type': 'honey',
            'status': 'active',
            'components': ['عسل سدر'],
          },
        ],
      'customer_followed_stores' => <Map<String, Object?>>[
          {
            'user_id': 'u1',
            'id': 's1',
            'merchant_id': 'm1',
            'name_ar': 'متجر متابَع',
            'slug': 'followed',
            'status': 'active',
          },
        ],
      'customer_stores' => <Map<String, Object?>>[
          {
            'id': 's1',
            'merchant_id': 'm1',
            'name_ar': 'متجر السدر',
            'slug': 'sidr',
            'status': 'active',
            'gallery_urls': ['gallery.png'],
          },
        ],
      'customer_comments' => <Map<String, Object?>>[
          {
            'id': 'c1',
            'author_id': 'u1',
            'target_id': 'p1',
            'body': 'تعليق معتمد',
            'status': 'approved',
            'author_name': 'مستخدم',
          },
        ],
      'customer_conversations' => <Map<String, Object?>>[
          {
            'user_id': 'u1',
            'id': 'conversation-1',
            'store_id': 's1',
            'store_name': 'متجر السدر',
            'last_message': 'مرحبًا',
            'updated_at': '2026-08-21T10:00:00Z',
            'created_at': '2026-08-21T09:00:00Z',
            'participant_ids': ['u1', 'm1'],
          },
        ],
      _ => <Map<String, Object?>>[],
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
