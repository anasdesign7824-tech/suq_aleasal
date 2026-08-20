import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom/core/assal_widgets.dart';

void main() {
  testWidgets('shared app bar reserves space for tab navigation', (tester) async {
    const bar = AssalAppBar(
      title: 'المحفوظات والمتابعات',
      bottom: TabBar(
        tabs: [
          Tab(text: 'منتجات محفوظة'),
          Tab(text: 'متاجر متابَعة'),
        ],
      ),
    );

    expect(bar.preferredSize.height, greaterThan(kToolbarHeight));
    await tester.pumpWidget(
      const MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: bar,
            body: SizedBox.shrink(),
          ),
        ),
      ),
    );

    expect(find.text('منتجات محفوظة'), findsOneWidget);
    expect(find.text('متاجر متابَعة'), findsOneWidget);
  });

  testWidgets('image picker tile invokes the action from its in-place icon',
      (tester) async {
    var picked = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssalImagePickerTile(
            onPick: () => picked = true,
            label: 'إضافة صورة المتجر',
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('إضافة صورة المتجر'), findsOneWidget);
    await tester.tap(find.byTooltip('إضافة الصورة'));
    expect(picked, isTrue);
  });

  testWidgets('premium badge is explicit and readable', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AssalPremiumBadge(label: 'خطة ذهبية'),
        ),
      ),
    );

    expect(find.text('خطة ذهبية'), findsOneWidget);
    expect(find.byIcon(Icons.workspace_premium_outlined), findsOneWidget);
  });
}
