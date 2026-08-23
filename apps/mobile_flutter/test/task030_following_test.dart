import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/core/assal_widgets.dart';
import 'package:assalkom/features/customer/customer_catalog.dart';
import 'package:assalkom/features/customer/customer_favorites.dart';

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
  regionNameAr: 'صنعاء',
  followersCount: 24,
);

const _product = AssalProductSummary(
  id: 'product-1',
  storeId: 'store-1',
  nameAr: 'عسل السدر الجبلي',
  productType: ProductType.honey,
  status: ProductStatus.active,
);

Future<void> _pumpFollowing(
  WidgetTester tester,
  _FollowingRepository repository,
) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: FavoritesScreen(
        repository: repository,
        initialTab: 1,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 030 renders followed store and source counts',
      (tester) async {
    final repository = _FollowingRepository();
    await _pumpFollowing(tester, repository);

    expect(find.text('المحفوظات والمتابعات'), findsOneWidget);
    expect(find.text('مناحل جبال اليمن'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.byType(StoreCard), findsOneWidget);
    expect(repository.followedUserId, 'customer-1');
  });

  testWidgets('TASK 030 opens the followed store', (tester) async {
    await _pumpFollowing(tester, _FollowingRepository());

    await tester.tap(find.text('مناحل جبال اليمن'));
    await tester.pumpAndSettle();
    expect(find.byType(StoreProfileScreen), findsOneWidget);
  });

  testWidgets('TASK 030 removes follow and refreshes the source',
      (tester) async {
    final repository = _FollowingRepository();
    await _pumpFollowing(tester, repository);

    await tester.tap(find.byTooltip('إزالة المتابعة'));
    await tester.pumpAndSettle();
    expect(repository.toggledStoreId, 'store-1');
    expect(find.text('لا تتابع متاجر بعد.'), findsOneWidget);
    expect(find.text('تمت إزالة المتجر من المتابعات.'), findsOneWidget);
  });

  testWidgets('TASK 030 shows real discover-stores action when empty',
      (tester) async {
    await _pumpFollowing(tester, _FollowingRepository(empty: true));

    expect(find.text('لا تتابع متاجر بعد.'), findsOneWidget);
    await tester.tap(find.text('اكتشف المتاجر'));
    await tester.pumpAndSettle();
    expect(find.text('المتاجر'), findsOneWidget);
  });

  testWidgets('TASK 030 retries a followed-stores source error',
      (tester) async {
    final repository = _FollowingRepository(errorOnce: true);
    await _pumpFollowing(tester, repository);

    expect(find.text('تعذر تحميل المتابعات الآن.'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('مناحل جبال اليمن'), findsOneWidget);
    expect(repository.followedCalls, 2);
  });

  testWidgets('TASK 030 gates followed stores behind the session',
      (tester) async {
    await _pumpFollowing(tester, _FollowingRepository(authenticated: false));

    expect(find.text('تسجيل الدخول لعرض محفوظاتك'), findsOneWidget);
    expect(find.text('متاجر متابَعة'), findsNothing);
  });

  testWidgets('TASK 030 records the following visual contract', (tester) async {
    await _pumpFollowing(tester, _FollowingRepository());
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(FavoritesScreen),
      matchesGoldenFile(
        'visual_reference/task030_following_reference_360x780.png',
      ),
    );
  });
}

class _FollowingRepository implements AssalRepository {
  _FollowingRepository({
    this.empty = false,
    this.errorOnce = false,
    this.authenticated = true,
  });

  final bool empty;
  bool errorOnce;
  final bool authenticated;
  bool followed = true;
  String? followedUserId;
  String? toggledStoreId;
  int followedCalls = 0;

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
  Future<AssalLoadState<List<AssalStoreSummary>>> listFollowedStores(
    String userId,
  ) async {
    followedUserId = userId;
    followedCalls++;
    if (errorOnce) {
      errorOnce = false;
      return const AssalError<List<AssalStoreSummary>>(
        'تعذر تحميل المتابعات الآن.',
        kind: AssalErrorKind.network,
        retryable: true,
      );
    }
    return AssalData(
      empty || !followed
          ? const <AssalStoreSummary>[]
          : const <AssalStoreSummary>[_store],
    );
  }

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listFavoriteProducts(
    String userId,
  ) async =>
      const AssalData(<AssalProductSummary>[]);

  @override
  Future<AssalLoadState<List<AssalTaxonomy>>> listFavoriteTaxonomies(
    String userId,
  ) async =>
      const AssalData(<AssalTaxonomy>[]);

  @override
  Future<AssalLoadState<bool>> toggleFollow(
    String userId,
    String storeId,
  ) async {
    toggledStoreId = storeId;
    followed = false;
    return const AssalData(false);
  }

  @override
  Future<AssalLoadState<AssalStoreSummary>> getStore(String storeId) async =>
      const AssalData(_store);

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({
    AssalProductQuery? query,
  }) async =>
      query?.storeId == _store.id
          ? const AssalData(<AssalProductSummary>[_product])
          : const AssalData(<AssalProductSummary>[]);

  @override
  Future<AssalLoadState<List<AssalStoreSummary>>> listStores({
    String? regionId,
  }) async =>
      const AssalData(<AssalStoreSummary>[_store]);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
