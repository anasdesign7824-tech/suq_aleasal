import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom/app/assal_app.dart';

void main() {
  testWidgets('customer app boots into guest discovery', (tester) async {
    await tester.pumpWidget(const AssalApp());
    await tester.pump();
    expect(find.text('اكتشف العسل من مصدره'), findsOneWidget);
    expect(find.text('تصفح'), findsNothing);
  });
}
