import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom/features/customer/customer_discovery.dart';

import 'test_catalog.dart';

Future<void> _pumpSearchFilters(WidgetTester tester) async {
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

void main() {
  testWidgets('TASK 011 renders the structured filter sheet', (tester) async {
    await _pumpSearchFilters(tester);

    await tester.tap(find.text('الفلاتر'));
    await tester.pumpAndSettle();

    expect(find.text('الفلاتر'), findsAtLeastNWidgets(1));
    expect(find.text('تصفية النتائج'), findsOneWidget);
    expect(find.text('الموقع'), findsOneWidget);
    expect(find.text('المحافظة'), findsOneWidget);
    expect(find.text('المديرية'), findsOneWidget);
    expect(find.text('السعر'), findsOneWidget);
    expect(find.text('عملة السعر'), findsOneWidget);
    expect(find.text('نوع المنتج'), findsAtLeastNWidgets(1));
    expect(find.text('التصنيف'), findsOneWidget);
    expect(find.text('التصنيف الفرعي'), findsOneWidget);
    expect(find.text('الجودة'), findsOneWidget);
    expect(find.text('الوزن أو الحجم'), findsAtLeastNWidgets(1));
    expect(find.text('حالة التوفر'), findsOneWidget);
    expect(find.text('التوفر'), findsOneWidget);
    expect(find.text('المتجر'), findsAtLeastNWidgets(1));
    expect(find.text('إلغاء'), findsOneWidget);
    expect(find.text('مسح الكل'), findsOneWidget);
    expect(find.text('تطبيق الفلاتر'), findsOneWidget);
    expect(find.byTooltip('إغلاق'), findsOneWidget);
  });

  testWidgets('TASK 011 applies a source-backed store filter and closes',
      (tester) async {
    await _pumpSearchFilters(tester);

    await tester.tap(find.text('الفلاتر'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('كل المتاجر'));
    await tester.tap(find.text('كل المتاجر'));
    await tester.pumpAndSettle();
    expect(find.text('مناحل دوعن'), findsOneWidget);
    await tester.tap(find.text('مناحل دوعن'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('تطبيق الفلاتر'));
    await tester.tap(find.text('تطبيق الفلاتر'));
    await tester.pumpAndSettle();

    expect(find.text('تصفية النتائج'), findsNothing);
    expect(find.text('الفلاتر (1)'), findsOneWidget);
    expect(find.text('المتجر المحدد'), findsOneWidget);
  });

  testWidgets('TASK 011 dismisses without applying changes', (tester) async {
    await _pumpSearchFilters(tester);

    await tester.tap(find.text('الفلاتر'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('إغلاق'));
    await tester.pumpAndSettle();

    expect(find.text('تصفية النتائج'), findsNothing);
    expect(find.text('الفلاتر (1)'), findsNothing);
  });

  testWidgets('TASK 011 records the filter sheet visual contract',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 2560);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpSearchFilters(tester);
    await tester.tap(find.text('الفلاتر'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(SearchScreen),
      matchesGoldenFile(
        'visual_reference/task011_search_filters_reference_360x640.png',
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
