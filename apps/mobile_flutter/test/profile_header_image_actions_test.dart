import 'package:assalkom_contracts/assal_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/core/assal_widgets.dart';

void main() {
  testWidgets('profile header exposes direct cover and avatar actions',
      (tester) async {
    var avatarPicks = 0;
    var coverPicks = 0;
    const user = AssalUserProfile(id: 'u1', nameAr: 'عميل عسلكم');

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: AssalProfileHeaderCard(
            user: user,
            onPickAvatar: () => avatarPicks++,
            onPickCover: () => coverPicks++,
          ),
        ),
      ),
    );

    expect(find.byTooltip('تغيير الصورة الشخصية'), findsOneWidget);
    expect(find.byTooltip('تغيير صورة الغلاف'), findsOneWidget);

    await tester.tap(find.byTooltip('تغيير الصورة الشخصية'));
    await tester.tap(find.byTooltip('تغيير صورة الغلاف'));
    expect(avatarPicks, 1);
    expect(coverPicks, 1);
  });
}
