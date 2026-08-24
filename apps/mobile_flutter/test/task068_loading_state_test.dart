import 'dart:async';

import 'package:assalkom/core/assal_widgets.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TASK 068 exposes an Arabic loading state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AssalGlassLoading(label: 'جارٍ تحميل المنتجات'),
        ),
      ),
    );

    expect(find.byIcon(Icons.hive_outlined), findsOneWidget);
    expect(find.text('جارٍ تحميل المنتجات'), findsOneWidget);
  });

  testWidgets('TASK 068 keeps the shared loader while a future is pending',
      (tester) async {
    final pending = Completer<AssalLoadState<int>>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssalFutureStateView<int>(
            future: pending.future,
            builder: (value) => Text('$value'),
          ),
        ),
      ),
    );

    expect(find.byType(AssalGlassLoading), findsOneWidget);
    expect(find.text('جارٍ تجهيز تجربة عسلكم...'), findsOneWidget);

    pending.complete(const AssalData<int>(1));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
  });
}
