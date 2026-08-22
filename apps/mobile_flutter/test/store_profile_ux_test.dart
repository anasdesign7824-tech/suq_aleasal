import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';

import 'package:assalkom/features/customer/customer_catalog.dart';

void main() {
  testWidgets('store profile groups public channels and handoff options',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const store = AssalStoreSummary(
      id: 'store-1',
      merchantId: 'merchant-1',
      nameAr: 'متجر العسل',
      slug: 'honey-store',
      status: StoreStatus.active,
      socialLinks: {
        'whatsapp': 'https://wa.me/967711111111',
        'website': 'https://assalkom.example',
      },
      contactWhatsapp: 'https://wa.me/967711111111',
      deliveryOptions: ['شركة توصيل'],
      pickupLocations: ['نقطة استلام صنعاء'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StoreProfileScreen(
          repository: const _StoreRepository(store),
          storeId: store.id,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final contactTab = find.text('التواصل');
    await tester.ensureVisible(contactTab);
    await tester.tap(contactTab);
    await tester.pumpAndSettle();

    expect(find.text('قنوات التواصل'), findsOneWidget);
    expect(find.text('واتساب'), findsOneWidget);
    expect(find.text('الموقع الإلكتروني'), findsOneWidget);
    expect(find.text('التسليم والاستلام'), findsOneWidget);
    expect(find.text('شركة توصيل'), findsOneWidget);
    expect(find.text('نقطة استلام صنعاء'), findsOneWidget);
    expect(find.text('مراسلة التاجر'), findsOneWidget);
  });
}

class _StoreRepository implements AssalRepository {
  const _StoreRepository(this.store);

  final AssalStoreSummary store;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => AssalSession.guest;

  @override
  Future<AssalLoadState<AssalStoreSummary>> getStore(String storeId) async =>
      AssalData(store);

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({
    AssalProductQuery query = const AssalProductQuery(),
  }) async => const AssalData(<AssalProductSummary>[]);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
