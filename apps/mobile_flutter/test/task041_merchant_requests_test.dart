import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_request_detail.dart';
import 'package:assalkom/features/merchant/merchant_dashboard.dart';

class _RequestsRepository implements AssalRepository {
  _RequestsRepository({this.requestsErrorOnce = false});

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
  );
  static const workspace = AssalMerchantWorkspaceSummary(
    store: store,
    verificationStatus: 'pending',
    publicStatus: 'pending',
    canEdit: true,
    canPublish: false,
  );
  static const firstRequest = AssalRequestSummary(
    id: 'request-1',
    requesterId: 'customer-1',
    merchantId: 'merchant-1',
    storeId: 'store-1',
    subject: 'طلب عسل أول',
    status: RequestStatus.open,
    productName: 'عسل سدر',
    storeName: 'متجر الاختبار',
    requesterName: 'عميل عسلكم',
    body: 'أرغب في معرفة التوفر والكمية.',
    quantity: 2,
    preferredHandoffOption: 'delivery',
  );
  static const secondRequest = AssalRequestSummary(
    id: 'request-2',
    requesterId: 'customer-2',
    merchantId: 'merchant-1',
    storeId: 'store-1',
    subject: 'طلب عسل ثان',
    status: RequestStatus.answered,
    productName: 'عسل سمرة',
    storeName: 'متجر الاختبار',
    requesterName: 'عميل آخر',
    quantity: 1,
    preferredHandoffOption: 'pickup',
  );
  static const requests = <AssalRequestSummary>[
    firstRequest,
    secondRequest,
  ];

  final bool requestsErrorOnce;
  int requestCalls = 0;
  int replyCalls = 0;
  AssalRequestReplyDraft? lastReply;

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
  ) async =>
      const AssalData(<AssalProductSummary>[]);

  @override
  Future<AssalLoadState<List<AssalRequestSummary>>> listMerchantRequests(
    String userId,
  ) async {
    requestCalls++;
    if (requestsErrorOnce && requestCalls == 1) {
      return const AssalError<List<AssalRequestSummary>>(
        'تعذر تحميل الطلبات الآن',
        code: 'requests_failed',
      );
    }
    return const AssalData(requests);
  }

  @override
  Future<AssalLoadState<List<AssalCommentSummary>>> listComments(
    String productId,
  ) async =>
      const AssalData(<AssalCommentSummary>[]);

  @override
  Future<AssalLoadState<List<AssalRequestMessageSummary>>> listRequestMessages(
    String requestId,
  ) async =>
      const AssalData(<AssalRequestMessageSummary>[]);

  @override
  Future<AssalLoadState<AssalRequestMessageSummary>> replyToRequest(
    String userId,
    String requestId,
    AssalRequestReplyDraft draft,
  ) async {
    replyCalls++;
    lastReply = draft;
    return AssalData<AssalRequestMessageSummary>(
      AssalRequestMessageSummary(
        id: 'message-1',
        requestId: 'request-1',
        senderId: 'merchant-1',
        body: 'متوفر ويمكن التنسيق للتسليم.',
        createdAt: DateTime(2026, 1, 1),
        responseCode: RequestResponseCode.available,
        isMine: true,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

Future<void> _pumpRequests(
  WidgetTester tester,
  _RequestsRepository repository,
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
  await tester.tap(find.text('الطلبات'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 041 renders requests, details, quantity and handoff',
      (tester) async {
    await _pumpRequests(tester, _RequestsRepository());

    expect(find.text('كل الطلبات'), findsOneWidget);
    expect(find.text('عسل سدر'), findsOneWidget);
    expect(find.text('عسل سمرة'), findsOneWidget);
    expect(find.text('مفتوح'), findsOneWidget);
    expect(find.text('تم الرد'), findsOneWidget);

    await tester.tap(find.text('عسل سدر'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomerRequestDetailScreen), findsOneWidget);
    expect(find.text('عميل عسلكم'), findsOneWidget);
    expect(find.text('الكمية'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('توصيل التاجر'), findsOneWidget);
  });

  testWidgets('TASK 041 filters merchant requests by response status',
      (tester) async {
    await _pumpRequests(tester, _RequestsRepository());

    await tester.tap(find.text('تم الرد').last);
    await tester.pump();
    expect(find.text('عسل سمرة'), findsOneWidget);
    expect(find.text('عسل سدر'), findsNothing);
  });

  testWidgets('TASK 041 sends a merchant response and response code',
      (tester) async {
    final repository = _RequestsRepository();
    await _pumpRequests(tester, repository);
    await tester.tap(find.text('عسل سدر'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byWidgetPredicate((widget) => widget is DropdownButtonFormField),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('متوفر').last);
    await tester.enterText(
      find.byType(TextField),
      'متوفر ويمكن التنسيق للتسليم.',
    );
    await tester.tap(find.text('إرسال الرد'));
    await tester.pumpAndSettle();

    expect(repository.replyCalls, 1);
    expect(repository.lastReply?.responseCode, RequestResponseCode.available);
    expect(repository.lastReply?.body, 'متوفر ويمكن التنسيق للتسليم.');
    expect(find.text('تم إرسال الرد وتحديث حالة الطلب.'), findsOneWidget);
  });

  testWidgets('TASK 041 exposes retry when request source fails',
      (tester) async {
    final repository = _RequestsRepository(requestsErrorOnce: true);
    await _pumpRequests(tester, repository);

    expect(find.text('تعذر تحميل الطلبات الآن'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('عسل سدر'), findsOneWidget);
    expect(repository.requestCalls, greaterThanOrEqualTo(2));
  });

  testWidgets('TASK 041 shows a truthful empty or filtered state',
      (tester) async {
    final repository = _EmptyRequestsRepository();
    await _pumpRequests(tester, repository);
    expect(find.text('لا توجد طلبات تواصل لهذا المتجر بعد.'), findsOneWidget);
    expect(find.text('كل الطلبات'), findsOneWidget);
  });

  testWidgets('TASK 041 records the visual contract', (tester) async {
    await _pumpRequests(tester, _RequestsRepository());
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MerchantDashboard),
      matchesGoldenFile(
        'visual_reference/task041_merchant_requests_reference_360x780.png',
      ),
    );
  });
}

class _EmptyRequestsRepository extends _RequestsRepository {
  @override
  Future<AssalLoadState<List<AssalRequestSummary>>> listMerchantRequests(
    String userId,
  ) async =>
      const AssalData(<AssalRequestSummary>[]);
}
