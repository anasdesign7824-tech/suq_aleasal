import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_catalog.dart';

const _product = AssalProductSummary(
  id: 'product-1',
  storeId: 'store-1',
  nameAr: 'عسل السدر الجبلي الفاخر',
  productType: ProductType.honey,
  status: ProductStatus.active,
  categoryNameAr: 'عسل السدر',
  subcategoryNameAr: 'عسل طبيعي',
  price: 15000,
  currencyCode: 'YER',
  availability: 'متوفر',
  deliveryOptions: ['توصيل إلى باب البيت'],
  pickupLocations: ['استلام من نقاط البيع'],
  ratingAverage: 4.8,
  reviewCount: 128,
  likesCount: 2300,
  regionNameAr: 'إب، اليمن',
  honeyIdentity: 'عسل السدر الجبلي الفاخر',
  qualityLabelAr: 'عسل خام 100% — غير مبستر',
  weightLabel: '500 جم',
  components: ['عسل نحل طبيعي 100%'],
);

const _store = AssalStoreSummary(
  id: 'store-1',
  merchantId: 'merchant-1',
  nameAr: 'مناحل جبال اليمن',
  slug: 'mountain-hives',
  status: StoreStatus.active,
  regionNameAr: 'إب، اليمن',
  isVerified: true,
  followersCount: 2300,
  ratingAverage: 4.8,
  reviewCount: 156,
  deliveryOptions: ['توصيل إلى باب البيت'],
  pickupLocations: ['استلام من نقاط البيع'],
);

Future<void> _pumpProduct(
  WidgetTester tester, {
  bool useInitialProduct = true,
  bool failFirstProductLoad = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ProductDetailScreen(
        repository: _ProductRepository(
          product: _product,
          store: _store,
          failFirstProductLoad: failFirstProductLoad,
        ),
        productId: _product.id,
        initialProduct: useInitialProduct ? _product : null,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 015 renders the source-backed product overview',
      (tester) async {
    await _pumpProduct(tester);

    expect(find.text('تفاصيل المنتج'), findsOneWidget);
    expect(find.text('عسل السدر الجبلي الفاخر'), findsWidgets);
    expect(find.text('عسل السدر'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('128 مراجعة'), findsOneWidget);
    expect(find.text('2300 إعجاب'), findsOneWidget);
    expect(find.byTooltip('حفظ المنتج'), findsOneWidget);
    await tester.drag(
      find.byType(NestedScrollView),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    expect(find.text('خيارات التوفر والاستلام'), findsOneWidget);
    expect(find.text('متوفر'), findsOneWidget);
    expect(find.text('15,000 ريال يمني'), findsOneWidget);
    expect(find.textContaining('التوصيل: توصيل إلى باب البيت'), findsOneWidget);
    expect(
        find.textContaining('الاستلام: استلام من نقاط البيع'), findsOneWidget);
    expect(find.text('اسأل عن التوفر'), findsOneWidget);
    expect(find.text('معلومات المنتج'), findsOneWidget);
    expect(find.text('التقييمات والتفاعل'), findsOneWidget);
    expect(find.text('منتجات مشابهة'), findsOneWidget);
    expect(find.text('بيانات المصدر والجودة'), findsOneWidget);
    expect(find.text('نوع المنتج'), findsOneWidget);
    expect(find.text('المكونات'), findsOneWidget);
    expect(find.text('عسل نحل طبيعي 100%'), findsOneWidget);
    expect(find.text('مناحل جبال اليمن'), findsWidgets);

    final heroRatio =
        tester.widget<AspectRatio>(find.byType(AspectRatio).first);
    expect(heroRatio.aspectRatio, 1);
  });

  testWidgets('TASK 015 exposes the real share action', (tester) async {
    await _pumpProduct(tester);

    await tester.tap(find.byTooltip('مشاركة'));
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('TASK 015 recovers product source errors with retry',
      (tester) async {
    await _pumpProduct(
      tester,
      useInitialProduct: false,
      failFirstProductLoad: true,
    );

    expect(
        find.text('تعذر تحميل البيانات الآن. تحقق من الاتصال ثم أعد المحاولة.'),
        findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('عسل السدر الجبلي الفاخر'), findsWidgets);
  });

  testWidgets('TASK 015 records the product overview visual contract',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 2560);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpProduct(tester);
    await expectLater(
      find.byType(ProductDetailScreen),
      matchesGoldenFile(
        'visual_reference/task015_product_detail_overview_reference_360x640.png',
      ),
    );
  });
}

class _ProductRepository implements AssalRepository {
  _ProductRepository({
    required this.product,
    required this.store,
    this.failFirstProductLoad = false,
  });

  final AssalProductSummary product;
  final AssalStoreSummary store;
  final bool failFirstProductLoad;
  int productLoadCalls = 0;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => AssalSession.guest;

  @override
  Future<AssalLoadState<void>> trackProductView(String productId) async =>
      const AssalData<void>(null);

  @override
  Future<AssalLoadState<AssalProductSummary>> getProduct(
      String productId) async {
    if (failFirstProductLoad && productLoadCalls++ == 0) {
      throw StateError('offline');
    }
    return AssalData(product);
  }

  @override
  Future<AssalLoadState<AssalStoreSummary>> getStore(String storeId) async =>
      AssalData(store);

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({
    AssalProductQuery query = const AssalProductQuery(),
  }) async =>
      const AssalData(<AssalProductSummary>[]);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
