import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom/app/assal_app.dart';
import 'test_catalog.dart';

void main() {
  testWidgets('guest can navigate core customer surfaces without auth wall',
      (tester) async {
    await tester.pumpWidget(AssalApp(
      repository: buildTestDemoRepository(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('البحث').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('البحث'), findsWidgets);

    await tester.tap(find.text('الملف الشخصي').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('تصفح كزائر'), findsOneWidget);
    expect(find.text('تسجيل الدخول أو إنشاء حساب'), findsOneWidget);

    await tester.tap(find.text('تسجيل الدخول أو إنشاء حساب'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('إرسال رمز التحقق'), findsOneWidget);
    expect(find.text('مرحبًا بك في عسلكم'), findsOneWidget);
    expect(find.text('إنشاء حساب'), findsOneWidget);
    expect(find.text('هل لديك حساب؟ سجّل الدخول إلى حسابك الموجود.'),
        findsNothing);
    expect(find.text('نسيت كلمة المرور؟'), findsNothing);
    expect(find.text('المتابعة عبر Google'), findsNothing);
    expect(find.text('المتابعة عبر Facebook'), findsNothing);
  });
}
