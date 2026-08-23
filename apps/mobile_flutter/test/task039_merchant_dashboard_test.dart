import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/merchant/merchant_dashboard.dart';

class _DashboardRepository implements AssalRepository {
  _DashboardRepository({this.errorOnce = false, this.emptyWorkspace = false});

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
    followersCount: 8,
    reviewCount: 3,
  );
  static const workspace = AssalMerchantWorkspaceSummary(
    store: store,
    verificationStatus: 'pending',
    publicStatus: 'pending',
    canEdit: true,
    canPublish: false,
  );
  static const product = AssalProductSummary(
    id: 'product-1',
    storeId: 'store-1',
    nameAr: 'عسل الاختبار',
    productType: ProductType.honey,
    status: ProductStatus.active,
    viewsCount: 21,
    likesCount: 9,
    ratingAverage: 4.8,
    reviewCount: 4,
  );

  final bool errorOnce;
  final bool emptyWorkspace;
  int workspaceCalls = 0;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => session;

  @override
  Future<AssalLoadState<AssalMerchantWorkspaceSummary?>> loadMerchantWorkspace(
      String userId) async {
    workspaceCalls++;
    if (errorOnce && workspaceCalls == 1) {
      return const AssalError<AssalMerchantWorkspaceSummary?>(
        'تعذر تحميل البيانات الآن',
        code: 'load_failed',
      );
    }
    return AssalData<AssalMerchantWorkspaceSummary?>(
      emptyWorkspace ? null : workspace,
    );
  }

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listMerchantProducts(
    String userId,
  ) async =>
      const AssalData([product]);

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

Future<void> _pumpDashboard(
  WidgetTester tester,
  _DashboardRepository repository,
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
}

void main() {
  testWidgets('TASK 039 renders unified merchant tabs and source metrics',
      (tester) async {
    await _pumpDashboard(tester, _DashboardRepository());

    expect(find.text('لوحة التاجر'), findsOneWidget);
    expect(find.text('نظرة عامة'), findsOneWidget);
    expect(find.text('الكتالوج'), findsOneWidget);
    expect(find.text('الطلبات'), findsOneWidget);
    expect(find.text('إدارة'), findsOneWidget);
    expect(find.text('مساحة متجرك جاهزة للتحرير'), findsOneWidget);
    expect(find.text('متجرك مفعّل'), findsNothing);
    expect(find.text('تعديل بيانات المتجر والصور'), findsOneWidget);
    await tester.tap(find.text('الكتالوج'));
    await tester.pumpAndSettle();
    expect(find.text('إضافة منتج ومعاينته'), findsOneWidget);
  });

  testWidgets('TASK 039 shows analytics and pending management choices',
      (tester) async {
    await _pumpDashboard(tester, _DashboardRepository());

    await tester.tap(find.text('إدارة'));
    await tester.pumpAndSettle();
    expect(find.text('المسودات والمراجعة'), findsOneWidget);
    expect(find.text('الإحصاءات'), findsOneWidget);
    expect(find.text('التعليقات'), findsOneWidget);

    await tester.tap(find.text('الإحصاءات'));
    await tester.pumpAndSettle();
    expect(find.text('متابعو المتجر'), findsOneWidget);
    expect(find.text('المشاهدات: 21'), findsOneWidget);
    expect(find.text('الإعجابات: 9'), findsOneWidget);
    expect(find.text('التقييم: 4.8'), findsOneWidget);
    expect(find.text('المراجعات: 4'), findsOneWidget);
  });

  testWidgets('TASK 039 exposes retry for workspace source errors',
      (tester) async {
    final repository = _DashboardRepository(errorOnce: true);
    await _pumpDashboard(tester, repository);

    expect(find.text('تعذر تحميل البيانات الآن'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('مساحة متجرك جاهزة للتحرير'), findsOneWidget);
    expect(repository.workspaceCalls, 2);
  });

  testWidgets('TASK 039 shows the empty workspace state with refresh action',
      (tester) async {
    final repository = _DashboardRepository(emptyWorkspace: true);
    await _pumpDashboard(tester, repository);

    expect(find.textContaining('لم تُفتح مساحة متجر لهذا الحساب بعد'),
        findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('TASK 039 refreshes all dashboard sources from the toolbar',
      (tester) async {
    final repository = _DashboardRepository();
    await _pumpDashboard(tester, repository);
    final before = repository.workspaceCalls;

    await tester.tap(find.byTooltip('تحديث بيانات المتجر'));
    await tester.pumpAndSettle();
    expect(repository.workspaceCalls, greaterThan(before));
  });

  testWidgets('TASK 039 records the visual contract', (tester) async {
    await _pumpDashboard(tester, _DashboardRepository());
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MerchantDashboard),
      matchesGoldenFile(
        'visual_reference/task039_merchant_dashboard_reference_360x780.png',
      ),
    );
  });
}
