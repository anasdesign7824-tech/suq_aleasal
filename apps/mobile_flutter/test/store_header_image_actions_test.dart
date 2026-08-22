import 'package:assalkom_contracts/assal_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom/core/assal_widgets.dart';

void main() {
  testWidgets('merchant store header exposes direct image actions',
      (tester) async {
    var logoPicks = 0;
    var coverPicks = 0;
    const store = AssalStoreSummary(
      id: 's1',
      merchantId: 'u1',
      nameAr: 'متجر عسلكم',
      slug: 'assalkom',
      status: StoreStatus.active,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: AssalStoreHeaderCard(
            store: store,
            onPickLogo: () => logoPicks++,
            onPickCover: () => coverPicks++,
          ),
        ),
      ),
    );

    expect(find.byTooltip('تغيير شعار المتجر'), findsOneWidget);
    expect(find.byTooltip('تغيير صورة غلاف المتجر'), findsOneWidget);

    await tester.tap(find.byTooltip('تغيير شعار المتجر'));
    await tester.tap(find.byTooltip('تغيير صورة غلاف المتجر'));
    expect(logoPicks, 1);
    expect(coverPicks, 1);
  });
}
