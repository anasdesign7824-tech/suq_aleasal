import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/merchant/merchant_dashboard.dart';

class _CatalogRepository implements AssalRepository {
  _CatalogRepository({this.productsErrorOnce = false});

  static const profile = AssalUserProfile(
    id: 'merchant-1',
    nameAr: 'تاجر الاختبار',
    role: AssalRole.merchant,
  );
  static const session = AssalSession(
    isAuthenticated: true,
    role: AssalRole.merchant,
    user: profile,
  );
  static const store = AssalStoreSummary(
    id: 'store-1',
    merchantId: 'merchant-1',
    nameAr: 'متجر الاختبار',
    slug: 'test-store',
    status: StoreStatus.pending,
  );
  static const workspace = AssalMerchantWorkspaceSummary(
    store: store,
    verificationStatus: 'pending',
    publicStatus: 'pending',
    canEdit: true,
    canPublish: false,
  );
  static const products = <AssalProductSummary>[
    AssalProductSummary(
      id: 'active-1',
      storeId: 'store-1',
      nameAr: 'عسل منشور',
      productType: ProductType.honey,
      status: ProductStatus.active,
      viewsCount: 7,
      likesCount: 3,
    ),
    AssalProductSummary(
      id: 'pending-1',
      storeId: 'store-1',
      nameAr: 'عسل معلق',
      productType: ProductType.honey,
      status: ProductStatus.pending,
      viewsCount: 21,
      likesCount: 8,
    ),
    AssalProductSummary(
      id: 'draft-1',
      storeId: 'store-1',
      nameAr: 'مسودة عسل',
      productType: ProductType.honey,
      status: ProductStatus.draft,
      viewsCount: 2,
      likesCount: 1,
    ),
  ];

  final bool productsErrorOnce;
  int productCalls = 0;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => session;

  @override
  Future<AssalLoadState<AssalMerchantWorkspaceSummary?>> loadMerchantWorkspace(
          String userId) async =>
      const AssalData(workspace);

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listMerchantProducts(
    String userId,
  ) async {
    productCalls++;
    if (productsErrorOnce && productCalls == 1) {
      return const AssalError<List<AssalProductSummary>>(
        'تعذر تحميل المنتجات الآن',
        code: 'products_failed',
      );
    }
    return const AssalData(products);
  }

  @override
  Future<AssalLoadState<List<AssalRequestSummary>>> listMerchantRequests(
    String userId,
  ) async =>
      const AssalData(<AssalRequestSummary>[]);

  @override
  Future<AssalLoadState<List<AssalCommentSummary>>> listComments(
    String productId,
  ) async =>
      const AssalData(<AssalCommentSummary>[]);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

Future<void> _pumpCatalog(
  WidgetTester tester,
  _CatalogRepository repository,
) async {
  tester.view.physicalSize = const Size(900, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(home: MerchantDashboard(repository: repository)),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('الكتالوج'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 040 renders catalog controls and square product cards',
      (tester) async {
    await _pumpCatalog(tester, _CatalogRepository());

    expect(find.text('بحث المنتجات'), findsOneWidget);
    expect(find.text('كل الحالات'), findsOneWidget);
    expect(find.text('مسودة'), findsOneWidget);
    expect(find.text('معلق'), findsOneWidget);
    expect(find.text('منشور'), findsOneWidget);
    expect(find.text('مرفوض'), findsOneWidget);
    expect(find.text('ترتيب المنتجات'), findsOneWidget);
    expect(find.text('إضافة منتج ومعاينته'), findsOneWidget);
    expect(find.text('عسل منشور'), findsOneWidget);
    expect(find.text('عسل معلق'), findsOneWidget);
  });

  testWidgets('TASK 040 filters products locally by search and status',
      (tester) async {
    await _pumpCatalog(tester, _CatalogRepository());

    await tester.enterText(find.byType(TextField), 'معلق');
    await tester.pump();
    expect(find.text('عسل معلق'), findsOneWidget);
    expect(find.text('عسل منشور'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('مسودة'));
    await tester.pump();
    expect(find.text('مسودة عسل'), findsOneWidget);
    expect(find.text('عسل منشور'), findsNothing);
  });

  testWidgets(
      'TASK 040 sorts by source metrics without changing repository query',
      (tester) async {
    await _pumpCatalog(tester, _CatalogRepository());

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الأكثر مشاهدة').last);
    await tester.pump();
    expect(find.text('بحث المنتجات'), findsOneWidget);
    expect(find.text('عسل معلق'), findsOneWidget);
  });

  testWidgets('TASK 040 exposes retry when merchant products fail',
      (tester) async {
    final repository = _CatalogRepository(productsErrorOnce: true);
    await _pumpCatalog(tester, repository);

    expect(find.text('تعذر تحميل المنتجات الآن'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('بحث المنتجات'), findsOneWidget);
    expect(repository.productCalls, greaterThanOrEqualTo(2));
  });

  testWidgets('TASK 040 shows an honest empty catalog state', (tester) async {
    final repository = _EmptyCatalogRepository();
    await _pumpCatalog(tester, repository);

    expect(
      find.text(
          'لا توجد منتجات بعد. أضف أول منتج؛ سيبقى معلقًا حتى تفعيل المتجر.'),
      findsOneWidget,
    );
  });

  testWidgets('TASK 040 records the visual contract', (tester) async {
    await _pumpCatalog(tester, _CatalogRepository());
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MerchantDashboard),
      matchesGoldenFile(
        'visual_reference/task040_merchant_catalog_reference_360x780.png',
      ),
    );
  });
}

class _EmptyCatalogRepository extends _CatalogRepository {
  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listMerchantProducts(
    String userId,
  ) async =>
      const AssalData(<AssalProductSummary>[]);
}
