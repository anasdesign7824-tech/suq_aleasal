import 'package:assalkom_data/demo_repository.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom/features/merchant/merchant_product_editor.dart';
import 'package:assalkom/core/assal_widgets.dart';
import 'test_catalog.dart';

class _EmptyCatalogLoader implements DemoCatalogLoader {
  @override
  Future<String> loadJson() async => '{"regions":[],"products":[]}';
}

Widget _editor(AssalRepositoryFactory factory) => MaterialApp(
      home: MerchantProductEditorScreen(
        repository: factory(),
        storeId: 's1',
      ),
    );

typedef AssalRepositoryFactory = DemoRepository Function();

void main() {
  testWidgets('TASK 044 يعرض البيانات الأساسية ويتحقق من الاسم',
      (tester) async {
    await tester.pumpWidget(
      _editor(buildTestDemoRepository),
    );
    await tester.pumpAndSettle();

    expect(find.text('الأساسي والتصنيف'), findsOneWidget);
    expect(find.text('حفظ المنتج ومعاينته'), findsOneWidget);
    expect(find.text('إلغاء'), findsOneWidget);

    await tester.drag(
      find.byType(ListView).first,
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsAtLeastNWidgets(3));
    expect(find.byType(DropdownButtonFormField<ProductType>), findsOneWidget);

    await tester.tap(find.text('حفظ المنتج ومعاينته'));
    await tester.pump();

    expect(find.text('اكتب اسم المنتج.'), findsOneWidget);
  });

  testWidgets('TASK 044 يعرض الفراغ ويتيح إعادة تحميل التصنيفات',
      (tester) async {
    final loader = _EmptyCatalogLoader();
    final repository = DemoRepository(loader: loader);
    await tester.pumpWidget(
      MaterialApp(
        home: MerchantProductEditorScreen(
          repository: repository,
          storeId: 's1',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(ListView).first,
      const Offset(0, -2000),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AssalMessageCard), findsOneWidget);
    final retryButton = find.text('إعادة المحاولة');
    expect(retryButton, findsOneWidget);
    await tester.ensureVisible(retryButton);
    await tester.tap(retryButton);
    await tester.pumpAndSettle();

    expect(find.byType(AssalMessageCard), findsOneWidget);
  });

  testWidgets('TASK 044 يعيد نتيجة إلغاء واضحة دون حفظ', (tester) async {
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
          repository: buildTestDemoRepository(),
          storeId: 's1',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    expect(await resultFuture, isFalse);
  });

  testWidgets('TASK 044 records the visual contract', (tester) async {
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      _editor(buildTestDemoRepository),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MerchantProductEditorScreen),
      matchesGoldenFile(
        'visual_reference/task044_product_editor_basic_reference_360x780.png',
      ),
    );
  });
}
