import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_catalog.dart';

const _store = AssalStoreSummary(
  id: 'store-1',
  merchantId: 'merchant-1',
  nameAr: 'مناحل جبال اليمن',
  slug: 'mountain-hives',
  followersCount: 2300,
  status: StoreStatus.active,
);

final _followersPage = AssalStoreFollowersPage(
  items: <AssalStoreFollowerSummary>[
    AssalStoreFollowerSummary(
      displayName: 'محمد العسلي',
      followedAt: DateTime(2024, 5, 12),
    ),
    AssalStoreFollowerSummary(
      displayName: 'سارة اليمنية',
      followedAt: DateTime(2024, 5, 5),
    ),
    AssalStoreFollowerSummary(
      displayName: 'أحمد الشامي',
      followedAt: DateTime(2024, 4, 28),
    ),
  ],
  total: 2300,
  limit: 50,
  offset: 0,
);

Future<void> _pumpStore(
  WidgetTester tester,
  _FollowersRepository repository,
) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
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

Future<void> _openFollowers(WidgetTester tester) async {
  await tester.tap(find.text('متابع'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 022 opens source-backed followers Bottom Sheet',
      (tester) async {
    final repository = _FollowersRepository();
    await _pumpStore(tester, repository);
    await _openFollowers(tester);

    expect(find.text('متابعو المتجر'), findsOneWidget);
    expect(find.text('إجمالي المتابعين: 2.3K'), findsOneWidget);
    expect(find.text('محمد العسلي'), findsOneWidget);
    expect(find.text('سارة اليمنية'), findsOneWidget);
    expect(find.text('أحمد الشامي'), findsOneWidget);
    expect(find.text('تاريخ المتابعة: 12 مايو 2024'), findsOneWidget);
    expect(repository.storeIdRequested, 'store-1');
    expect(find.byTooltip('إغلاق'), findsOneWidget);
  });

  testWidgets('TASK 022 closes the Bottom Sheet through its real action',
      (tester) async {
    await _pumpStore(tester, _FollowersRepository());
    await _openFollowers(tester);

    await tester.tap(find.byTooltip('إغلاق'));
    await tester.pumpAndSettle();
    expect(find.text('متابعو المتجر'), findsNothing);
  });

  testWidgets('TASK 022 shows explicit empty guidance and retry',
      (tester) async {
    await _pumpStore(
      tester,
      _FollowersRepository(
          page: const AssalStoreFollowersPage(
        items: <AssalStoreFollowerSummary>[],
        total: 0,
        limit: 50,
        offset: 0,
      )),
    );
    await _openFollowers(tester);

    expect(find.text('لا يوجد متابعون ظاهرون بعد.'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsAtLeastNWidgets(1));
  });

  testWidgets('TASK 022 retries a followers source error', (tester) async {
    final repository = _FollowersRepository(errorOnce: true);
    await _pumpStore(tester, repository);
    await _openFollowers(tester);

    expect(
      find.text(
        'تعذر تحميل المتابعين الآن. تحقق من الاتصال ثم أعد المحاولة.',
      ),
      findsOneWidget,
    );
    final retryButton = find.text('إعادة المحاولة').last;
    await tester.ensureVisible(retryButton);
    await tester.tap(retryButton);
    await tester.pumpAndSettle();
    expect(find.text('محمد العسلي'), findsOneWidget);
  });

  testWidgets('TASK 022 records the followers visual contract', (tester) async {
    await _pumpStore(tester, _FollowersRepository());
    await _openFollowers(tester);
    tester.view.physicalSize = const Size(1440, 2560);
    tester.view.devicePixelRatio = 4;
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(StoreProfileScreen),
      matchesGoldenFile(
        'visual_reference/task022_store_followers_reference_360x640.png',
      ),
    );
  });
}

class _FollowersRepository implements AssalRepository {
  _FollowersRepository({
    AssalStoreFollowersPage? page,
    this.errorOnce = false,
  }) : page = page ?? _followersPage;

  final AssalStoreFollowersPage page;
  bool errorOnce;
  String? storeIdRequested;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => const AssalSession(
        isAuthenticated: false,
        role: AssalRole.guest,
      );

  @override
  Future<AssalLoadState<AssalStoreSummary>> getStore(String storeId) async =>
      const AssalData(_store);

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({
    AssalProductQuery? query,
  }) async =>
      const AssalData(<AssalProductSummary>[]);

  @override
  Future<AssalLoadState<AssalStoreFollowersPage>> listStoreFollowers(
    String storeId, {
    int limit = 50,
    int offset = 0,
  }) async {
    storeIdRequested = storeId;
    if (errorOnce) {
      errorOnce = false;
      return const AssalError<AssalStoreFollowersPage>(
        'تعذر تحميل المتابعين الآن. تحقق من الاتصال ثم أعد المحاولة.',
        kind: AssalErrorKind.network,
        retryable: true,
      );
    }
    return AssalData(page);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
