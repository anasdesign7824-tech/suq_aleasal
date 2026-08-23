import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom/features/customer/customer_discovery.dart';

import 'test_catalog.dart';

Future<void> _pumpCategories(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: CategoriesScreen(repository: buildTestDemoRepository()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 013 renders source-backed category controls',
      (tester) async {
    await _pumpCategories(tester);

    expect(find.text('التصنيفات والأنواع'), findsOneWidget);
    expect(find.text('البحث في التصنيفات'), findsOneWidget);
    expect(find.text('التصنيفات'), findsOneWidget);
    expect(find.text('العسل'), findsOneWidget);
    expect(find.text('الشمع'), findsOneWidget);
    final typeScroller = find.byType(Scrollable).first;
    for (final label in ['الخلطات', 'المنتجات الخام', 'الهدايا والعبوات']) {
      await tester.scrollUntilVisible(
        find.text(label),
        500,
        scrollable: typeScroller,
      );
      expect(find.text(label), findsOneWidget);
    }
    await tester.scrollUntilVisible(
      find.text('تحديث'),
      -500,
      scrollable: typeScroller,
    );
    expect(find.text('تحديث'), findsOneWidget);
    expect(find.text('العسل السائل'), findsOneWidget);
    expect(find.textContaining('1 منتج متاح'), findsOneWidget);
  });

  testWidgets('TASK 013 searches and filters categories without fake data',
      (tester) async {
    await _pumpCategories(tester);

    await tester.enterText(find.byType(TextField), 'سائل');
    await tester.pump();
    expect(find.text('العسل السائل'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'غير موجود');
    await tester.pump();
    expect(
      find.text('لا توجد تصنيفات مطابقة. جرّب كلمة أخرى أو غيّر النوع.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.tap(find.text('العسل'));
    await tester.pump();
    expect(find.text('العسل السائل'), findsOneWidget);
    await tester.tap(find.text('الشمع'));
    await tester.pump();
    expect(
      find.text('لا توجد تصنيفات مطابقة. جرّب كلمة أخرى أو غيّر النوع.'),
      findsOneWidget,
    );
  });

  testWidgets('TASK 013 opens search for a selected category and refreshes',
      (tester) async {
    await _pumpCategories(tester);

    final filterScroller = find.byType(Scrollable).at(1);
    await tester.drag(filterScroller, const Offset(700, 0));
    await tester.pumpAndSettle();
    expect(find.text('تحديث'), findsOneWidget);
    await tester.tap(find.text('تحديث'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('العسل السائل'));
    await tester.pumpAndSettle();

    expect(find.text('ابحث عن منتج أو متجر'), findsOneWidget);
    expect(find.text('نتائج البحث'), findsOneWidget);
  });

  testWidgets('TASK 013 records the categories visual contract',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpCategories(tester);
    await expectLater(
      find.byType(CategoriesScreen),
      matchesGoldenFile(
        'visual_reference/task013_categories_reference_360x780.png',
      ),
    );
  });
}
