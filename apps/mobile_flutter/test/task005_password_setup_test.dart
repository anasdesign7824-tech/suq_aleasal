import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom/features/customer/customer_account.dart';

import 'test_catalog.dart';

Future<void> _loadArabicFontsForGolden() async {
  final loader = FontLoader('Assal Golden Arabic Task 005');
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
  testWidgets('TASK 005 renders password setup and strength states',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AuthScreen(repository: buildTestDemoRepository()),
    ));
    await tester.pump();

    await tester.tap(find.text('إنشاء حساب'));
    await tester.pump();
    expect(find.text('إنشاء وتأكيد كلمة المرور'), findsOneWidget);
    expect(
        find.text('أنشئ كلمة مرورك. ستستخدمها لتأمين حسابك.'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
    expect(find.text('تأكيد كلمة المرور'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-name')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-email')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-password')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-password-confirm')), findsOneWidget);
    expect(find.text('حفظ ومتابعة'), findsOneWidget);
    expect(find.text('كلمة المرور ضعيفة'), findsOneWidget);

    final passwordField = find.byKey(const ValueKey('auth-password'));
    await tester.enterText(passwordField, 'Abcdef12');
    await tester.pump();
    expect(find.text('كلمة المرور متوسطة'), findsOneWidget);
    await tester.enterText(passwordField, 'Abcdef12!');
    await tester.pump();
    expect(find.text('كلمة المرور قوية'), findsOneWidget);

    await tester.tap(find.text('حفظ ومتابعة'));
    await tester.pump();
    expect(find.text('أدخل بريدًا إلكترونيًا صالحًا.'), findsOneWidget);
  });

  testWidgets('TASK 005 records the password setup visual contract',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 3120);
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
    await tester.tap(find.text('إنشاء حساب'));
    await tester.pump();

    await expectLater(
      find.byType(AuthScreen),
      matchesGoldenFile(
        'visual_reference/task005_password_setup_reference_360x780.png',
      ),
    );
  });

  testWidgets('TASK 005 submits a valid registration through the repository',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final repository = buildTestDemoRepository();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      home: const SizedBox.shrink(),
    ));
    navigatorKey.currentState!.push(
      MaterialPageRoute(
        builder: (_) => AuthScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('إنشاء حساب'));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('auth-name')), 'New User');
    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'customer@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password')),
      'Abcdef12!',
    );
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Abcdef12!');
    await tester.tap(find.text('حفظ ومتابعة'));
    await tester.pumpAndSettle();

    expect(find.byType(AuthScreen), findsNothing);
    final session = await repository.getSession();
    expect(session.isAuthenticated, isTrue);
    expect(session.user?.email, 'customer@example.com');
  });

  testWidgets('TASK 005 keeps password validation before registration',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AuthScreen(repository: buildTestDemoRepository()),
    ));
    await tester.pump();
    await tester.tap(find.text('إنشاء حساب'));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('auth-name')), 'New User');
    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'customer@example.com',
    );
    await tester.enterText(find.byKey(const ValueKey('auth-password')), 'weak');
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'weak');
    await tester.tap(find.text('حفظ ومتابعة'));
    await tester.pump();

    expect(
      find.textContaining('اختر كلمة مرور أقوى'),
      findsOneWidget,
    );
  });
}
