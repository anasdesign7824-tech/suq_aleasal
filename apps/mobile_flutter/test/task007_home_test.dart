import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom/features/customer/customer_experience.dart';

import 'test_catalog.dart';

Future<void> _loadArabicFontsForGolden() async {
  final loader = FontLoader('Assal Golden Arabic Task 007');
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

Widget _home({required VoidCallback onOpenSearch}) => MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: HomeScreen(
            repository: buildTestDemoRepository(),
            onOpenSearch: onOpenSearch,
            onOpenNotifications: () {},
          ),
        ),
      ),
    );

Future<void> _pumpHome(WidgetTester tester) async {
  for (var index = 0; index < 6; index++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  testWidgets('TASK 007 renders the home discovery contract and CTA',
      (tester) async {
    var searchOpened = 0;
    await tester.pumpWidget(_home(onOpenSearch: () => searchOpened++));
    await _pumpHome(tester);

    expect(find.text('ابحث عن عسل أو متجر'), findsOneWidget);
    expect(find.text('طبيعة أصيلة .. عسل أصيل'), findsOneWidget);
    expect(
        find.text('اكتشف أفضل أنواع العسل اليمني الطبيعي من النحل إلى مائدتك'),
        findsOneWidget);
    expect(find.text('اكتشف الآن'), findsOneWidget);
    expect(find.text('استكشف حسب التصنيف'), findsOneWidget);
    expect(find.text('منتجات مختارة'), findsOneWidget);

    await tester.tap(find.text('اكتشف الآن'));
    await tester.pump();
    expect(searchOpened, 1);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(searchOpened, 2);
  });

  testWidgets('TASK 007 exposes lower home rails after scrolling',
      (tester) async {
    await tester.pumpWidget(_home(onOpenSearch: () {}));
    await _pumpHome(tester);

    final scrollable = find.byType(Scrollable).first;
    expect(find.byType(Scrollable), findsWidgets);
    for (final target in <String>[
      'الأكثر مشاهدة',
      'وصل حديثًا',
      'الأعلى تقييمًا',
      'متاجر عسلكم',
    ]) {
      await tester.scrollUntilVisible(
        find.text(target),
        500,
        scrollable: scrollable,
      );
      expect(find.text(target), findsOneWidget);
    }
  });

  testWidgets('TASK 007 records the mobile home visual contract',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 2560);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _loadArabicFontsForGolden();
    await tester.pumpWidget(_home(onOpenSearch: () {}));
    await _pumpHome(tester);

    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile(
        'visual_reference/task007_home_reference_360x640.png',
      ),
    );
  });
}
