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
  description: 'عسل يمني أصيل.',
  regionNameAr: 'إب، اليمن',
  contactPhone: '+967777123456',
  contactWhatsapp: 'https://wa.me/967777123456',
  contactTelegram: 'https://t.me/mountain_hives',
  socialLinks: <String, String>{
    'website': 'https://assalkom.example/store/mountain-hives',
  },
  deliveryOptions: <String>['توصيل إلى باب البيت', 'شحن بين المدن'],
  pickupLocations: <String>['نقطة إب الرئيسية'],
  status: StoreStatus.active,
);

Future<void> _pumpStore(
  WidgetTester tester,
  _ContactRepository repository,
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

Future<void> _openContactTab(WidgetTester tester) async {
  await tester.tap(find.text('التواصل'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 021 renders source-backed channels and delivery options',
      (tester) async {
    final repository = _ContactRepository();
    await _pumpStore(tester, repository);
    await _openContactTab(tester);

    expect(find.text('قنوات التواصل'), findsOneWidget);
    expect(find.text('الهاتف'), findsOneWidget);
    expect(find.text('واتساب'), findsOneWidget);
    expect(find.text('تلغرام'), findsOneWidget);
    expect(find.text('الموقع الإلكتروني'), findsOneWidget);
    expect(find.text('التسليم والاستلام'), findsOneWidget);
    expect(find.text('التوصيل'), findsOneWidget);
    expect(find.textContaining('توصيل إلى باب البيت'), findsOneWidget);
    expect(find.text('الاستلام'), findsOneWidget);
    expect(find.text('نقطة إب الرئيسية'), findsOneWidget);
    expect(find.text('مراسلة التاجر'), findsOneWidget);
  });

  testWidgets('TASK 021 invokes the real phone contact action', (tester) async {
    await _pumpStore(tester, _ContactRepository());
    await _openContactTab(tester);

    await tester.tap(find.widgetWithText(ActionChip, 'الهاتف'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ActionChip, 'الهاتف'), findsOneWidget);
  });

  testWidgets('TASK 021 shows explicit empty guidance for missing channels',
      (tester) async {
    const emptyStore = AssalStoreSummary(
      id: 'store-empty',
      merchantId: 'merchant-1',
      nameAr: 'متجر بلا قنوات',
      slug: 'empty-store',
      status: StoreStatus.active,
    );
    await _pumpStore(tester, _ContactRepository(store: emptyStore));
    await _openContactTab(tester);

    expect(find.text('لم يضف المتجر قنوات تواصل بعد.'), findsOneWidget);
    expect(find.text('لم يحدد المتجر خيارات التسليم أو الاستلام بعد.'),
        findsOneWidget);
    expect(find.text('مراسلة التاجر'), findsOneWidget);
  });

  testWidgets('TASK 021 retries a store source error', (tester) async {
    final repository = _ContactRepository(storeErrorOnce: true);
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

  testWidgets('TASK 021 records the store contact visual contract',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpStore(tester, _ContactRepository());
    await _openContactTab(tester);
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(StoreProfileScreen),
      matchesGoldenFile(
        'visual_reference/task021_store_profile_contact_reference_360x780.png',
      ),
    );
  });
}

class _ContactRepository implements AssalRepository {
  _ContactRepository({
    this.store = _store,
    this.storeErrorOnce = false,
  });

  final AssalStoreSummary store;
  bool storeErrorOnce;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => const AssalSession(
        isAuthenticated: false,
        role: AssalRole.guest,
      );

  @override
  Future<AssalLoadState<AssalStoreSummary>> getStore(String storeId) async {
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
