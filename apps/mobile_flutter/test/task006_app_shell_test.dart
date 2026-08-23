import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom/app/assal_app.dart';

import 'test_catalog.dart';

Future<void> _loadArabicFontsForGolden() async {
  final loader = FontLoader('Assal Golden Arabic Task 006');
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
  testWidgets('TASK 006 exposes the contract navigation destinations',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: AssalHomeShell(repository: buildTestDemoRepository()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1200));

    for (final label in <String>[
      'الرئيسية',
      'البحث',
      'المحفوظات',
      'المتابعات',
      'الملف الشخصي',
      'الإشعارات',
    ]) {
      expect(find.text(label), findsAtLeastNWidgets(1));
    }

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('البحث'),
    ));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('البحث'), findsAtLeastNWidgets(1));

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('المحفوظات'),
    ));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('المحفوظات'), findsAtLeastNWidgets(1));
    expect(find.text('تسجيل الدخول لعرض محفوظاتك'), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('المتابعات'),
    ));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('المحفوظات'), findsAtLeastNWidgets(1));
    expect(find.text('تسجيل الدخول لعرض محفوظاتك'), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('الإشعارات'),
    ));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('الإشعارات'), findsAtLeastNWidgets(1));
    expect(find.text('تسجيل الدخول لعرض إشعاراتك'), findsOneWidget);
  });

  testWidgets('TASK 006 records the mobile shell visual contract',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _loadArabicFontsForGolden();
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: AssalHomeShell(repository: buildTestDemoRepository()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1200));

    await expectLater(
      find.byType(AssalHomeShell),
      matchesGoldenFile(
        'visual_reference/task006_app_shell_reference_360x780.png',
      ),
    );
  });

  testWidgets('TASK 006 keeps the desktop navigation rail available',
      (tester) async {
    tester.view.physicalSize = const Size(3600, 3120);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: AssalHomeShell(repository: buildTestDemoRepository()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('المحفوظات'), findsAtLeastNWidgets(1));
    expect(find.text('المتابعات'), findsAtLeastNWidgets(1));
    expect(find.text('الإشعارات'), findsAtLeastNWidgets(1));
  });
}
