import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom/features/merchant/merchant_product_editor.dart';
import 'test_catalog.dart';

void main() {
  testWidgets('product metadata suggestions remain editable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MerchantProductEditorScreen(
          repository: buildTestDemoRepository(),
          storeId: 's1',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('الجودة والمصدر'));
    await tester.pumpAndSettle();

    final editorScroll = find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        )
        .last;

    await tester.scrollUntilVisible(
      find.bySemanticsLabel('مدة الصلاحية'),
      420,
      scrollable: editorScroll,
    );
    await tester.enterText(find.bySemanticsLabel('مدة الصلاحية'), '9 أشهر');
    expect(find.text('9 أشهر'), findsOneWidget);
    expect(find.text('12 شهرًا'), findsOneWidget);

    final componentChip = find.widgetWithText(ActionChip, 'عسل نحل طبيعي');
    await tester.scrollUntilVisible(
      componentChip,
      420,
      scrollable: editorScroll,
    );
    await tester.ensureVisible(componentChip);
    await tester.tap(componentChip);
    expect(find.text('عسل نحل طبيعي'), findsAtLeastNWidgets(1));

    expect(
      find.widgetWithText(ActionChip, 'شهادة منشأ'),
      findsOneWidget,
    );
  });
}
