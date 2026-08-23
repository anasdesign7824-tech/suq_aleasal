import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_account.dart';
import 'package:assalkom/features/customer/customer_discovery.dart';

const _user = AssalUserProfile(
  id: 'customer-1',
  nameAr: 'عميل عسلكم',
  role: AssalRole.customer,
);

final _requests = <AssalRequestSummary>[
  AssalRequestSummary(
    id: 'request-new',
    requesterId: 'customer-1',
    storeId: 'store-1',
    subject: 'استفسار عن عسل السدر الجبلي الفاخر',
    status: RequestStatus.open,
    productId: 'product-1',
    productName: 'عسل السدر الجبلي الفاخر',
    storeName: 'مناحل جبال اليمن',
    body: 'هل المنتج متوفر؟',
    quantity: 1,
    createdAt: DateTime(2025, 6, 1),
  ),
  AssalRequestSummary(
    id: 'request-progress',
    requesterId: 'customer-1',
    storeId: 'store-1',
    subject: 'استفسار عن التوصيل',
    status: RequestStatus.inProgress,
    productName: 'عسل السدر الجبلي الفاخر',
    storeName: 'مناحل جبال اليمن',
    quantity: 2,
    createdAt: DateTime(2025, 6, 2),
  ),
  AssalRequestSummary(
    id: 'request-answered',
    requesterId: 'customer-1',
    storeId: 'store-1',
    subject: 'استفسار مجاب',
    status: RequestStatus.answered,
    productName: 'عسل السدر الجبلي الفاخر',
    storeName: 'مناحل جبال اليمن',
    quantity: 1,
    createdAt: DateTime(2025, 6, 3),
  ),
  AssalRequestSummary(
    id: 'request-closed',
    requesterId: 'customer-1',
    storeId: 'store-1',
    subject: 'طلب مغلق',
    status: RequestStatus.closed,
    productName: 'عسل السدر الجبلي الفاخر',
    storeName: 'مناحل جبال اليمن',
    quantity: 1,
    createdAt: DateTime(2025, 6, 4),
  ),
];

Future<void> _pumpRequests(
  WidgetTester tester,
  _RequestsRepository repository,
) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(home: RequestsScreen(repository: repository)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 024 renders source-backed requests and status filters',
      (tester) async {
    final repository = _RequestsRepository();
    await _pumpRequests(tester, repository);

    expect(find.text('طلباتي'), findsOneWidget);
    expect(find.text('الكل'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'جديد'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'قيد الرد'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'تم الرد'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'مغلقة'), findsOneWidget);
    expect(find.text('عسل السدر الجبلي الفاخر'), findsNWidgets(4));
    expect(find.text('مناحل جبال اليمن'), findsNWidgets(4));
    expect(find.text('الكمية: 1'), findsNWidgets(3));
    expect(repository.requestedUserId, 'customer-1');
  });

  testWidgets('TASK 024 gates the list behind the real customer session',
      (tester) async {
    await _pumpRequests(
      tester,
      _RequestsRepository(authenticated: false),
    );

    expect(find.text('تسجيل الدخول لمتابعة الطلبات'), findsOneWidget);
  });

  testWidgets('TASK 024 filters requests by real status chips', (tester) async {
    await _pumpRequests(tester, _RequestsRepository());

    await tester.tap(find.widgetWithText(ChoiceChip, 'قيد الرد'));
    await tester.pumpAndSettle();
    expect(find.text('عسل السدر الجبلي الفاخر'), findsOneWidget);
    expect(find.text('الكمية: 2'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'مغلقة'));
    await tester.pumpAndSettle();
    expect(find.text('عسل السدر الجبلي الفاخر'), findsOneWidget);
    expect(find.text('الكمية: 2'), findsNothing);
  });

  testWidgets('TASK 024 opens the real customer request detail route',
      (tester) async {
    final repository = _RequestsRepository();
    await _pumpRequests(tester, repository);

    await tester.tap(find.widgetWithText(TextButton, 'التفاصيل').first);
    await tester.pumpAndSettle();
    expect(find.text('تفاصيل الطلب'), findsOneWidget);
    expect(repository.messagesRequestId, 'request-new');
  });

  testWidgets('TASK 024 exposes empty guidance and real product exploration',
      (tester) async {
    await _pumpRequests(
      tester,
      _RequestsRepository(requests: const <AssalRequestSummary>[]),
    );

    expect(find.text('لا توجد طلبات تواصل بعد.'), findsOneWidget);
    expect(find.text('استكشف المنتجات'), findsOneWidget);
    await tester.tap(find.text('استكشف المنتجات'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
  });

  testWidgets('TASK 024 retries a request source error', (tester) async {
    final repository = _RequestsRepository(errorOnce: true);
    await _pumpRequests(tester, repository);

    expect(
      find.text('تعذر تحميل الطلبات الآن. تحقق من الاتصال ثم أعد المحاولة.'),
      findsOneWidget,
    );
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('عسل السدر الجبلي الفاخر'), findsNWidgets(4));
  });

  testWidgets('TASK 024 records the customer requests visual contract',
      (tester) async {
    await _pumpRequests(tester, _RequestsRepository());
    tester.view.physicalSize = const Size(1440, 2560);
    tester.view.devicePixelRatio = 4;
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(RequestsScreen),
      matchesGoldenFile(
        'visual_reference/task024_customer_requests_reference_360x640.png',
      ),
    );
  });
}

class _RequestsRepository implements AssalRepository {
  _RequestsRepository({
    List<AssalRequestSummary>? requests,
    this.errorOnce = false,
    this.authenticated = true,
  }) : requests = requests ?? _requests;

  final List<AssalRequestSummary> requests;
  bool errorOnce;
  final bool authenticated;
  String? requestedUserId;
  String? messagesRequestId;

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
  Future<AssalLoadState<List<AssalRequestSummary>>> listRequests(
    String userId,
  ) async {
    requestedUserId = userId;
    if (errorOnce) {
      errorOnce = false;
      return const AssalError<List<AssalRequestSummary>>(
        'تعذر تحميل الطلبات الآن. تحقق من الاتصال ثم أعد المحاولة.',
        kind: AssalErrorKind.network,
        retryable: true,
      );
    }
    return AssalData(requests);
  }

  @override
  Future<AssalLoadState<List<AssalRequestMessageSummary>>> listRequestMessages(
      String requestId) async {
    messagesRequestId = requestId;
    return const AssalData(<AssalRequestMessageSummary>[]);
  }

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({
    AssalProductQuery? query,
  }) async =>
      const AssalData(<AssalProductSummary>[]);

  @override
  Future<AssalLoadState<List<AssalCategorySummary>>> listCategories() async =>
      const AssalData(<AssalCategorySummary>[]);

  @override
  Future<AssalLoadState<List<AssalTaxonomy>>> listTaxonomy() async =>
      const AssalData(<AssalTaxonomy>[]);

  @override
  Future<AssalLoadState<List<String>>> listPopularSearches() async =>
      const AssalData(<String>[]);

  @override
  Future<AssalLoadState<List<AssalStoreSummary>>> listStores({
    String? regionId,
  }) async =>
      const AssalData(<AssalStoreSummary>[]);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
