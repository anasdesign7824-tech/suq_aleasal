import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/core/assal_widgets.dart';
import 'package:assalkom/features/customer/customer_catalog.dart';

const _profile = AssalUserProfile(
  id: 'user-1',
  nameAr: 'عميل الاختبار',
  email: 'customer@example.com',
);

const _session = AssalSession(
  isAuthenticated: true,
  role: AssalRole.customer,
  user: _profile,
);

const _store = AssalStoreSummary(
  id: 'store-1',
  merchantId: 'merchant-1',
  nameAr: 'مناحل جبال اليمن',
  slug: 'mountain-hives',
  description: 'عسل يمني أصيل من أفضل المناطق الجبلية.',
  regionNameAr: 'إب، اليمن',
  isVerified: true,
  status: StoreStatus.active,
  ratingAverage: 4.8,
  reviewCount: 128,
  followersCount: 2300,
  bio: 'نهتم بالجودة والنقاء في كل قطرة عسل ننتجها.',
);

const _productOne = AssalProductSummary(
  id: 'product-1',
  storeId: 'store-1',
  nameAr: 'عسل السدر الجبلي الفاخر',
  productType: ProductType.honey,
  status: ProductStatus.active,
  subcategoryNameAr: 'عسل السدر',
  price: 15000,
  currencyCode: 'YER',
  weightLabel: '500 جم',
  ratingAverage: 4.8,
  reviewCount: 128,
);

const _productTwo = AssalProductSummary(
  id: 'product-2',
  storeId: 'store-1',
  nameAr: 'عسل الطلح الجبلي',
  productType: ProductType.honey,
  status: ProductStatus.active,
  subcategoryNameAr: 'عسل الطلح',
  price: 13000,
  currencyCode: 'YER',
  weightLabel: '500 جم',
  ratingAverage: 4.6,
  reviewCount: 52,
);

Future<void> _pumpStore(
  WidgetTester tester,
  _StoreRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: StoreProfileScreen(
        repository: repository,
        storeId: _store.id,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 019 renders the source-backed store products grid',
      (tester) async {
    final repository = _StoreRepository();
    await _pumpStore(tester, repository);

    expect(find.text('صفحة المتجر'), findsOneWidget);
    expect(find.text('مناحل جبال اليمن'), findsWidgets);
    expect(find.text('المنتجات'), findsOneWidget);
    expect(find.text('معلومات المتجر'), findsOneWidget);
    expect(find.text('التواصل'), findsOneWidget);
    expect(find.text('عسل السدر الجبلي الفاخر'), findsOneWidget);
    expect(find.text('عسل الطلح الجبلي'), findsOneWidget);
    expect(find.byType(ProductCard), findsNWidgets(2));
    expect(repository.lastQuery?.storeId, 'store-1');
  });

  testWidgets('TASK 019 keeps product cards square and supports real saving',
      (tester) async {
    final repository = _StoreRepository();
    await _pumpStore(tester, repository);

    final ratio = tester.widget<AspectRatio>(find.byType(AspectRatio).first);
    expect(ratio.aspectRatio, 1);
    await tester.tap(find.byTooltip('حفظ المنتج').first);
    await tester.pumpAndSettle();
    expect(repository.favoriteTargetId, 'product-1');
  });

  testWidgets('TASK 019 exposes an empty state with a real alternate action',
      (tester) async {
    final repository =
        _StoreRepository(products: const <AssalProductSummary>[]);
    await _pumpStore(tester, repository);

    expect(
        find.text('لا توجد منتجات منشورة في هذا المتجر بعد.'), findsOneWidget);
    expect(find.text('العودة إلى المتاجر'), findsOneWidget);
    expect(find.byType(ProductCard), findsNothing);
  });

  testWidgets('TASK 019 retries a product source error', (tester) async {
    final repository = _StoreRepository(productsErrorOnce: true);
    await _pumpStore(tester, repository);

    expect(
      find.text('تعذر تحميل البيانات الآن. تحقق من الاتصال ثم أعد المحاولة.'),
      findsOneWidget,
    );
    expect(find.text('إعادة المحاولة'), findsOneWidget);

    await tester.ensureVisible(find.text('إعادة المحاولة'));
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('عسل السدر الجبلي الفاخر'), findsOneWidget);
  });

  testWidgets('TASK 019 opens the real product detail from a store card',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = _StoreRepository();
    await _pumpStore(tester, repository);

    final card = find.byType(ProductCard).first;
    await tester.tap(
      find.descendant(of: card, matching: find.byType(InkWell)).first,
    );
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(find.text('عسل السدر الجبلي الفاخر'), findsWidgets);
  });

  testWidgets('TASK 019 records the store products visual contract',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 2560);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpStore(tester, _StoreRepository());
    await expectLater(
      find.byType(StoreProfileScreen),
      matchesGoldenFile(
        'visual_reference/task019_store_profile_products_reference_360x640.png',
      ),
    );
  });
}

class _StoreRepository implements AssalRepository {
  _StoreRepository({
    this.products = const <AssalProductSummary>[_productOne, _productTwo],
    this.productsErrorOnce = false,
  });

  final AssalSession session = _session;
  final List<AssalProductSummary> products;
  bool productsErrorOnce;
  AssalProductQuery? lastQuery;
  String? favoriteTargetId;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => session;

  @override
  Future<AssalLoadState<AssalStoreSummary>> getStore(String storeId) async =>
      const AssalData(_store);

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({
    AssalProductQuery? query,
  }) async {
    lastQuery = query;
    if (productsErrorOnce) {
      productsErrorOnce = false;
      return const AssalError<List<AssalProductSummary>>(
        'تعذر تحميل البيانات الآن. تحقق من الاتصال ثم أعد المحاولة.',
        kind: AssalErrorKind.network,
        retryable: true,
      );
    }
    return AssalData(products);
  }

  @override
  Future<AssalLoadState<List<AssalStoreSummary>>> listFollowedStores(
    String userId,
  ) async =>
      const AssalData(<AssalStoreSummary>[]);

  @override
  Future<AssalLoadState<bool>> toggleFavorite(
    String userId,
    String targetId,
  ) async {
    favoriteTargetId = targetId;
    return const AssalData(true);
  }

  @override
  Future<AssalLoadState<AssalProductSummary>> getProduct(
    String productId,
  ) async =>
      AssalData(
        products.firstWhere(
          (product) => product.id == productId,
          orElse: () => _productOne,
        ),
      );

  @override
  Future<AssalLoadState<void>> trackProductView(String productId) async =>
      const AssalData<void>(null);

  @override
  Future<AssalLoadState<AssalProductInteractionState>>
      loadProductInteractionState(String userId, String productId) async =>
          const AssalData(AssalProductInteractionState());

  @override
  Future<AssalLoadState<List<AssalReviewSummary>>> listReviews(
    String productId,
  ) async =>
      const AssalEmpty<List<AssalReviewSummary>>('لا توجد مراجعات');

  @override
  Future<AssalLoadState<List<AssalCommentSummary>>> listComments(
    String targetId,
  ) async =>
      const AssalEmpty<List<AssalCommentSummary>>('لا توجد تعليقات');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
