import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom/app/assal_app.dart';

Future<void> _loadArabicFontsForGolden() async {
  final loader = FontLoader('Assal Golden Arabic Task 002');
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
  testWidgets('TASK 002 renders Arabic startup error and retries',
      (tester) async {
    var retryCount = 0;
    await tester.pumpWidget(MaterialApp(
      home: AssalStartupErrorScreen(
        messageAr: 'تعذر تهيئة مصدر البيانات الآن.',
        onRetry: () => retryCount += 1,
      ),
    ));
    await tester.pump();

    expect(find.text('خطأ بدء التشغيل'), findsOneWidget);
    expect(find.text('تعذر تشغيل التطبيق'), findsNWidgets(2));
    expect(find.text('غير متصل'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    expect(find.text('تعذر تهيئة مصدر البيانات الآن.'), findsOneWidget);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pump();
    expect(retryCount, 1);
  });

  testWidgets('TASK 002 has a recorded full-screen comparison', (tester) async {
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _loadArabicFontsForGolden();

    await tester.pumpWidget(MaterialApp(
      home: AssalStartupErrorScreen(
        messageAr: 'تعذر تهيئة مصدر البيانات الآن.',
        onRetry: () {},
      ),
    ));
    await tester.pump();

    await expectLater(
      find.byType(AssalStartupErrorScreen),
      matchesGoldenFile(
        'visual_reference/task002_startup_error_reference_360x780.png',
      ),
    );
  });
}
