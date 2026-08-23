import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom/features/customer/customer_discovery.dart';

import 'test_catalog.dart';

void main() {
  testWidgets('search filter button opens sheet and applies verified filter',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchScreen(
          repository: buildTestDemoRepository(),
          locationBundle: _LocationAssetBundle(_locationFixture),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('الفلاتر'), findsOneWidget, reason: 'filter button must be visible before tap');
    await tester.tap(find.text('الفلاتر'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('تصفية النتائج'), findsOneWidget, reason: 'filter sheet must open after tap');
    expect(find.text('المحافظة'), findsOneWidget);
    expect(find.text('المديرية'), findsOneWidget);
    expect(find.text('المتاجر الموثقة فقط'), findsOneWidget);
    expect(find.text('تطبيق الفلاتر'), findsOneWidget);

    await tester.ensureVisible(find.text('المتاجر الموثقة فقط'));
    await tester.tap(find.text('المتاجر الموثقة فقط'));
    await tester.pump();
    await tester.ensureVisible(find.text('تطبيق الفلاتر'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تطبيق الفلاتر'));
    await tester.pumpAndSettle();

    expect(find.text('الفلاتر (1)'), findsOneWidget, reason: 'applied filter count must be visible');
    expect(find.text('متاجر موثقة'), findsOneWidget, reason: 'verified chip must be visible');
    expect(find.text('سدر يمني من وديانه'), findsOneWidget, reason: 'verified product must remain in result');
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
