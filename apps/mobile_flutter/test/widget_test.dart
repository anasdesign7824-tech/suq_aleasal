import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom/app/assal_app.dart';

void main() {
  testWidgets('customer app boots into guest discovery', (tester) async {
    await tester.pumpWidget(const AssalApp());
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));
    await tester.pump();
    final bootException = tester.takeException();
    expect(bootException, isNull);
    expect(find.textContaining('الثقة تبدأ من المصدر'), findsOneWidget);
    expect(find.textContaining('سدر يمني من وديانه'), findsOneWidget);
  });
}
