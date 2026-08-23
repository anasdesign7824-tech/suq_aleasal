import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/core/assal_widgets.dart';
import 'package:assalkom/features/customer/customer_account.dart';
import 'package:assalkom/features/customer/customer_favorites.dart';

const _user = AssalUserProfile(
  id: 'customer-1',
  nameAr: 'محمد اليمني',
  email: 'mohammed@example.com',
  phone: '+967700000000',
  location: 'إب، اليمن',
  bio: 'أحرص على اختيار أفضل المنتجات النحلية الطبيعية.',
  followersCount: 18,
  followingCount: 56,
);

const _store = AssalStoreSummary(
  id: 'store-1',
  merchantId: 'merchant-1',
  nameAr: 'مناحل جبال اليمن',
  slug: 'yemen-mountains-honey',
  followersCount: 24,
);

const _product = AssalProductSummary(
  id: 'product-1',
  storeId: 'store-1',
  nameAr: 'عسل السدر الجبلي',
  productType: ProductType.honey,
  status: ProductStatus.active,
);

Future<void> _pumpProfile(
  WidgetTester tester,
  _ProfileRepository repository,
) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(home: ProfileScreen(repository: repository)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 031 renders source profile fields and activity actions',
      (tester) async {
    final repository = _ProfileRepository();
    await _pumpProfile(tester, repository);

    expect(find.text('محمد اليمني'), findsOneWidget);
    expect(find.text('عميل عسلكم'), findsOneWidget);
    expect(find.text('mohammed@example.com'), findsOneWidget);
    expect(find.text('+967700000000'), findsOneWidget);
    expect(find.text('إب، اليمن'), findsOneWidget);
    expect(find.text('أحرص على اختيار أفضل المنتجات النحلية الطبيعية.'),
        findsOneWidget);
    expect(find.text('نشاطك'), findsOneWidget);
    expect(find.text('المحفوظات'), findsNWidgets(2));
    expect(find.text('المتابعات'), findsNWidgets(2));
    expect(find.text('طلباتي'), findsNWidgets(2));
    expect(find.text('الرسائل'), findsOneWidget);
    expect(find.text('الإشعارات'), findsOneWidget);
    expect(find.text('الحساب والمساعدة'), findsOneWidget);
    expect(find.text('الدعم الفني'), findsOneWidget);
    expect(find.text('المساعدة'), findsOneWidget);
    expect(repository.statsCalls, 3);
  });

  testWidgets('TASK 031 opens the real following route from activity',
      (tester) async {
    await _pumpProfile(tester, _ProfileRepository());

    await tester.tap(
      find.widgetWithText(AssalActionTile, 'المتابعات'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FavoritesScreen), findsOneWidget);
    expect(find.text('مناحل جبال اليمن'), findsOneWidget);
  });

  testWidgets('TASK 031 retries unavailable session source', (tester) async {
    final repository = _ProfileRepository(unavailableOnce: true);
    await _pumpProfile(tester, repository);

    expect(
      find.text('تعذر مزامنة جلسة الحساب. حاول مرة أخرى.'),
      findsOneWidget,
    );
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('محمد اليمني'), findsOneWidget);
    expect(repository.sessionCalls, 2);
  });

  testWidgets('TASK 031 keeps guest profile behind real auth action',
      (tester) async {
    await _pumpProfile(tester, _ProfileRepository(authenticated: false));

    expect(find.text('تصفح كزائر'), findsOneWidget);
    expect(find.text('تسجيل الدخول أو إنشاء حساب'), findsOneWidget);
    expect(find.text('نشاطك'), findsNothing);
  });

  testWidgets('TASK 031 records the profile visual contract', (tester) async {
    await _pumpProfile(tester, _ProfileRepository());
    tester.view.physicalSize = const Size(1440, 2560);
    tester.view.devicePixelRatio = 4;
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ProfileScreen),
      matchesGoldenFile(
          'visual_reference/task031_profile_reference_360x640.png'),
    );
  });
}

class _ProfileRepository implements AssalRepository {
  _ProfileRepository({
    this.authenticated = true,
    this.unavailableOnce = false,
  });

  final bool authenticated;
  bool unavailableOnce;
  int sessionCalls = 0;
  int statsCalls = 0;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async {
    sessionCalls++;
    if (unavailableOnce) {
      unavailableOnce = false;
      return AssalSession.unavailable;
    }
    return authenticated
        ? const AssalSession(
            isAuthenticated: true,
            role: AssalRole.customer,
            user: _user,
          )
        : AssalSession.guest;
  }

  @override
  Future<AssalLoadState<List<AssalStoreSummary>>> listFollowedStores(
    String userId,
  ) async {
    statsCalls++;
    return const AssalData(<AssalStoreSummary>[_store]);
  }

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listFavoriteProducts(
    String userId,
  ) async {
    statsCalls++;
    return const AssalData(<AssalProductSummary>[_product]);
  }

  @override
  Future<AssalLoadState<List<AssalRequestSummary>>> listRequests(
    String userId,
  ) async {
    statsCalls++;
    return const AssalData(<AssalRequestSummary>[]);
  }

  @override
  Future<AssalLoadState<List<AssalTaxonomy>>> listFavoriteTaxonomies(
    String userId,
  ) async =>
      const AssalData(<AssalTaxonomy>[]);

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({
    AssalProductQuery? query,
  }) async =>
      const AssalData(<AssalProductSummary>[_product]);

  @override
  Future<AssalLoadState<List<AssalStoreSummary>>> listStores({
    String? regionId,
  }) async =>
      const AssalData(<AssalStoreSummary>[_store]);

  @override
  Future<AssalLoadState<AssalStoreSummary>> getStore(String storeId) async =>
      const AssalData(_store);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
