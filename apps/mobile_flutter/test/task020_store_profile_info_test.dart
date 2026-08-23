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
  description: 'عسل يمني أصيل من أفضل المناطق الجبلية.',
  regionNameAr: 'إب، اليمن',
  galleryUrls: <String>['', ''],
  deliveryOptions: <String>['توصيل إلى باب البيت', 'شحن بين المدن'],
  pickupLocations: <String>['نقطة إب الرئيسية'],
  isVerified: true,
  status: StoreStatus.active,
  yearsExperience: 12,
  bio: 'نهتم بالجودة والنقاء في كل قطرة عسل ننتجها.',
  specialties: <String>['عسل السدر', 'العسل الطلح'],
  certifications: <String>['جودة مصدرية'],
);

Future<void> _pumpStore(
  WidgetTester tester,
  _InfoRepository repository,
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

Future<void> _openInfoTab(WidgetTester tester) async {
  await tester.tap(find.text('معلومات المتجر'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 020 renders source-backed store information',
      (tester) async {
    final repository = _InfoRepository();
    await _pumpStore(tester, repository);
    await _openInfoTab(tester);

    expect(find.text('من المتجر'), findsOneWidget);
    expect(find.text('عن المتجر'), findsOneWidget);
    expect(find.text(_store.bio!), findsOneWidget);
    expect(find.text('الموقع والتخصصات'), findsOneWidget);
    expect(find.text('إب، اليمن'), findsOneWidget);
    expect(find.text('12 سنة'), findsOneWidget);
    expect(find.text('عسل السدر'), findsOneWidget);
    expect(find.text('جودة مصدرية'), findsOneWidget);
    expect(find.text('طرق التوصيل'), findsOneWidget);
    expect(find.text('توصيل إلى باب البيت'), findsOneWidget);
    expect(find.text('نقاط الاستلام'), findsOneWidget);
    expect(find.text('نقطة إب الرئيسية'), findsOneWidget);
    expect(repository.storeIdRequested, 'store-1');
  });

  testWidgets('TASK 020 shows explicit empty guidance for missing information',
      (tester) async {
    final repository = _InfoRepository(
        store: const AssalStoreSummary(
      id: 'store-empty',
      merchantId: 'merchant-1',
      nameAr: 'متجر بلا بيانات',
      slug: 'empty-store',
      status: StoreStatus.active,
    ));
    await _pumpStore(tester, repository);
    await _openInfoTab(tester);

    expect(find.text('لم يضف المتجر نبذة تعريفية بعد.'), findsOneWidget);
    expect(find.text('لم يضف المتجر تخصصاته بعد.'), findsOneWidget);
    expect(find.text('لم يحدد المتجر طرق التوصيل بعد.'), findsOneWidget);
    expect(find.text('لم يحدد المتجر نقاط الاستلام بعد.'), findsOneWidget);
  });

  testWidgets('TASK 020 retries a store source error', (tester) async {
    final repository = _InfoRepository(storeErrorOnce: true);
    await _pumpStore(tester, repository);

    expect(
      find.text('تعذر تحميل البيانات الآن. تحقق من الاتصال ثم أعد المحاولة.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('إعادة المحاولة'));
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('مناحل جبال اليمن'), findsWidgets);
  });

  testWidgets('TASK 020 records the store information visual contract',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpStore(tester, _InfoRepository());
    await _openInfoTab(tester);
    await expectLater(
      find.byType(StoreProfileScreen),
      matchesGoldenFile(
        'visual_reference/task020_store_profile_info_reference_360x780.png',
      ),
    );
  });
}

class _InfoRepository implements AssalRepository {
  _InfoRepository({
    this.store = _store,
    this.storeErrorOnce = false,
  });

  final AssalStoreSummary store;
  bool storeErrorOnce;
  String? storeIdRequested;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => const AssalSession(
        isAuthenticated: false,
        role: AssalRole.guest,
      );

  @override
  Future<AssalLoadState<AssalStoreSummary>> getStore(String storeId) async {
    storeIdRequested = storeId;
    if (storeErrorOnce) {
      storeErrorOnce = false;
      return const AssalError<AssalStoreSummary>(
        'تعذر تحميل البيانات الآن. تحقق من الاتصال ثم أعد المحاولة.',
        kind: AssalErrorKind.network,
        retryable: true,
      );
    }
    return AssalData(store);
  }

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({
    AssalProductQuery? query,
  }) async =>
      const AssalData(<AssalProductSummary>[]);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
