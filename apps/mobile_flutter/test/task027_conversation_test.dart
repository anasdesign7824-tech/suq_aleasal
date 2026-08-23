import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_account.dart';

const _customer = AssalUserProfile(
  id: 'customer-1',
  nameAr: 'عميل عسلكم',
  role: AssalRole.customer,
);

final _conversation = AssalConversationSummary(
  id: 'conversation-1',
  storeId: 'store-1',
  storeName: 'مناحل جبال اليمن',
  lastMessage: 'مرحبًا',
  updatedAt: DateTime(2026, 8, 20, 11, 32),
);

final _initialMessages = <AssalMessageSummary>[
  AssalMessageSummary(
    id: 'message-1',
    conversationId: 'conversation-1',
    senderId: 'merchant-1',
    body: 'مرحبًا، كيف يمكننا مساعدتك؟',
    sentAt: DateTime(2026, 8, 20, 11, 30),
  ),
  AssalMessageSummary(
    id: 'message-2',
    conversationId: 'conversation-1',
    senderId: 'customer-1',
    body: 'أريد الاستفسار عن عسل السدر.',
    sentAt: DateTime(2026, 8, 20, 11, 31),
    isMine: true,
  ),
];

Future<void> _pumpConversation(
  WidgetTester tester,
  _ConversationRepository repository,
) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: ConversationScreen(
        repository: repository,
        conversation: _conversation,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 027 renders source-backed messages and composer',
      (tester) async {
    final repository = _ConversationRepository();
    await _pumpConversation(tester, repository);

    expect(find.text('مناحل جبال اليمن'), findsNWidgets(2));
    expect(find.text('متصل الآن'), findsOneWidget);
    expect(find.text('مرحبًا، كيف يمكننا مساعدتك؟'), findsOneWidget);
    expect(find.text('أريد الاستفسار عن عسل السدر.'), findsOneWidget);
    expect(find.text('اكتب رسالتك'), findsOneWidget);
    expect(find.byTooltip('إرسال'), findsOneWidget);
    expect(repository.requestedConversationId, 'conversation-1');
  });

  testWidgets('TASK 027 shows empty messages with Arabic guidance',
      (tester) async {
    await _pumpConversation(
      tester,
      _ConversationRepository(messages: const <AssalMessageSummary>[]),
    );

    expect(
      find.text('لا توجد رسائل بعد. ابدأ المحادثة برسالة جديدة.'),
      findsOneWidget,
    );
    expect(find.text('اكتب رسالتك'), findsOneWidget);
  });

  testWidgets('TASK 027 retries message loading after a source error',
      (tester) async {
    final repository = _ConversationRepository(errorOnce: true);
    await _pumpConversation(tester, repository);

    expect(find.text('تعذر تحميل البيانات الآن.'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('مرحبًا، كيف يمكننا مساعدتك؟'), findsOneWidget);
    expect(repository.messageCalls, 2);
  });

  testWidgets('TASK 027 sends through repository and refreshes source',
      (tester) async {
    final repository = _ConversationRepository();
    await _pumpConversation(tester, repository);

    await tester.enterText(find.byType(TextField), 'رسالة اختبارية');
    await tester.tap(find.byTooltip('إرسال'));
    await tester.pumpAndSettle();

    expect(repository.sentUserId, 'customer-1');
    expect(repository.sentDraft?.conversationId, 'conversation-1');
    expect(repository.sentDraft?.body, 'رسالة اختبارية');
    expect(find.text('تم إرسال الرسالة.'), findsOneWidget);
    expect(find.text('رسالة اختبارية'), findsOneWidget);
    expect(repository.messageCalls, 2);
  });

  testWidgets('TASK 027 keeps the message and reports a send error',
      (tester) async {
    final repository = _ConversationRepository(sendError: true);
    await _pumpConversation(tester, repository);

    await tester.enterText(find.byType(TextField), 'رسالة لم ترسل');
    await tester.tap(find.byTooltip('إرسال'));
    await tester.pumpAndSettle();

    expect(find.text('تعذر إرسال الرسالة الآن.'), findsOneWidget);
    expect(find.text('رسالة لم ترسل'), findsOneWidget);
    expect(repository.sentDraft?.body, 'رسالة لم ترسل');
  });

  testWidgets('TASK 027 gates sending behind the real session', (tester) async {
    await _pumpConversation(
      tester,
      _ConversationRepository(authenticated: false),
    );

    expect(find.text('يلزم تسجيل الدخول للإرسال'), findsOneWidget);
    expect(find.text('تسجيل الدخول للرد'), findsOneWidget);
    expect(find.byTooltip('تسجيل الدخول'), findsOneWidget);
  });

  testWidgets('TASK 027 retries an unavailable session', (tester) async {
    final repository = _ConversationRepository(sessionUnavailableOnce: true);
    await _pumpConversation(tester, repository);

    expect(
      find.text('تعذر مزامنة جلسة الحساب. حاول مرة أخرى.'),
      findsOneWidget,
    );
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('متصل الآن'), findsOneWidget);
    expect(repository.sessionCalls, 2);
  });

  testWidgets('TASK 027 records the conversation visual contract',
      (tester) async {
    await _pumpConversation(tester, _ConversationRepository());
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ConversationScreen),
      matchesGoldenFile(
        'visual_reference/task027_conversation_reference_360x780.png',
      ),
    );
  });
}

class _ConversationRepository implements AssalRepository {
  _ConversationRepository({
    List<AssalMessageSummary>? messages,
    this.errorOnce = false,
    this.sendError = false,
    this.authenticated = true,
    this.sessionUnavailableOnce = false,
  }) : messages = messages ?? List<AssalMessageSummary>.from(_initialMessages);

  final List<AssalMessageSummary> messages;
  bool errorOnce;
  final bool sendError;
  final bool authenticated;
  bool sessionUnavailableOnce;
  int messageCalls = 0;
  int sessionCalls = 0;
  String? requestedConversationId;
  String? sentUserId;
  AssalMessageDraft? sentDraft;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async {
    sessionCalls++;
    if (sessionUnavailableOnce) {
      sessionUnavailableOnce = false;
      return AssalSession.unavailable;
    }
    return authenticated
        ? const AssalSession(
            isAuthenticated: true,
            role: AssalRole.customer,
            user: _customer,
          )
        : AssalSession.guest;
  }

  @override
  Future<AssalLoadState<List<AssalMessageSummary>>> listMessages(
    String conversationId,
  ) async {
    requestedConversationId = conversationId;
    messageCalls++;
    if (errorOnce) {
      errorOnce = false;
      return const AssalError<List<AssalMessageSummary>>(
        'تعذر تحميل البيانات الآن.',
        kind: AssalErrorKind.network,
        retryable: true,
      );
    }
    return AssalData(List<AssalMessageSummary>.from(messages));
  }

  @override
  Future<AssalLoadState<AssalMessageSummary>> sendMessage(
    String userId,
    AssalMessageDraft draft,
  ) async {
    sentUserId = userId;
    sentDraft = draft;
    if (sendError) {
      return const AssalError<AssalMessageSummary>(
        'تعذر إرسال الرسالة الآن.',
        kind: AssalErrorKind.network,
        retryable: true,
      );
    }
    messages.add(
      AssalMessageSummary(
        id: 'message-sent',
        conversationId: draft.conversationId,
        senderId: userId,
        body: draft.body,
        sentAt: DateTime(2026, 8, 20, 11, 33),
        isMine: true,
      ),
    );
    return AssalData(messages.last);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
