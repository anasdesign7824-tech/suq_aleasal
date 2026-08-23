import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';

import 'package:assalkom/features/customer/customer_catalog.dart';

const _product = AssalProductSummary(
  id: 'product-047',
  storeId: 'store-047',
  nameAr: 'عسل السدر الجبلي الفاخر',
  productType: ProductType.honey,
  status: ProductStatus.active,
  categoryNameAr: 'العسل',
  subcategoryNameAr: 'سدر',
  price: 15000,
  currencyCode: 'YER',
  availability: 'متوفر',
  deliveryOptions: ['توصيل داخل المدينة'],
  pickupLocations: ['نقطة استلام المتجر'],
  ratingAverage: 4.8,
  reviewCount: 12,
  likesCount: 7,
);

const _store = AssalStoreSummary(
  id: 'store-047',
  merchantId: 'merchant-047',
  nameAr: 'متجر السدر الجبلي',
  slug: 'mountain-sidr',
  status: StoreStatus.active,
  regionNameAr: 'صنعاء',
  deliveryOptions: ['توصيل داخل المدينة'],
  pickupLocations: ['نقطة استلام المتجر'],
);

Future<void> _pumpPreview(
  WidgetTester tester, {
  bool merchantMode = false,
  Future<void> Function()? onEdit,
  bool usePhoneSurface = true,
}) async {
  if (usePhoneSurface) {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }
  await tester.pumpWidget(
    MaterialApp(
      home: ProductDetailScreen(
        repository: const _PreviewRepository(),
        productId: _product.id,
        initialProduct: _product,
        merchantMode: merchantMode,
        onEdit: onEdit,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 047 يعرض معاينة المنتج الموحدة للعميل', (tester) async {
    await _pumpPreview(tester);

    expect(find.text('عسل السدر الجبلي الفاخر'), findsAtLeastNWidgets(1));
    expect(find.text('15,000 ريال يمني'), findsOneWidget);
    expect(find.text('متوفر'), findsOneWidget);
    expect(find.text('اسأل عن التوفر'), findsOneWidget);
    expect(find.text('تعديل المنتج'), findsNothing);
    expect(find.textContaining('التوصيل: توصيل داخل المدينة'), findsOneWidget);
    final previewScroll = find.byType(Scrollable).first;
    await tester.drag(previewScroll, const Offset(0, -520));
    await tester.pumpAndSettle();
    expect(find.text('معلومات المنتج'), findsOneWidget);
    expect(find.text('التقييمات والتفاعل'), findsOneWidget);
    expect(find.text('منتجات مشابهة'), findsOneWidget);
    expect(
        tester.widget<AspectRatio>(find.byType(AspectRatio).first).aspectRatio,
        1);
  });

  testWidgets('TASK 047 يضيف تعديل التاجر إلى نفس المعاينة ويربطه بفعل حقيقي',
      (tester) async {
    var editPressed = false;
    await _pumpPreview(
      tester,
      merchantMode: true,
      onEdit: () async {
        editPressed = true;
      },
    );

    expect(find.text('تعديل المنتج'), findsOneWidget);
    final previewScroll = find.byType(Scrollable).first;
    await tester.drag(previewScroll, const Offset(0, -220));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تعديل المنتج'));
    await tester.pumpAndSettle();
    expect(editPressed, isTrue);
  });

  testWidgets('TASK 047 records the visual contract', (tester) async {
    await _pumpPreview(
      tester,
      merchantMode: true,
      onEdit: () async {},
      usePhoneSurface: false,
    );
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ProductDetailScreen),
      matchesGoldenFile(
        'visual_reference/task047_product_preview_merchant_reference_360x780.png',
      ),
    );
  });
}

class _PreviewRepository implements AssalRepository {
  const _PreviewRepository();

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => AssalSession.guest;

  @override
  Future<AssalLoadState<void>> trackProductView(String productId) async =>
      const AssalData<void>(null);

  @override
  Future<AssalLoadState<AssalStoreSummary>> getStore(String storeId) async =>
      const AssalData(_store);

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({
    AssalProductQuery query = const AssalProductQuery(),
  }) async =>
      const AssalData(<AssalProductSummary>[]);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
