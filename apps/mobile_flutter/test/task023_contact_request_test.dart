import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_catalog.dart';

const _product = AssalProductSummary(
  id: 'product-1',
  storeId: 'store-1',
  nameAr: 'عسل السدر الجبلي الفاخر',
  productType: ProductType.honey,
  status: ProductStatus.active,
  primaryImageUrl: 'https://example.com/honey.png',
  price: 180,
  currencyCode: 'YER',
  weightLabel: '500 غرام',
);

const _store = AssalStoreSummary(
  id: 'store-1',
  merchantId: 'merchant-1',
  nameAr: 'مناحل جبال اليمن',
  slug: 'mountain-hives',
  regionNameAr: 'إب، اليمن',
  contactPhone: '+967777123456',
  contactWhatsapp: 'https://wa.me/967777123456',
  contactTelegram: 'https://t.me/mountain_hives',
  socialLinks: <String, String>{
    'website': 'https://assalkom.example/store/mountain-hives',
  },
  deliveryOptions: <String>['توصيل إلى باب البيت'],
  pickupLocations: <String>['نقطة إب الرئيسية'],
  status: StoreStatus.active,
);

const _user = AssalUserProfile(
  id: 'customer-1',
  nameAr: 'عميل الاختبار',
  role: AssalRole.customer,
);

Future<void> _pumpSheet(
  WidgetTester tester,
  _RequestRepository repository,
) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: _RequestHarness(repository: repository),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('فتح نافذة الطلب'));
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );

void main() {
  testWidgets('TASK 023 renders source-backed request fields and channels',
      (tester) async {
    await _pumpSheet(tester, _RequestRepository());

    expect(find.text('اسأل عن التوفر'), findsOneWidget);
    expect(find.text('عسل السدر الجبلي الفاخر'), findsOneWidget);
    expect(find.text('مناحل جبال اليمن'), findsOneWidget);
    expect(find.text('الموضوع'), findsNothing);
    expect(find.text('الكمية'), findsOneWidget);
    expect(find.text('السعر أو ملاحظة السعر (اختياري)'), findsOneWidget);
    expect(find.text('ملاحظات التوصيل (اختياري)'), findsOneWidget);
    expect(find.text('داخل عسلكم'), findsOneWidget);
    expect(find.text('الهاتف'), findsOneWidget);
    expect(find.text('واتساب'), findsOneWidget);
    expect(find.text('تلغرام'), findsOneWidget);
    expect(find.text('الموقع'), findsOneWidget);
    expect(find.text('إرسال الطلب'), findsOneWidget);
    expect(find.text('إلغاء'), findsOneWidget);
  });

  testWidgets('TASK 023 submits the real request draft and selected channel',
      (tester) async {
    final repository = _RequestRepository();
    await _pumpSheet(tester, repository);

    await tester.enterText(
        _field('السعر أو ملاحظة السعر (اختياري)'), 'هل يتوفر سعر الجملة؟');
    await tester.enterText(
        _field('ملاحظات التوصيل (اختياري)'), 'التواصل قبل الوصول');
    await tester.tap(find.text('واتساب'));
    await tester.ensureVisible(find.text('إرسال الطلب'));
    await tester.tap(find.text('إرسال الطلب'));
    await tester.pumpAndSettle();

    expect(repository.requesterId, 'customer-1');
    expect(repository.draft?.productId, 'product-1');
    expect(repository.draft?.subject, 'استفسار عن عسل السدر الجبلي الفاخر');
    expect(repository.draft?.quantity, 1);
    expect(repository.draft?.contactChannel, 'whatsapp');
    expect(repository.draft?.priceNote, 'هل يتوفر سعر الجملة؟');
    expect(repository.draft?.deliveryNote, 'التواصل قبل الوصول');
    expect(find.text('تم حفظ الطلب ويمكنك متابعته من ملفك.'), findsOneWidget);
  });

  testWidgets('TASK 023 blocks sending without an authenticated session',
      (tester) async {
    final repository = _RequestRepository(authenticated: false);
    await _pumpSheet(tester, repository);

    await tester.tap(find.text('إرسال الطلب'));
    await tester.pumpAndSettle();
    expect(find.text('سجّل الدخول أولًا لإرسال الطلب.'), findsOneWidget);
    expect(repository.draft, isNull);
  });

  testWidgets('TASK 023 reports create request errors without closing',
      (tester) async {
    final repository = _RequestRepository(requestError: true);
    await _pumpSheet(tester, repository);

    await tester.tap(find.text('إرسال الطلب'));
    await tester.pumpAndSettle();
    expect(find.text('تعذر حفظ الطلب الآن.'), findsOneWidget);
    expect(find.text('اسأل عن التوفر'), findsOneWidget);
  });

  testWidgets('TASK 023 cancels through the real action', (tester) async {
    await _pumpSheet(tester, _RequestRepository());

    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(find.text('اسأل عن التوفر'), findsNothing);
  });

  testWidgets('TASK 023 records the contact request visual contract',
      (tester) async {
    await _pumpSheet(tester, _RequestRepository());
    tester.view.physicalSize = const Size(1440, 2560);
    tester.view.devicePixelRatio = 4;
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(RequestSheet),
      matchesGoldenFile(
        'visual_reference/task023_contact_request_reference_360x640.png',
      ),
    );
  });
}

class _RequestHarness extends StatelessWidget {
  const _RequestHarness({required this.repository});

  final _RequestRepository repository;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => RequestSheet(
                repository: repository,
                product: _product,
                store: _store,
              ),
            ),
            child: const Text('فتح نافذة الطلب'),
          ),
        ),
      );
}

class _RequestRepository implements AssalRepository {
  _RequestRepository({
    this.authenticated = true,
    this.requestError = false,
  });

  final bool authenticated;
  final bool requestError;
  String? requesterId;
  AssalRequestDraft? draft;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => authenticated
      ? const AssalSession(
          isAuthenticated: true,
          role: AssalRole.customer,
          user: _user,
        )
      : AssalSession.guest;

  @override
  Future<AssalLoadState<AssalStoreSummary>> getStore(String storeId) async =>
      const AssalData(_store);

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({
    AssalProductQuery? query,
  }) async =>
      const AssalData(<AssalProductSummary>[]);

  @override
  Future<AssalLoadState<AssalRequestSummary>> createRequest(
    String requesterId,
    AssalRequestDraft draft,
  ) async {
    this.requesterId = requesterId;
    this.draft = draft;
    if (requestError) {
      return const AssalError<AssalRequestSummary>(
        'تعذر حفظ الطلب الآن.',
        kind: AssalErrorKind.network,
        retryable: true,
      );
    }
    return AssalData(
      AssalRequestSummary(
        id: 'request-1',
        requesterId: requesterId,
        storeId: draft.storeId,
        subject: draft.subject,
        status: RequestStatus.open,
        productId: draft.productId,
        body: draft.body,
        quantity: draft.quantity,
        phone: draft.phone,
        preferredHandoffOption: draft.handoffOption.name,
        priceNote: draft.priceNote,
        deliveryNote: draft.deliveryNote,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
