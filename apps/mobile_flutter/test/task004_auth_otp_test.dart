import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom/features/customer/customer_account.dart';

import 'test_catalog.dart';

Future<void> _openOtpDialog(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    home: AuthScreen(repository: buildTestDemoRepository()),
  ));
  await tester.pump();
  await tester.enterText(find.byType(TextField).first, 'customer@example.com');
  await tester.tap(find.text('إرسال رمز التحقق'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('TASK 004 renders OTP verification controls', (tester) async {
    await _openOtpDialog(tester);

    expect(find.text('تحقق من بريدك'), findsOneWidget);
    expect(find.text('أرسلنا رمز التحقق إلى البريد المدخل'), findsOneWidget);
    expect(find.text('تعديل البريد'), findsOneWidget);
    expect(find.text('رمز التحقق (6–9 أرقام)'), findsOneWidget);
    expect(find.text('إعادة إرسال الرمز 0:30'), findsOneWidget);
    expect(find.text('تحقق'), findsOneWidget);

    await tester.tap(find.text('تعديل البريد'));
    await tester.pump();
    expect(find.text('يمكنك تعديل البريد قبل التحقق'), findsOneWidget);

    Navigator.of(tester.element(find.byType(AlertDialog))).pop();
    await tester.pump();
  });

  testWidgets('TASK 004 records the OTP visual contract', (tester) async {
    tester.view.physicalSize = const Size(1440, 2560);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _openOtpDialog(tester);

    await expectLater(
      find.byType(AuthScreen),
      matchesGoldenFile(
        'visual_reference/task004_auth_otp_reference_360x640.png',
      ),
    );

    Navigator.of(tester.element(find.byType(AlertDialog))).pop();
    await tester.pump();
  });
}
