import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom/app/assal_app.dart';

void main() {
  testWidgets('customer app boots into guest discovery', (tester) async {
    await tester.pumpWidget(const AssalApp());
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
    await tester.pump();
    final bootException = tester.takeException();
    expect(bootException, isNull);
    expect(find.textContaining('اكتشف العسل من مصدره'), findsOneWidget);
    expect(find.textContaining('تصفح المتاجر والمنتجات اليمنية الموثوقة'), findsOneWidget);
  });
}
