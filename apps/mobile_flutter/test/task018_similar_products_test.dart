import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_catalog.dart';
import 'package:assalkom/core/assal_widgets.dart';

const _product = AssalProductSummary(
  id: 'product-1',
  storeId: 'store-1',
  nameAr: 'عسل السدر الجبلي الفاخر',
  productType: ProductType.honey,
  status: ProductStatus.active,
  taxonomyId: 'subcategory-sidr',
  categoryNameAr: 'العسل السائل',
  subcategoryNameAr: 'عسل السدر',
  price: 15000,
  currencyCode: 'YER',
  ratingAverage: 4.8,
  reviewCount: 128,
);

const _similar = AssalProductSummary(
  id: 'product-2',
  storeId: 'store-1',
  nameAr: 'عسل السدر الحضرمي',
  productType: ProductType.honey,
  status: ProductStatus.active,
  taxonomyId: 'subcategory-sidr',
  categoryNameAr: 'العسل السائل',
  subcategoryNameAr: 'عسل السدر',
  price: 12000,
  currencyCode: 'YER',
  ratingAverage: 4.6,
  reviewCount: 42,
);

const _store = AssalStoreSummary(
  id: 'store-1',
  merchantId: 'merchant-1',
  nameAr: 'مناحل جبال اليمن',
  slug: 'mountain-hives',
  status: StoreStatus.active,
);

Future<void> _pumpSimilar(
  WidgetTester tester,
  _SimilarRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ProductDetailScreen(
        repository: repository,
        productId: _product.id,
        initialProduct: _product,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.drag(
    find.byType(NestedScrollView),
    const Offset(0, -1500),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('منتجات مشابهة'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('منتجات مشابهة'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 018 renders source-backed similar products as square cards',
      (tester) async {
    final repository = _SimilarRepository();
    await _pumpSimilar(tester, repository);

    expect(find.text('المنتجات المشابهة'), findsOneWidget);
    expect(find.text('عسل السدر الحضرمي'), findsOneWidget);
    expect(find.text('12,000 ريال يمني'), findsOneWidget);
    expect(find.byType(ProductCard), findsOneWidget);
    final ratio = tester.widget<AspectRatio>(find.byType(AspectRatio).last);
    expect(ratio.aspectRatio, 1);
    expect(repository.lastQuery?.subcategoryId, 'subcategory-sidr');
  });

  testWidgets(
      'TASK 018 excludes the current product and retries an empty source',
      (tester) async {
    final repository = _SimilarRepository(includeSimilar: false);
    await _pumpSimilar(tester, repository);

    expect(find.text('لا توجد منتجات مشابهة منشورة بعد.'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    expect(find.text('عسل السدر الحضرمي'), findsNothing);

    repository.includeSimilar = true;
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('عسل السدر الحضرمي'), findsOneWidget);
  });

  testWidgets('TASK 018 retries a source error and then renders the result',
      (tester) async {
    final repository = _SimilarRepository(throwOnSimilar: true);
    await _pumpSimilar(tester, repository);

    expect(
      find.text(
        'تعذر تحميل المنتجات المشابهة الآن. تحقق من الاتصال ثم أعد المحاولة.',
      ),
      findsOneWidget,
    );
    expect(find.text('إعادة المحاولة'), findsOneWidget);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('عسل السدر الحضرمي'), findsOneWidget);
  });

  testWidgets('TASK 018 opens the real product detail from a similar card',
      (tester) async {
    final repository = _SimilarRepository();
    await _pumpSimilar(tester, repository);

    await tester.tap(find.text('عسل السدر الحضرمي'));
    await tester.pumpAndSettle();
    expect(find.text('عسل السدر الحضرمي'), findsOneWidget);
    expect(find.byType(ProductDetailScreen), findsOneWidget);
  });

  testWidgets('TASK 018 records the similar products visual contract',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpSimilar(tester, _SimilarRepository());
    await expectLater(
      find.byType(ProductDetailScreen),
      matchesGoldenFile(
        'visual_reference/task018_similar_products_reference_360x780.png',
      ),
    );
  });
}

class _SimilarRepository implements AssalRepository {
  _SimilarRepository({
    this.includeSimilar = true,
    this.throwOnSimilar = false,
  });

  final session = const AssalSession(
    isAuthenticated: false,
    role: AssalRole.guest,
  );
  bool includeSimilar;
  bool throwOnSimilar;
  AssalProductQuery? lastQuery;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => session;

  @override
  Future<AssalLoadState<void>> trackProductView(String productId) async =>
      const AssalData<void>(null);

  @override
  Future<AssalLoadState<AssalStoreSummary>> getStore(String storeId) async =>
      const AssalData(_store);

  @override
  Future<AssalLoadState<AssalProductSummary>> getProduct(
          String productId) async =>
      AssalData(productId == _similar.id ? _similar : _product);

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({
    AssalProductQuery? query,
  }) async {
    lastQuery = query;
    if (throwOnSimilar) {
      throwOnSimilar = false;
      return const AssalError<List<AssalProductSummary>>(
        'تعذر تحميل المنتجات المشابهة الآن. تحقق من الاتصال ثم أعد المحاولة.',
        kind: AssalErrorKind.network,
        retryable: true,
      );
    }
    return AssalData(
      includeSimilar
          ? <AssalProductSummary>[_product, _similar]
          : <AssalProductSummary>[_product],
    );
  }

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
  Future<AssalLoadState<AssalProductInteractionState>>
      loadProductInteractionState(String userId, String productId) async =>
          const AssalData(AssalProductInteractionState());

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
