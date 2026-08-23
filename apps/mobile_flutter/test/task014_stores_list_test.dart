import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom/features/customer/customer_discovery.dart';

import 'test_catalog.dart';

Future<void> _pumpStores(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: StoresScreen(repository: buildTestDemoRepository()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 014 renders source-backed store list controls',
      (tester) async {
    await _pumpStores(tester);

    expect(find.text('قائمة المتاجر'), findsNWidgets(2));
    expect(find.text('بحث المتجر أو المنطقة'), findsOneWidget);
    expect(find.text('متصل'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'تحديث'), findsOneWidget);
    expect(find.text('مناحل دوعن'), findsWidgets);
    expect(
      find.widgetWithText(OutlinedButton, 'عرض المتجر'),
      findsOneWidget,
    );
  });

  testWidgets('TASK 014 searches, filters, and refreshes source stores',
      (tester) async {
    await _pumpStores(tester);

    await tester.enterText(find.byType(TextField), 'دوعن');
    await tester.pump();
    expect(find.text('مناحل دوعن'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'غير موجود');
    await tester.pump();
    expect(find.text('لا توجد متاجر متاحة الآن.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.tap(find.widgetWithText(ActionChip, 'الفلاتر'));
    await tester.pumpAndSettle();
    expect(find.text('المتاجر الموثقة'), findsOneWidget);
    await tester.tap(find.text('المتاجر الموثقة'));
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(find.text('مناحل دوعن'), findsWidgets);

    await tester.tap(find.widgetWithText(TextButton, 'تحديث'));
    await tester.pumpAndSettle();
    expect(find.text('مناحل دوعن'), findsWidgets);
  });

  testWidgets('TASK 014 opens the real store profile from the list',
      (tester) async {
    await _pumpStores(tester);

    await tester.ensureVisible(
      find.widgetWithText(OutlinedButton, 'عرض المتجر'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'عرض المتجر'));
    await tester.pumpAndSettle();

    expect(find.text('مناحل دوعن'), findsWidgets);
    expect(find.text('المنتجات'), findsOneWidget);
    expect(find.text('معلومات المتجر'), findsOneWidget);
    expect(find.text('التواصل'), findsOneWidget);
  });

  testWidgets('TASK 014 records the stores visual contract', (tester) async {
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpStores(tester);
    await expectLater(
      find.byType(StoresScreen),
      matchesGoldenFile(
        'visual_reference/task014_stores_list_reference_360x780.png',
      ),
    );
  });
}
