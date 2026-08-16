import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom/app/assal_app.dart';

void main() {
  testWidgets('guest can navigate core customer surfaces without auth wall', (tester) async {
    await tester.pumpWidget(const AssalApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('اكتشف العسل من مصدره'), findsOneWidget);

    await tester.tap(find.text('التصنيفات').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('التصنيفات'), findsWidgets);

    await tester.tap(find.text('حسابي').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('تصفح كزائر'), findsOneWidget);
    expect(find.text('تسجيل الدخول أو إنشاء حساب'), findsOneWidget);
  });
}
