import 'package:assalkom/features/customer/customer_discovery.dart';
import 'package:assalkom_data/demo_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _emptyStoresCatalog = '''
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

const _oneStoreCatalog = '''
{
  "regions": [],
  "stores": [{"id":"s1","merchant_id":"m1","name_ar":"مناحل دوعن","slug":"doani","status":"active","is_verified":true,"followers_count":12}],
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

DemoRepository _repository(String catalog) => DemoRepository(
      loader: InMemoryDemoCatalogLoader(catalog),
    );

Future<void> _pumpStores(WidgetTester tester, DemoRepository repository) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: StoresScreen(repository: repository),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  testWidgets('TASK 070 exposes an actionable empty stores state',
      (tester) async {
    await _pumpStores(tester, _repository(_emptyStoresCatalog));

    expect(
      find.text('لا توجد متاجر منشورة الآن. جرّب تحديث القائمة أو مسح الفلاتر.'),
      findsOneWidget,
    );
  });

  testWidgets('TASK 070 distinguishes filter mismatch from an empty source',
      (tester) async {
    await _pumpStores(tester, _repository(_oneStoreCatalog));
    expect(find.text('مناحل دوعن'), findsAtLeastNWidgets(1));

    await tester.enterText(find.byType(TextField).first, 'لا يوجد');
    await tester.pump();
    expect(
      find.text('لا توجد متاجر مطابقة للبحث أو الفلاتر الحالية.'),
      findsOneWidget,
    );

  });
}
