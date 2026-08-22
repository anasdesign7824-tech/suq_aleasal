import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/demo_repository.dart';

import 'package:assalkom/features/customer/customer_request_detail.dart';

void main() {
  final request = AssalRequestSummary(
    id: 'request-1',
    requesterId: 'customer-1',
    storeId: 'store-1',
    merchantId: 'merchant-1',
    subject: 'طلب توفر عسل السدر',
    status: RequestStatus.open,
    productId: 'product-1',
    productName: 'عسل سدر يمني',
    storeName: 'متجر العسل',
    requesterName: 'عميل الاختبار',
    body: 'هل المنتج متوفر؟',
    quantity: 2,
    preferredHandoffOption: 'pickup',
    createdAt: DateTime(2026, 8, 22, 10, 30),
  );

  testWidgets('customer sees request details and empty reply state',
      (tester) async {
    final repository = DemoRepository(
      loader: const InMemoryDemoCatalogLoader('{}'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CustomerRequestDetailScreen(
          repository: repository,
          request: request,
          merchantMode: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تفاصيل الطلب'), findsOneWidget);
    expect(find.text('عسل سدر يمني'), findsOneWidget);
    expect(find.text('لم يصل رد على الطلب بعد.'), findsOneWidget);
    expect(find.text('إجابة التاجر'), findsNothing);
  });

  testWidgets('merchant sees response controls and availability choices',
      (tester) async {
    final repository = DemoRepository(
      loader: const InMemoryDemoCatalogLoader('{}'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CustomerRequestDetailScreen(
          repository: repository,
          request: request,
          merchantMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الرد على الطلب'), findsOneWidget);
    expect(find.text('إجابة التاجر'), findsOneWidget);
    expect(find.text('حالة التوفر'), findsOneWidget);
    expect(find.text('إرسال الرد'), findsOneWidget);
  });
}
