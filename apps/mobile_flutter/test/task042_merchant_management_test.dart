import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/merchant/merchant_dashboard.dart';

class _ManagementRepository implements AssalRepository {
  _ManagementRepository(
      {this.productsErrorOnce = false, this.emptyProducts = false});

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
    followersCount: 13,
    reviewCount: 6,
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
      id: 'product-1',
      storeId: 'store-1',
      nameAr: 'عسل الإدارة',
      productType: ProductType.honey,
      status: ProductStatus.active,
      viewsCount: 31,
      likesCount: 12,
      ratingAverage: 4.6,
      reviewCount: 5,
    ),
    AssalProductSummary(
      id: 'product-2',
      storeId: 'store-1',
      nameAr: 'مسودة الإدارة',
      productType: ProductType.honey,
      status: ProductStatus.draft,
      viewsCount: 3,
      likesCount: 1,
      ratingAverage: 0,
      reviewCount: 0,
    ),
  ];
  static const comment = AssalCommentSummary(
    id: 'comment-1',
    targetId: 'product-1',
    authorId: 'customer-1',
    authorName: 'عميل عسلكم',
    body: 'منتج مميز.',
  );

  final bool productsErrorOnce;
  final bool emptyProducts;
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
        'تعذر تحميل مقاييس المنتجات الآن',
        code: 'metrics_failed',
      );
    }
    return AssalData<List<AssalProductSummary>>(
      emptyProducts ? const [] : products,
    );
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
      const AssalData(<AssalCommentSummary>[comment]);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

Future<void> _pumpManagement(
  WidgetTester tester,
  _ManagementRepository repository,
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
  await tester.tap(find.text('إدارة'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 042 renders management tabs and source states',
      (tester) async {
    await _pumpManagement(tester, _ManagementRepository());

    expect(find.text('المسودات والمراجعة'), findsOneWidget);
    expect(find.text('الإحصاءات'), findsOneWidget);
    expect(find.text('التعليقات'), findsOneWidget);
    expect(find.text('حالة المنتج'), findsOneWidget);
    expect(find.text('المشاهدات'), findsOneWidget);
    expect(find.text('الإعجابات'), findsOneWidget);
    expect(find.text('التقييمات'), findsOneWidget);
  });

  testWidgets('TASK 042 shows status and product metrics from source',
      (tester) async {
    await _pumpManagement(tester, _ManagementRepository());

    await tester.tap(find.text('حالة المنتج'));
    await tester.pumpAndSettle();
    expect(find.text('حالة المنتج: منشور'), findsOneWidget);
    expect(find.text('حالة المنتج: مسودة'), findsOneWidget);

    await tester.ensureVisible(find.text('المشاهدات'));
    await tester.tap(find.text('المشاهدات'));
    await tester.pumpAndSettle();
    expect(find.text('المشاهدات: 31'), findsOneWidget);
    expect(find.text('الإعجابات: 12'), findsNothing);

    await tester.ensureVisible(find.text('التقييمات'));
    await tester.tap(find.text('التقييمات'));
    await tester.pumpAndSettle();
    expect(find.text('التقييم: 4.6'), findsOneWidget);
    expect(find.text('المراجعات: 5'), findsOneWidget);
  });

  testWidgets('TASK 042 renders comments as a real management view',
      (tester) async {
    await _pumpManagement(tester, _ManagementRepository());
    await tester.tap(find.text('التعليقات'));
    await tester.pumpAndSettle();
    expect(find.text('عميل عسلكم'), findsNWidgets(2));
    expect(find.text('منتج مميز.'), findsNWidgets(2));
  });

  testWidgets('TASK 042 exposes retry for metrics source failure',
      (tester) async {
    final repository = _ManagementRepository(productsErrorOnce: true);
    await _pumpManagement(tester, repository);
    await tester.tap(find.text('الإحصاءات'));
    await tester.pumpAndSettle();

    expect(find.text('تعذر تحميل مقاييس المنتجات الآن'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('المشاهدات: 31'), findsOneWidget);
    expect(repository.productCalls, greaterThanOrEqualTo(2));
  });

  testWidgets('TASK 042 shows honest empty management metrics', (tester) async {
    await _pumpManagement(tester, _ManagementRepository(emptyProducts: true));
    await tester.tap(find.text('الإحصاءات'));
    await tester.pumpAndSettle();
    expect(
      find.text('لا توجد منتجات منشورة أو مقاييس متاحة لهذا المتجر بعد.'),
      findsOneWidget,
    );
  });

  testWidgets('TASK 042 records the visual contract', (tester) async {
    await _pumpManagement(tester, _ManagementRepository());
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MerchantDashboard),
      matchesGoldenFile(
        'visual_reference/task042_merchant_management_reference_360x780.png',
      ),
    );
  });
}
