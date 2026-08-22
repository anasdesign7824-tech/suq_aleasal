import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';

import 'package:assalkom/features/customer/customer_catalog.dart';

void main() {
  testWidgets('request form stays open when backend save fails',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const product = AssalProductSummary(
      id: 'product-1',
      storeId: 'store-1',
      nameAr: 'عسل سدر يمني',
      productType: ProductType.honey,
      status: ProductStatus.active,
    );
    const store = AssalStoreSummary(
      id: 'store-1',
      merchantId: 'merchant-1',
      nameAr: 'متجر العسل',
      slug: 'honey-store',
      status: StoreStatus.active,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RequestSheet(
            repository: _FailingRequestRepository(),
            product: product,
            store: store,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('حفظ وإرسال الطلب'));
    await tester.pumpAndSettle();

    expect(find.text('طلب تواصل مع متجر العسل'), findsOneWidget);
    expect(find.text('تعذر حفظ الطلب من الخادم'), findsOneWidget);
  });
}

class _FailingRequestRepository implements AssalRepository {
  const _FailingRequestRepository();

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => const AssalSession(
        isAuthenticated: true,
        role: AssalRole.customer,
        user: AssalUserProfile(
          id: 'customer-1',
          nameAr: 'عميل عسلكم',
          role: AssalRole.customer,
        ),
      );

  @override
  Future<AssalLoadState<AssalRequestSummary>> createRequest(
    String requesterId,
    AssalRequestDraft draft,
  ) async => const AssalError<AssalRequestSummary>(
        'تعذر حفظ الطلب من الخادم',
        code: 'request_failed',
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
