import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom/features/merchant/merchant_product_editor.dart';

class _QualityRepository implements AssalRepository {
  int regionCalls = 0;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => AssalSession.guest;

  @override
  Future<AssalLoadState<List<AssalTaxonomy>>> listTaxonomy() async =>
      const AssalData([
        AssalTaxonomy(
          id: 'taxonomy-1',
          code: 'honey',
          nameAr: 'العسل السائل',
        ),
      ]);

  @override
  Future<AssalLoadState<List<AssalRegion>>> listRegions() async {
    regionCalls += 1;
    if (regionCalls == 1) {
      return const AssalError<List<AssalRegion>>(
        'تعذر تحميل المناطق الآن',
        code: 'regions_unavailable',
        retryable: true,
      );
    }
    return const AssalData([
      AssalRegion(id: 'governorate-1', nameAr: 'أمانة العاصمة'),
      AssalRegion(
        id: 'district-1',
        nameAr: 'مديرية حدة',
        parentRegionId: 'governorate-1',
      ),
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

Future<void> _pumpQualityEditor(
  WidgetTester tester,
  _QualityRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MerchantProductEditorScreen(
        repository: repository,
        storeId: 'store-1',
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('الجودة والمصدر'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 045 يعرض حقول المصدر والجودة المرتبطة بالعقد',
      (tester) async {
    final repository = _QualityRepository();
    await _pumpQualityEditor(tester, repository);

    expect(find.text('بلد المصدر'), findsOneWidget);

    final qualityScroll = find.byType(ListView).last;
    await tester.drag(qualityScroll, const Offset(0, -1800));
    await tester.pumpAndSettle();
    expect(find.text('مدة الصلاحية'), findsOneWidget);
    expect(find.text('المكونات — افصل بينها بفاصلة'), findsOneWidget);
    expect(find.text('الشهادات — افصل بينها بفاصلة'), findsOneWidget);
  });

  testWidgets('TASK 045 يعرض خطأ المناطق ثم يعيد قراءتها عبر retry',
      (tester) async {
    final repository = _QualityRepository();
    await _pumpQualityEditor(tester, repository);

    final qualityScroll = find.byType(ListView).last;
    await tester.drag(qualityScroll, const Offset(0, -180));
    await tester.pumpAndSettle();

    expect(repository.regionCalls, greaterThanOrEqualTo(1));
    expect(find.textContaining('تعذر تحميل المناطق الآن'), findsOneWidget);
    final retryButton = find.text('إعادة المحاولة');
    expect(retryButton, findsOneWidget);
    await tester.ensureVisible(retryButton);
    await tester.tap(retryButton);
    await tester.pumpAndSettle();
    await tester.drag(qualityScroll, const Offset(0, 180));
    await tester.pumpAndSettle();

    expect(find.text('محافظة الإنتاج'), findsOneWidget);
    expect(find.text('مديرية الإنتاج'), findsOneWidget);
    expect(repository.regionCalls, greaterThanOrEqualTo(2));
  });

  testWidgets('TASK 045 يبقي الإلغاء دون تعديل المصدر', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const SizedBox.shrink(),
      ),
    );
    await tester.pump();

    final resultFuture = navigatorKey.currentState!.push<bool>(
      MaterialPageRoute(
        builder: (_) => MerchantProductEditorScreen(
          repository: _QualityRepository(),
          storeId: 'store-1',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    expect(await resultFuture, isFalse);
  });

  testWidgets('TASK 045 records the visual contract', (tester) async {
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: MerchantProductEditorScreen(
          repository: _QualityRepository(),
          storeId: 'store-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MerchantProductEditorScreen),
      matchesGoldenFile(
        'visual_reference/task045_product_editor_quality_reference_360x780.png',
      ),
    );
  });
}
