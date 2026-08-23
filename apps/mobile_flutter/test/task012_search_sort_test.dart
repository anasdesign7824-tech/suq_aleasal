import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom/features/customer/customer_discovery.dart';

import 'test_catalog.dart';

Future<void> _pumpSearch(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: SearchScreen(
          repository: buildTestDemoRepository(),
          locationBundle: _LocationAssetBundle(_locationFixture),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openSortSheet(WidgetTester tester) async {
  await tester.tap(find.ancestor(
    of: find.text('ترتيب'),
    matching: find.byType(OutlinedButton),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 012 renders source-backed sort options', (tester) async {
    await _pumpSearch(tester);
    await _openSortSheet(tester);

    expect(find.text('ترتيب النتائج'), findsAtLeastNWidgets(1));
    expect(find.text('اختر طريقة عرض المنتجات'), findsOneWidget);
    expect(find.text('الأكثر مشاهدة'), findsOneWidget);
    expect(find.text('الأحدث'), findsOneWidget);
    expect(find.text('الأعلى تقييمًا'), findsOneWidget);
    expect(
      find.text(
          'الفرز بالسعر أو الأقرب حسب المنطقة غير متاح من مصدر البيانات الحالي.'),
      findsOneWidget,
    );
    expect(find.text('تطبيق'), findsOneWidget);
    expect(find.byTooltip('إغلاق'), findsOneWidget);
  });

  testWidgets('TASK 012 applies newest sort through AssalSort', (tester) async {
    await _pumpSearch(tester);
    await _openSortSheet(tester);

    await tester.tap(find.text('الأحدث'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    expect(find.text('ترتيب: الأحدث'), findsOneWidget);
    expect(find.text('سدر يمني من وديانه'), findsOneWidget);
  });

  testWidgets('TASK 012 closes without changing the active sort',
      (tester) async {
    await _pumpSearch(tester);
    await _openSortSheet(tester);
    await tester.tap(find.byTooltip('إغلاق'));
    await tester.pumpAndSettle();

    expect(find.text('ترتيب'), findsOneWidget);
    expect(find.text('ترتيب: الأحدث'), findsNothing);
  });

  testWidgets('TASK 012 records the sort sheet visual contract',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpSearch(tester);
    await _openSortSheet(tester);

    await expectLater(
      find.byType(SearchScreen),
      matchesGoldenFile(
        'visual_reference/task012_search_sort_reference_360x780.png',
      ),
    );
  });
}

class _LocationAssetBundle extends CachingAssetBundle {
  _LocationAssetBundle(this.content);

  final String content;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.view(Uint8List.fromList(utf8.encode(content)).buffer);
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
