import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_discovery.dart';

void main() {
  testWidgets(
    'search location filter preserves governorate and district query ids',
    (tester) async {
      final repository = _RecordingLocationRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: SearchScreen(
            repository: repository,
            locationBundle: _LocationAssetBundle(_locationFixture),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('الفلاتر'));
      await tester.pumpAndSettle();

      expect(find.text('تصفية النتائج'), findsOneWidget,
          reason: 'location reference must allow the filter sheet to build');
      expect(find.text('كل المحافظات'), findsOneWidget);
      expect(find.text('كل المديريات'), findsOneWidget);

      await tester.tap(find.text('كل المحافظات'));
      await tester.pumpAndSettle();
      expect(find.text('أمانة العاصمة'), findsOneWidget);
      await tester.tap(find.text('أمانة العاصمة'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('كل المديريات'));
      await tester.pumpAndSettle();
      expect(find.text('صنعاء القديمة'), findsOneWidget);
      await tester.tap(find.text('صنعاء القديمة'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('تطبيق الفلاتر'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تطبيق الفلاتر'));
      await tester.pumpAndSettle();

      expect(repository.queries.last.regionId, 'YE-GOV-001');
      expect(repository.queries.last.provinceId, 'YE-DST-001-001');
    },
  );
}

class _LocationAssetBundle extends CachingAssetBundle {
  _LocationAssetBundle(this.content);

  final String content;

  @override
  Future<ByteData> load(String key) async {
    final bytes = Uint8List.fromList(utf8.encode(content));
    return ByteData.view(bytes.buffer);
  }
}

const _locationFixture = '''
{
  "schema": "assalkom.yemen_governorates_districts.v1",
  "provenance": {"source_sha256": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"},
  "counts": {"governorates": 1, "districts": 1},
  "governorates": [
    {"code": "YE-GOV-001", "name_ar": "أمانة العاصمة", "districts": [
      {"code": "YE-DST-001-001", "name_ar": "صنعاء القديمة"}
    ]}
  ]
}
''';

class _RecordingLocationRepository implements AssalRepository {
  final List<AssalProductQuery> queries = <AssalProductQuery>[];

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({
    AssalProductQuery query = const AssalProductQuery(),
  }) async {
    queries.add(query);
    return const AssalEmpty<List<AssalProductSummary>>('لا توجد منتجات');
  }

  @override
  Future<AssalLoadState<List<AssalCategorySummary>>> listCategories() async =>
      const AssalEmpty<List<AssalCategorySummary>>('لا توجد أقسام');

  @override
  Future<AssalLoadState<List<AssalTaxonomy>>> listTaxonomy() async =>
      const AssalEmpty<List<AssalTaxonomy>>('لا توجد تصنيفات');

  @override
  Future<AssalLoadState<List<AssalStoreSummary>>> listStores({
    String? regionId,
  }) async =>
      const AssalEmpty<List<AssalStoreSummary>>('لا توجد متاجر');

  @override
  Future<AssalLoadState<List<String>>> listPopularSearches() async =>
      const AssalEmpty<List<String>>('لا توجد اقتراحات');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
