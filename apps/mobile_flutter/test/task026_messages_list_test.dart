import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_account.dart';
import 'package:assalkom/features/customer/customer_discovery.dart';

const _customer = AssalUserProfile(
  id: 'customer-1',
  nameAr: 'عميل عسلكم',
  role: AssalRole.customer,
);

final _conversations = <AssalConversationSummary>[
  AssalConversationSummary(
    id: 'conversation-1',
    storeId: 'store-1',
    storeName: 'مناحل جبال اليمن',
    lastMessage: 'مرحبًا، المنتج متوفر لدينا.',
    updatedAt: DateTime(2026, 8, 20, 11, 32),
    unreadCount: 2,
  ),
  AssalConversationSummary(
    id: 'conversation-2',
    storeId: 'store-2',
    storeName: 'عسل السدر الذهبي',
    lastMessage: 'هل يتوفر التوصيل؟',
    updatedAt: DateTime(2026, 8, 20, 10, 5),
    unreadCount: 1,
  ),
];

Future<void> _pumpMessages(
  WidgetTester tester,
  _MessagesRepository repository,
) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(home: MessagesScreen(repository: repository)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 026 renders source-backed conversation fields',
      (tester) async {
    final repository = _MessagesRepository();
    await _pumpMessages(tester, repository);

    expect(find.text('الرسائل'), findsOneWidget);
    expect(find.text('البحث في المحادثات'), findsOneWidget);
    expect(find.text('مناحل جبال اليمن'), findsOneWidget);
    expect(find.text('عسل السدر الذهبي'), findsOneWidget);
    expect(find.text('مرحبًا، المنتج متوفر لدينا.'), findsOneWidget);
    expect(find.text('20/08 · 11:32'), findsOneWidget);
    expect(find.text('2 جديد'), findsOneWidget);
    expect(repository.requestedUserId, 'customer-1');
  });

  testWidgets('TASK 026 filters conversations locally by store or last message',
      (tester) async {
    await _pumpMessages(tester, _MessagesRepository());

    await tester.enterText(find.byType(TextField), 'التوصيل');
    await tester.pumpAndSettle();
    expect(find.text('عسل السدر الذهبي'), findsOneWidget);
    expect(find.text('مناحل جبال اليمن'), findsNothing);

    await tester.enterText(find.byType(TextField), 'جبال');
    await tester.pumpAndSettle();
    expect(find.text('مناحل جبال اليمن'), findsOneWidget);
    expect(find.text('عسل السدر الذهبي'), findsNothing);
  });

  testWidgets('TASK 026 shows empty guidance and explores real stores route',
      (tester) async {
    await _pumpMessages(
      tester,
      _MessagesRepository(conversations: const <AssalConversationSummary>[]),
    );

    expect(find.text('لا توجد محادثات بعد.'), findsOneWidget);
    expect(find.text('استكشف المتاجر'), findsOneWidget);
    await tester.tap(find.text('استكشف المتاجر'));
    await tester.pumpAndSettle();
    expect(find.byType(StoresScreen), findsOneWidget);
  });

  testWidgets('TASK 026 retries a conversation source error', (tester) async {
    final repository = _MessagesRepository(errorOnce: true);
    await _pumpMessages(tester, repository);

    expect(find.text('تعذر تحميل البيانات الآن.'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('مناحل جبال اليمن'), findsOneWidget);
    expect(repository.conversationCalls, 2);
  });

  testWidgets('TASK 026 gates the list behind the real session',
      (tester) async {
    await _pumpMessages(tester, _MessagesRepository(authenticated: false));

    expect(find.text('تسجيل الدخول لعرض الرسائل'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('TASK 026 opens the existing conversation route', (tester) async {
    await _pumpMessages(tester, _MessagesRepository());

    await tester.tap(find.text('مناحل جبال اليمن'));
    await tester.pumpAndSettle();
    expect(find.byType(ConversationScreen), findsOneWidget);
  });

  testWidgets('TASK 026 records the messages list visual contract',
      (tester) async {
    await _pumpMessages(tester, _MessagesRepository());
    tester.view.physicalSize = const Size(1440, 2560);
    tester.view.devicePixelRatio = 4;
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MessagesScreen),
      matchesGoldenFile(
        'visual_reference/task026_messages_list_reference_360x640.png',
      ),
    );
  });
}

class _MessagesRepository implements AssalRepository {
  _MessagesRepository({
    List<AssalConversationSummary>? conversations,
    this.errorOnce = false,
    this.authenticated = true,
  }) : conversations = conversations ?? _conversations;

  final List<AssalConversationSummary> conversations;
  bool errorOnce;
  final bool authenticated;
  String? requestedUserId;
  int conversationCalls = 0;

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
  Future<AssalLoadState<List<AssalConversationSummary>>> listConversations(
    String userId,
  ) async {
    requestedUserId = userId;
    conversationCalls++;
    if (errorOnce) {
      errorOnce = false;
      return const AssalError<List<AssalConversationSummary>>(
        'تعذر تحميل البيانات الآن.',
        kind: AssalErrorKind.network,
        retryable: true,
      );
    }
    return AssalData(conversations);
  }

  @override
  Future<AssalLoadState<List<AssalMessageSummary>>> listMessages(
    String conversationId,
  ) async =>
      const AssalData(<AssalMessageSummary>[]);

  @override
  Future<AssalLoadState<List<AssalStoreSummary>>> listStores({
    String? regionId,
  }) async =>
      const AssalData(<AssalStoreSummary>[]);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
