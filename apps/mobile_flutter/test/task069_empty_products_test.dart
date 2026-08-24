import 'package:assalkom/features/customer/customer_discovery.dart';
import 'package:assalkom/core/assal_widgets.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/demo_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _emptyProductsCatalog = '''
{
  "regions": [],
  "stores": [],
  "products": [],
  "banners": [],
  "popular_searches": [],
  "reviews": [],
  "comments": [],
  "requests": [],
  "notifications": [],
  "conversations": [],
  "messages": []
}
''';

DemoRepository _emptyProductsRepository() => DemoRepository(
      loader: const InMemoryDemoCatalogLoader(_emptyProductsCatalog),
    );

Future<void> _pumpEmptySearch(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: SearchScreen(repository: _emptyProductsRepository()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  testWidgets('TASK 069 makes the empty-state action executable', (tester) async {
    var actionCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AssalStateView<List<AssalProductSummary>>(
          state: const AssalEmpty<List<AssalProductSummary>>('لا توجد منتجات'),
          builder: (_) => const SizedBox.shrink(),
          emptyActionLabel: 'استكشف المنتجات',
          onEmptyAction: () => actionCount++,
        ),
      ),
    );

    await tester.tap(find.text('استكشف المنتجات'));
    expect(actionCount, 1);
  });

  testWidgets('TASK 069 gives empty product search a real recovery action',
      (tester) async {
    await _pumpEmptySearch(tester);

    expect(
      find.text('لا توجد منتجات مطابقة. جرّب إزالة البحث أو الفلاتر.'),
      findsOneWidget,
    );
    final clearAction = find.text('مسح البحث والفلاتر');
    expect(clearAction, findsOneWidget);

    await tester.tap(clearAction);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.text('لا توجد منتجات مطابقة. جرّب إزالة البحث أو الفلاتر.'),
      findsOneWidget,
    );
  });

}
