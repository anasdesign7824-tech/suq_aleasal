import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';

import 'package:assalkom/core/assal_widgets.dart';

const _store = AssalStoreSummary(
  id: 'store-009',
  merchantId: 'merchant-009',
  nameAr: 'مناحل جبال اليمن',
  slug: 'yemen-mountains-apiary',
  regionNameAr: 'إب، اليمن',
  followersCount: 2300,
  ratingAverage: 4.8,
  reviewCount: 156,
);

void main() {
  testWidgets('TASK 009 renders the unified store card contract',
      (tester) async {
    var opened = 0;
    var actioned = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 360,
              child: StoreCard(
                store: _store,
                productCount: 156,
                onTap: () => opened++,
                onAction: () => actioned++,
                actionTooltip: 'إزالة المتابعة',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final frame = tester.widget<AspectRatio>(find.byType(AspectRatio).first);
    expect(frame.aspectRatio, 4 / 5);
    expect(find.text('مناحل جبال اليمن'), findsOneWidget);
    expect(find.text('إب، اليمن'), findsOneWidget);
    expect(find.text('2.3K'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('156'), findsOneWidget);
    expect(find.text('عرض المتجر'), findsOneWidget);
    expect(find.byTooltip('إزالة المتابعة'), findsOneWidget);

    await tester.tap(find.text('عرض المتجر'));
    await tester.tap(find.byTooltip('إزالة المتابعة'));
    expect(opened, 1);
    expect(actioned, 1);
  });

  testWidgets('TASK 009 keeps the store card usable at compact width',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 220,
              child: StoreCard(
                store: _store,
                productCount: 156,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(AspectRatio), findsOneWidget);
  });

  testWidgets('TASK 009 records the 4:5 store-card visual contract',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1800);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StoreCard(
              store: _store,
              productCount: 156,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(StoreCard),
      matchesGoldenFile(
        'visual_reference/task009_store_card_reference_360x450.png',
      ),
    );
  });
}
