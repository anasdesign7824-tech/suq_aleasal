import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom/features/merchant/merchant_product_editor.dart';
import 'test_catalog.dart';

void main() {
  testWidgets('editor keeps reference suggestions editable',
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

    expect(find.byType(Autocomplete<String>), findsAtLeastNWidgets(4));
    expect(find.text('وصف المصدر المحلي (اختياري)'), findsNothing);

    final editorScroll = find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        )
        .last;
    await tester.drag(editorScroll, const Offset(0, -420));
    await tester.pumpAndSettle();
    expect(find.byType(Autocomplete<String>), findsAtLeastNWidgets(1));
  });
}
