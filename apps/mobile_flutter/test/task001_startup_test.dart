import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom/app/assal_startup.dart';

Future<void> _loadArabicFontsForGolden() async {
  final loader = FontLoader('Assal Golden Arabic');
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
  testWidgets('TASK 001 renders the Arabic startup contract', (tester) async {
    tester.view.physicalSize = const Size(1440, 2560);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _loadArabicFontsForGolden();

    await tester.pumpWidget(const MaterialApp(
      home: AssalStartupView(fontFamily: 'Assal Golden Arabic'),
    ));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump();

    expect(find.text('عسلكم'), findsOneWidget);
    expect(find.text('من اليمن .. طبيعة أصيلة'), findsOneWidget);
    expect(find.text('جارٍ تجهيز سوق العسل...'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('جارٍ تجهيز سوق العسل')),
      findsOneWidget,
    );

    await expectLater(
      find.byType(AssalStartupView),
      matchesGoldenFile('visual_reference/task001_startup_reference_360x640.png'),
    );
  });

  testWidgets('TASK 001 startup gate transitions to the configured app',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: AssalStartupGate(
        duration: Duration(milliseconds: 100),
        child: Text('المحتوى الجاهز'),
      ),
    ));
    expect(find.text('جارٍ تجهيز سوق العسل...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 110));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('المحتوى الجاهز'), findsOneWidget);
  });
}
