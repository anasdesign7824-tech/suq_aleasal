import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom/app/assal_app.dart';

void main() {
  testWidgets('customer app boots into guest discovery', (tester) async {
    await tester.pumpWidget(const AssalApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    final bootException = tester.takeException();
    debugPrint('BOOT exception=$bootException');
    debugPrint('BOOT home=${find.text('اكتشف العسل من مصدره').evaluate().length} loading=${find.text('جارٍ تحميل الصفحة والمنتجات...').evaluate().length} startupError=${find.text('تعذر تجهيز الصفحة الآن. تحقق من الاتصال ثم أعد المحاولة.').evaluate().length}');
    debugPrint('BOOT texts=${tester.widgetList<Text>(find.byType(Text)).map((widget) => widget.data).whereType<String>().take(20).join(' | ')}');
    expect(bootException, isNull);
    expect(find.text('اكتشف العسل من مصدره'), findsOneWidget);
    expect(find.text('تصفح'), findsNothing);
  });
}
