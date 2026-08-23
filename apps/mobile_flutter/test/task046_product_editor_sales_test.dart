import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom/features/merchant/merchant_product_editor.dart';
import 'test_catalog.dart';

Future<void> _pumpEditor(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MerchantProductEditorScreen(
        repository: buildTestDemoRepository(),
        storeId: 's1',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 046 يضع السعر والتوفر في تبويبهما الموحد', (tester) async {
    await _pumpEditor(tester);

    await tester.tap(find.text('البيع والتوصيل'));
    await tester.pumpAndSettle();

    expect(find.text('السعر'), findsOneWidget);
    expect(find.text('العملة'), findsOneWidget);
    expect(find.text('حالة التوفر'), findsOneWidget);
    expect(find.text('خيارات التوصيل — افصل بينها بفاصلة'), findsOneWidget);

    final salesScroll = find.byType(ListView).last;
    await tester.drag(salesScroll, const Offset(0, -520));
    await tester.pumpAndSettle();
    expect(find.text('نقاط الاستلام — افصل بينها بفاصلة'), findsOneWidget);
  });

  testWidgets('TASK 046 يمنع حفظ السعر غير الصالح', (tester) async {
    await _pumpEditor(tester);
    await tester.tap(find.text('البيع والتوصيل'));
    await tester.pumpAndSettle();

    final firstField = find.byType(TextFormField).first;
    await tester.enterText(firstField, 'سعر غير صالح');
    await tester.tap(find.text('حفظ المنتج ومعاينته'));
    await tester.pumpAndSettle();

    expect(find.text('اكتب سعرًا صحيحًا.'), findsOneWidget);
  });

  testWidgets('TASK 046 يعرض طريقة الحفظ والإلغاء دون فعل شكلي',
      (tester) async {
    await _pumpEditor(tester);
    expect(find.text('حفظ المنتج ومعاينته'), findsOneWidget);
    expect(find.text('إلغاء'), findsOneWidget);
  });

  testWidgets('TASK 046 records the visual contract', (tester) async {
    await _pumpEditor(tester);
    await tester.tap(find.text('البيع والتوصيل'));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MerchantProductEditorScreen),
      matchesGoldenFile(
        'visual_reference/task046_product_editor_sales_reference_360x780.png',
      ),
    );
  });
}
