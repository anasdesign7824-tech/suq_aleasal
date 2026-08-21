import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/merchant/merchant_dashboard.dart';

void main() {
  testWidgets('merchant analytics renders real product metrics', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MerchantDashboard(repository: _AnalyticsRepository()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('الإحصاءات'));
    await tester.pumpAndSettle();
    expect(find.text('متابعو المتجر'), findsOneWidget);
    expect(find.text('المشاهدات: 11'), findsOneWidget);
    expect(find.text('الإعجابات: 7'), findsOneWidget);
    expect(find.text('التقييم: 4.7'), findsOneWidget);
    expect(find.text('المراجعات: 3'), findsOneWidget);
    expect(find.text('2 متابع للمتجر'), findsNothing);
  });
}

class _AnalyticsRepository implements AssalRepository {
  static const _profile = AssalUserProfile(
    id: 'merchant-1',
    nameAr: 'تاجر الاختبار',
    role: AssalRole.merchant,
  );
  static const _session = AssalSession(
    isAuthenticated: true,
    role: AssalRole.merchant,
    user: _profile,
  );
  static const _store = AssalStoreSummary(
    id: 'store-1',
    merchantId: 'merchant-1',
    nameAr: 'متجر التحليلات',
    slug: 'analytics-store',
    status: StoreStatus.active,
    followersCount: 2,
    reviewCount: 4,
  );
  static const _workspace = AssalMerchantWorkspaceSummary(
    store: _store,
    verificationStatus: 'not_requested',
    publicStatus: 'active',
    canPublish: true,
  );
  static const _product = AssalProductSummary(
    id: 'product-1',
    storeId: 'store-1',
    nameAr: 'عسل إحصائي',
    productType: ProductType.honey,
    status: ProductStatus.active,
    viewsCount: 11,
    likesCount: 7,
    ratingAverage: 4.7,
    reviewCount: 3,
  );

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => _session;

  @override
  Future<AssalLoadState<AssalMerchantWorkspaceSummary?>>
      loadMerchantWorkspace(String userId) async => const AssalData(_workspace);

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listMerchantProducts(
    String userId,
  ) async => const AssalData([_product]);

  @override
  Future<AssalLoadState<List<AssalRequestSummary>>> listMerchantRequests(
    String userId,
  ) async => const AssalData(<AssalRequestSummary>[]);

  @override
  Future<AssalLoadState<List<AssalCommentSummary>>> listComments(
    String productId,
  ) async => const AssalData(<AssalCommentSummary>[]);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
