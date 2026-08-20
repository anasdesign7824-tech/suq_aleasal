import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom/app/assal_app.dart';
import 'test_catalog.dart';

void main() {
  testWidgets('customer app boots into guest discovery', (tester) async {
    await tester.pumpWidget(AssalApp(
      repository: buildTestDemoRepository(),
    ));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));
    await tester.pump();
    final bootException = tester.takeException();
    expect(bootException, isNull);
    expect(find.textContaining('الثقة تبدأ من المصدر'), findsAtLeastNWidgets(1));
    expect(find.text('استكشف حسب التصنيف'), findsOneWidget);
    expect(find.text('منتجات مختارة'), findsOneWidget);
  });
}
