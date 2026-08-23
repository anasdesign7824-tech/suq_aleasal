import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_request_detail.dart';

const _customer = AssalUserProfile(
  id: 'customer-1',
  nameAr: 'عميل عسلكم',
  role: AssalRole.customer,
);

final _request = AssalRequestSummary(
  id: 'request-1',
  requesterId: 'customer-1',
  storeId: 'store-1',
  merchantId: 'merchant-1',
  subject: 'استفسار عن عسل السدر',
  status: RequestStatus.answered,
  productId: 'product-1',
  productName: 'عسل السدر الجبلي الفاخر',
  storeName: 'مناحل جبال اليمن',
  requesterName: 'عميل عسلكم',
  body: 'هل المنتج متوفر؟',
  quantity: 2,
  phone: '0500000000',
  preferredHandoffOption: 'delivery',
  priceNote: 'أرسل السعر النهائي من فضلك.',
  deliveryNote: 'التوصيل إلى المنزل.',
  createdAt: DateTime(2026, 8, 20, 10, 30),
  updatedAt: DateTime(2026, 8, 21, 12, 45),
);

Future<void> _pumpDetail(
  WidgetTester tester,
  _DetailRepository repository, {
  bool merchantMode = false,
  Future<void> Function()? onOpenStore,
  Future<void> Function()? onMessageMerchant,
}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: CustomerRequestDetailScreen(
        repository: repository,
        request: _request,
        merchantMode: merchantMode,
        onOpenStore: onOpenStore,
        onMessageMerchant: onMessageMerchant,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 025 renders source-backed request fields and messages',
      (tester) async {
    final repository = _DetailRepository(
      messages: [
        AssalRequestMessageSummary(
          id: 'message-1',
          requestId: 'request-1',
          senderId: 'merchant-1',
          body: 'المنتج متوفر ويمكن تنسيق التوصيل.',
          createdAt: DateTime(2026, 8, 21, 12),
          responseCode: RequestResponseCode.available,
        ),
      ],
    );
    await _pumpDetail(tester, repository);

    expect(find.text('تفاصيل الطلب'), findsOneWidget);
    expect(find.text('عسل السدر الجبلي الفاخر'), findsOneWidget);
    expect(find.text('مناحل جبال اليمن'), findsOneWidget);
    expect(find.text('الكمية'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('توصيل التاجر'), findsOneWidget);
    expect(find.text('ملاحظة السعر'), findsOneWidget);
    expect(find.text('التوصيل إلى المنزل.'), findsOneWidget);
    expect(find.text('آخر تحديث'), findsOneWidget);
    expect(find.text('المنتج متوفر ويمكن تنسيق التوصيل.'), findsOneWidget);
    expect(repository.messagesRequestId, 'request-1');
  });

  testWidgets('TASK 025 shows empty and retries message source errors',
      (tester) async {
    final repository = _DetailRepository(errorOnce: true);
    await _pumpDetail(tester, repository);

    expect(find.text('تعذر تحميل الرسائل الآن.'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('لم يصل رد على الطلب بعد.'), findsOneWidget);
    expect(repository.messageCalls, 2);
  });

  testWidgets('TASK 025 exposes real customer actions without merchant composer',
      (tester) async {
    var openedStore = false;
    var openedConversation = false;
    await _pumpDetail(
      tester,
      _DetailRepository(),
      onOpenStore: () async => openedStore = true,
      onMessageMerchant: () async => openedConversation = true,
    );

    expect(find.text('مراسلة التاجر'), findsOneWidget);
    expect(find.text('فتح المتجر'), findsOneWidget);
    expect(find.text('إجابة التاجر'), findsNothing);
    await tester.tap(find.text('مراسلة التاجر'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('فتح المتجر'));
    await tester.pumpAndSettle();
    expect(openedConversation, isTrue);
    expect(openedStore, isTrue);
  });

  testWidgets('TASK 025 keeps customer and merchant permissions separate',
      (tester) async {
    await _pumpDetail(tester, _DetailRepository(), merchantMode: true);

    expect(find.text('الرد على الطلب'), findsOneWidget);
    expect(find.text('إجابة التاجر'), findsOneWidget);
    expect(find.text('إرسال الرد'), findsOneWidget);
    expect(find.text('مراسلة التاجر'), findsNothing);
    expect(find.text('فتح المتجر'), findsNothing);
  });

  testWidgets('TASK 025 records the customer detail visual contract',
      (tester) async {
    await _pumpDetail(tester, _DetailRepository());
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(CustomerRequestDetailScreen),
      matchesGoldenFile(
        'visual_reference/task025_customer_request_detail_reference_360x780.png',
      ),
    );
  });
}

class _DetailRepository implements AssalRepository {
  _DetailRepository({this.messages = const [], this.errorOnce = false});

  final List<AssalRequestMessageSummary> messages;
  bool errorOnce;
  String? messagesRequestId;
  int messageCalls = 0;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => const AssalSession(
        isAuthenticated: true,
        role: AssalRole.customer,
        user: _customer,
      );

  @override
  Future<AssalLoadState<List<AssalRequestMessageSummary>>> listRequestMessages(
    String requestId,
  ) async {
    messagesRequestId = requestId;
    messageCalls++;
    if (errorOnce) {
      errorOnce = false;
      return const AssalError<List<AssalRequestMessageSummary>>(
        'تعذر تحميل الرسائل الآن.',
        kind: AssalErrorKind.network,
        retryable: true,
      );
    }
    return AssalData(messages);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
