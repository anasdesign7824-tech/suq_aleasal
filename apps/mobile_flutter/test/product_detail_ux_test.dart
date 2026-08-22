import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';

import 'package:assalkom/features/customer/customer_catalog.dart';

void main() {
  testWidgets('product detail exposes decision information and CTA',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const product = AssalProductSummary(
      id: 'product-1',
      storeId: 'store-1',
      nameAr: 'عسل سدر يمني',
      productType: ProductType.honey,
      status: ProductStatus.active,
      categoryNameAr: 'العسل',
      subcategoryNameAr: 'سدر',
      price: 180,
      currencyCode: 'YER',
      availability: 'متاح للاستفسار',
      deliveryOptions: ['شركة توصيل'],
      pickupLocations: ['نقطة استلام صنعاء'],
      ratingAverage: 4.5,
      reviewCount: 8,
    );
    const store = AssalStoreSummary(
      id: 'store-1',
      merchantId: 'merchant-1',
      nameAr: 'متجر العسل',
      slug: 'honey-store',
      status: StoreStatus.active,
      regionNameAr: 'صنعاء',
      deliveryOptions: ['شركة توصيل'],
      pickupLocations: ['نقطة استلام صنعاء'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailScreen(
          repository: const _ProductRepository(store),
          productId: product.id,
          initialProduct: product,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('180 ريال يمني'), findsOneWidget);
    expect(find.text('متاح للاستفسار'), findsOneWidget);
    expect(find.textContaining('التوصيل: شركة توصيل'), findsOneWidget);
    expect(find.text('اسأل عن التوفر'), findsOneWidget);
    expect(find.text('صنعاء'), findsAtLeastNWidgets(1));
    final heroRatio = tester.widget<AspectRatio>(find.byType(AspectRatio).first);
    expect(heroRatio.aspectRatio, 1);

  });
}

class _ProductRepository implements AssalRepository {
  const _ProductRepository(this.store);

  final AssalStoreSummary store;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => AssalSession.guest;

  @override
  Future<AssalLoadState<void>> trackProductView(String productId) async =>
      const AssalData<void>(null);

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
