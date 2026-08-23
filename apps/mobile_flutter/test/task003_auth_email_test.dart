import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom/features/customer/customer_account.dart';

import 'test_catalog.dart';

Future<void> _loadArabicFontsForGolden() async {
  final loader = FontLoader('Assal Golden Arabic Task 003');
  for (final filename in <String>[
    'IBMPlexSansArabic-Regular.ttf',
    'IBMPlexSansArabic-Medium.ttf',
    'IBMPlexSansArabic-SemiBold.ttf',
    'IBMPlexSansArabic-Bold.ttf',
  ]) {
    loader.addFont(rootBundle.load('assets/fonts/$filename'));
  }
  await loader.load();
}

void main() {
  testWidgets('TASK 003 renders email auth and help action', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AuthScreen(repository: buildTestDemoRepository()),
    ));
    await tester.pump();

    expect(find.text('عسلكم'), findsOneWidget);
    expect(find.text('مرحبًا بك في عسلكم'), findsOneWidget);
    expect(find.text('أدخل بريدك الإلكتروني للمتابعة'), findsOneWidget);
    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('إرسال رمز التحقق'), findsOneWidget);
    expect(find.text('إنشاء حساب'), findsOneWidget);
    expect(find.text('المساعدة'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'not-an-email');
    await tester.tap(find.text('إرسال رمز التحقق'));
    await tester.pump();
    expect(find.text('أدخل بريدًا إلكترونيًا صالحًا.'), findsOneWidget);
  });

  testWidgets('TASK 003 records the email auth visual contract',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 2560);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _loadArabicFontsForGolden();
    await tester.pumpWidget(MaterialApp(
      home: AuthScreen(repository: buildTestDemoRepository()),
    ));
    await tester.pump();

    await expectLater(
      find.byType(AuthScreen),
      matchesGoldenFile(
        'visual_reference/task003_auth_email_reference_360x640.png',
      ),
    );
  });

  testWidgets('TASK 003 keeps the real OTP transition on a valid email',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AuthScreen(repository: buildTestDemoRepository()),
    ));
    await tester.pump();
    await tester.enterText(
        find.byType(TextField).first, 'customer@example.com');
    await tester.tap(find.text('إرسال رمز التحقق'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('رمز الدخول'), findsOneWidget);
    expect(find.text('أرسلنا رمز الدخول إلى'), findsOneWidget);
    expect(find.text('رمز التحقق (6–9 أرقام)'), findsOneWidget);

    Navigator.of(tester.element(find.byType(AlertDialog))).pop();
    await tester.pump();
  });
}
