import 'package:assalkom/features/customer/customer_account.dart';
import 'package:assalkom_data/demo_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _emptyRequestsCatalog = '''
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

void main() {
  testWidgets('TASK 071 renders the authenticated empty requests state',
      (tester) async {
    final repository = DemoRepository(
      loader: const InMemoryDemoCatalogLoader(_emptyRequestsCatalog),
    );
    await repository.register(
      'عميل اختبار',
      'empty-requests@example.com',
      'StrongPass1!',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: RequestsScreen(repository: repository),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('طلباتي'), findsOneWidget);
    expect(find.text('لا توجد طلبات تواصل بعد.'), findsOneWidget);
    expect(find.text('استكشف المنتجات'), findsOneWidget);
    expect(find.text('تسجيل الدخول لمتابعة الطلبات'), findsNothing);
  });
}
