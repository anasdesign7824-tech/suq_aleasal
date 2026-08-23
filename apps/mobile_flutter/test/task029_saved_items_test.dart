import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_catalog.dart';
import 'package:assalkom/features/customer/customer_favorites.dart';
import 'package:assalkom/core/assal_widgets.dart';

const _customer = AssalUserProfile(
  id: 'customer-1',
  nameAr: 'عميل عسلكم',
  role: AssalRole.customer,
);

const _store = AssalStoreSummary(
  id: 'store-1',
  merchantId: 'merchant-1',
  nameAr: 'مناحل جبال اليمن',
  slug: 'yemen-mountains-honey',
);

const _product = AssalProductSummary(
  id: 'product-1',
  storeId: 'store-1',
  nameAr: 'عسل السدر الجبلي',
  productType: ProductType.honey,
  status: ProductStatus.active,
  categoryNameAr: 'العسل',
  primaryImageUrl: null,
);

Future<void> _pumpFavorites(
  WidgetTester tester,
  _FavoritesRepository repository,
) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(home: FavoritesScreen(repository: repository)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 029 renders saved products and stores from source',
      (tester) async {
    final repository = _FavoritesRepository();
    await _pumpFavorites(tester, repository);

    expect(find.text('المحفوظات والمتابعات'), findsOneWidget);
    expect(find.text('منتجات محفوظة'), findsOneWidget);
    expect(find.text('متاجر متابَعة'), findsOneWidget);
    expect(find.text('عسل السدر الجبلي'), findsOneWidget);
    expect(find.byType(ProductCard), findsOneWidget);
    expect(repository.loadedUserId, 'customer-1');
  });

  testWidgets('TASK 029 opens product details from saved product',
      (tester) async {
    await _pumpFavorites(tester, _FavoritesRepository());

    await tester.tap(find.text('عسل السدر الجبلي'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailScreen), findsOneWidget);
  });

  testWidgets('TASK 029 removes a saved product and refreshes source',
      (tester) async {
    final repository = _FavoritesRepository();
    await _pumpFavorites(tester, repository);

    await tester.tap(find.byTooltip('إزالة الحفظ'));
    await tester.pumpAndSettle();
    expect(repository.toggledFavoriteId, 'product-1');
    expect(find.text('تمت إزالة المنتج من المحفوظات.'), findsOneWidget);
  });

  testWidgets('TASK 029 shows empty guidance with real explore action',
      (tester) async {
    await _pumpFavorites(
      tester,
      _FavoritesRepository(products: const <AssalProductSummary>[]),
    );

    expect(find.text('لم تحفظ شيئًا بعد.'), findsOneWidget);
    expect(find.text('استكشف المنتجات'), findsOneWidget);
    await tester.tap(find.text('استكشف المنتجات'));
    await tester.pumpAndSettle();
    expect(find.text('البحث عن منتجات'), findsOneWidget);
  });

  testWidgets('TASK 029 retries a saved products source error', (tester) async {
    final repository = _FavoritesRepository(productErrorOnce: true);
    await _pumpFavorites(tester, repository);

    expect(find.text('تعذر تحميل المحفوظات الآن.'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('عسل السدر الجبلي'), findsOneWidget);
    expect(repository.productCalls, 2);
  });

  testWidgets('TASK 029 gates favorites behind the real session',
      (tester) async {
    await _pumpFavorites(tester, _FavoritesRepository(authenticated: false));

    expect(find.text('تسجيل الدخول لعرض محفوظاتك'), findsOneWidget);
    expect(find.text('منتجات محفوظة'), findsNothing);
  });

  testWidgets('TASK 029 records the saved-items visual contract',
      (tester) async {
    await _pumpFavorites(tester, _FavoritesRepository());
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(FavoritesScreen),
      matchesGoldenFile(
        'visual_reference/task029_saved_items_reference_360x780.png',
      ),
    );
  });
}

class _FavoritesRepository implements AssalRepository {
  _FavoritesRepository({
    List<AssalProductSummary>? products,
    this.productErrorOnce = false,
    this.authenticated = true,
  }) : products = products ?? const <AssalProductSummary>[_product];

  final List<AssalProductSummary> products;
  bool productErrorOnce;
  final bool authenticated;
  String? loadedUserId;
  String? toggledFavoriteId;
  int productCalls = 0;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => authenticated
      ? const AssalSession(
          isAuthenticated: true,
          role: AssalRole.customer,
          user: _customer,
        )
      : AssalSession.guest;

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listFavoriteProducts(
    String userId,
  ) async {
    loadedUserId = userId;
    productCalls++;
    if (productErrorOnce) {
      productErrorOnce = false;
      return const AssalError<List<AssalProductSummary>>(
        'تعذر تحميل المحفوظات الآن.',
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
      const AssalData(<AssalStoreSummary>[_store]);

  @override
  Future<AssalLoadState<List<AssalTaxonomy>>> listFavoriteTaxonomies(
    String userId,
  ) async =>
      const AssalData(<AssalTaxonomy>[]);

  @override
  Future<AssalLoadState<bool>> toggleFavorite(
    String userId,
    String targetId,
  ) async {
    toggledFavoriteId = targetId;
    return const AssalData(false);
  }

  @override
  Future<AssalLoadState<void>> trackProductView(String productId) async =>
      const AssalData<void>(null);

  @override
  Future<AssalLoadState<AssalProductInteractionState>>
      loadProductInteractionState(String userId, String productId) async =>
          const AssalData(AssalProductInteractionState());

  @override
  Future<AssalLoadState<AssalProductSummary>> getProduct(
          String productId) async =>
      const AssalData(_product);

  @override
  Future<AssalLoadState<AssalStoreSummary>> getStore(String storeId) async =>
      const AssalData(_store);

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({
    AssalProductQuery? query,
  }) async =>
      const AssalData(<AssalProductSummary>[]);

  @override
  Future<AssalLoadState<List<AssalStoreSummary>>> listStores({
    String? regionId,
  }) async =>
      const AssalData(<AssalStoreSummary>[]);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
