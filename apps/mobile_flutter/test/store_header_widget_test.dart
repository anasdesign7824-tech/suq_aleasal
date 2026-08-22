import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';

import 'package:assalkom/core/assal_widgets.dart';

void main() {
  testWidgets('store header exposes a real follow action over the cover',
      (tester) async {
    const store = AssalStoreSummary(
      id: 'store-1',
      merchantId: 'merchant-1',
      nameAr: 'متجر العسل',
      slug: 'honey-store',
      status: StoreStatus.active,
      isVerified: true,
      followersCount: 12,
    );
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssalStoreHeaderCard(
            store: store,
            onFollow: () => tapped = true,
            followersCountOverride: 13,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final button = find.byTooltip('متابعة المتجر');
    expect(button, findsOneWidget);
    await tester.tap(button);
    expect(tapped, isTrue);
    expect(find.text('12'), findsNothing);
    expect(find.text('13'), findsOneWidget);
    expect(find.text('متابع'), findsOneWidget);
    expect(find.text('موثق Pro'), findsNothing);
    expect(find.text('متجر مفعّل'), findsOneWidget);
  });
}
