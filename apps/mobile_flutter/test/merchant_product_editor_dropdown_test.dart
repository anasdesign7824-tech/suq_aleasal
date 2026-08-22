import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom/features/merchant/merchant_product_editor.dart';
import 'test_catalog.dart';

void main() {
  testWidgets('editor uses canonical dropdowns for reference fields',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MerchantProductEditorScreen(
          repository: buildTestDemoRepository(),
          storeId: 's1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الأساسي والتصنيف'), findsOneWidget);
    await tester.tap(find.text('الجودة والمصدر'));
    await tester.pumpAndSettle();

    expect(find.text('بلد المصدر'), findsOneWidget);
    expect(find.text('المصدر المحلي'), findsOneWidget);
    expect(find.text('وصف المصدر المحلي (اختياري)'), findsNothing);

    final editorScroll = find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        )
        .last;
    await tester.scrollUntilVisible(
      find.text('هوية العسل أو السلالة'),
      420,
      scrollable: editorScroll,
    );
    expect(find.text('هوية العسل أو السلالة'), findsOneWidget);
    expect(find.text('درجة الجودة'), findsOneWidget);
    expect(find.text('طريقة المعالجة'), findsOneWidget);
    expect(find.text('حالة المعالجة'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('نوع التغليف'),
      420,
      scrollable: editorScroll,
    );
    expect(find.text('نوع التغليف'), findsOneWidget);
    expect(
      find.byType(DropdownButtonFormField<String>),
      findsAtLeastNWidgets(3),
    );
  });
}
