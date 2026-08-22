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
    var following = false;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: AssalStoreHeaderCard(
              store: store,
              isFollowing: following,
              onFollow: () => setState(() => following = !following),
              followersCountOverride: following ? 13 : 12,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final button = find.byTooltip('متابعة المتجر');
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byTooltip('إلغاء متابعة المتجر'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('12'), findsNothing);
    expect(find.text('13'), findsOneWidget);
    expect(find.text('متابع'), findsOneWidget);
    expect(find.text('موثق Pro'), findsNothing);
    expect(find.text('متجر مفعّل'), findsNothing);
  });
}
