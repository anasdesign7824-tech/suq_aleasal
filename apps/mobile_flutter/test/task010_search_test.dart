import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom/features/customer/customer_discovery.dart';

import 'test_catalog.dart';

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
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 010 renders search controls and real demo results',
      (tester) async {
    await _pumpSearch(tester);

    expect(find.text('ابحث عن منتج أو متجر'), findsOneWidget);
    expect(find.text('الفلاتر'), findsOneWidget);
    expect(find.text('ترتيب'), findsOneWidget);
    expect(find.text('نتائج البحث'), findsOneWidget);
    final sortButton = find.ancestor(
      of: find.text('ترتيب'),
      matching: find.byType(OutlinedButton),
    );
    expect(sortButton, findsOneWidget);
    await tester.tap(sortButton);
    await tester.pumpAndSettle();
    expect(find.text('ترتيب النتائج'), findsAtLeastNWidgets(1));
    expect(find.text('الأكثر مشاهدة'), findsOneWidget);
    expect(find.text('الأحدث'), findsOneWidget);
    expect(find.text('الأعلى تقييمًا'), findsOneWidget);
    expect(
        find.text(
            'الفرز بالسعر أو الأقرب حسب المنطقة غير متاح من مصدر البيانات الحالي.'),
        findsOneWidget);

    await tester.tap(find.text('الأحدث'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'سدر');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('سدر يمني من وديانه'), findsOneWidget);
  });

  testWidgets(
      'TASK 010 opens the filter sheet and exposes source-backed fields',
      (tester) async {
    await _pumpSearch(tester);

    await tester.tap(find.text('الفلاتر'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('تصفية النتائج'), findsOneWidget);
    expect(find.text('المحافظة'), findsOneWidget);
    expect(find.text('المديرية'), findsOneWidget);
    expect(find.text('القسم'), findsOneWidget);
    expect(find.text('التصنيف الفرعي'), findsOneWidget);
    expect(find.text('نوع المنتج'), findsAtLeastNWidgets(1));

    expect(find.text('المتاجر الموثقة فقط'), findsOneWidget);
    expect(find.text('تطبيق الفلاتر'), findsOneWidget);

    await tester.ensureVisible(find.text('تطبيق الفلاتر'));
    await tester.tap(find.text('تطبيق الفلاتر'));
    await tester.pumpAndSettle();
    expect(find.text('تصفية النتائج'), findsNothing);
  });

  testWidgets('TASK 010 records the mobile search visual contract',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 2560);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpSearch(tester);
    await expectLater(
      find.byType(SearchScreen),
      matchesGoldenFile(
        'visual_reference/task010_search_reference_360x640.png',
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
