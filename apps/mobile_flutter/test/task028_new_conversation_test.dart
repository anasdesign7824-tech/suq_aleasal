import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_account.dart';
import 'package:assalkom/features/customer/customer_catalog.dart';

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
  deliveryOptions: <String>['توصيل داخل المدينة'],
);

final _conversation = AssalConversationSummary(
  id: 'conversation-1',
  storeId: 'store-1',
  storeName: 'مناحل جبال اليمن',
  lastMessage: 'رسالة اختبارية',
  updatedAt: DateTime(2026, 8, 20, 11, 32),
);

Future<void> _pumpSheet(
  WidgetTester tester,
  _NewConversationRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => showModalBottomSheet<String>(
              context: tester.element(find.byType(FilledButton)),
              isScrollControlled: true,
              builder: (_) => const NewConversationSheet(store: _store),
            ),
            child: const Text('فتح النافذة'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('فتح النافذة'));
  await tester.pumpAndSettle();
}

Future<void> _pumpStore(
  WidgetTester tester,
  _NewConversationRepository repository,
) async {
  tester.view.physicalSize = const Size(800, 1400);
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

void main() {
  testWidgets('TASK 028 validates first message and supports cancel',
      (tester) async {
    await _pumpSheet(tester, _NewConversationRepository());

    expect(find.text('مراسلة التاجر'), findsOneWidget);
    expect(find.text('مناحل جبال اليمن'), findsOneWidget);
    expect(find.text('أول رسالة'), findsOneWidget);
    expect(find.text('بدء المحادثة'), findsOneWidget);
    await tester.tap(find.text('بدء المحادثة'));
    await tester.pump();
    expect(find.text('اكتب رسالتك الأولى للمتجر.'), findsOneWidget);

    await tester.tap(find.byTooltip('إلغاء'));
    await tester.pumpAndSettle();
    expect(find.text('مراسلة التاجر'), findsNothing);
  });

  testWidgets('TASK 028 creates conversation and sends first message',
      (tester) async {
    final repository = _NewConversationRepository();
    await _pumpStore(tester, repository);

    await tester.tap(find.text('التواصل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مراسلة التاجر'));
    await tester.pumpAndSettle();
    expect(find.byType(NewConversationSheet), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'هل يتوفر عسل السدر؟');
    await tester.tap(find.text('بدء المحادثة'));
    await tester.pumpAndSettle();

    expect(repository.createdUserId, 'customer-1');
    expect(repository.createdStoreId, 'store-1');
    expect(repository.sentUserId, 'customer-1');
    expect(repository.sentDraft?.conversationId, 'conversation-1');
    expect(repository.sentDraft?.body, 'هل يتوفر عسل السدر؟');
    expect(find.byType(ConversationScreen), findsOneWidget);
  });

  testWidgets('TASK 028 reports create conversation error without navigation',
      (tester) async {
    final repository = _NewConversationRepository(createError: true);
    await _pumpStore(tester, repository);

    await tester.tap(find.text('التواصل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مراسلة التاجر'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'استفسار عن التوفر');
    await tester.tap(find.text('بدء المحادثة'));
    await tester.pumpAndSettle();

    expect(find.text('تعذر بدء المحادثة الآن.'), findsOneWidget);
    expect(find.byType(ConversationScreen), findsNothing);
  });

  testWidgets('TASK 028 keeps guest action behind the session gate',
      (tester) async {
    final repository = _NewConversationRepository(authenticated: false);
    await _pumpStore(tester, repository);

    await tester.tap(find.text('التواصل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مراسلة التاجر'));
    await tester.pumpAndSettle();
    expect(find.text('هذه الميزة تحتاج حسابًا'), findsOneWidget);
    expect(find.byType(NewConversationSheet), findsNothing);
  });

  testWidgets('TASK 028 records the first-conversation visual contract',
      (tester) async {
    await _pumpSheet(tester, _NewConversationRepository());
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(NewConversationSheet),
      matchesGoldenFile(
        'visual_reference/task028_new_conversation_reference_360x780.png',
      ),
    );
  });
}

class _NewConversationRepository implements AssalRepository {
  _NewConversationRepository({
    this.createError = false,
    this.authenticated = true,
  });

  final bool createError;
  final bool authenticated;
  String? createdUserId;
  String? createdStoreId;
  String? sentUserId;
  AssalMessageDraft? sentDraft;
  final messages = <AssalMessageSummary>[];

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
  Future<AssalLoadState<AssalStoreSummary>> getStore(String storeId) async =>
      const AssalData(_store);

  @override
  Future<AssalLoadState<List<AssalStoreSummary>>> listFollowedStores(
    String userId,
  ) async =>
      const AssalData(<AssalStoreSummary>[]);

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({
    AssalProductQuery? query,
  }) async =>
      const AssalData(<AssalProductSummary>[]);

  @override
  Future<AssalLoadState<AssalConversationSummary>> createConversation(
    String userId,
    String storeId,
  ) async {
    createdUserId = userId;
    createdStoreId = storeId;
    if (createError) {
      return const AssalError<AssalConversationSummary>(
        'تعذر بدء المحادثة الآن.',
        kind: AssalErrorKind.server,
        retryable: true,
      );
    }
    return AssalData(_conversation);
  }

  @override
  Future<AssalLoadState<AssalMessageSummary>> sendMessage(
    String userId,
    AssalMessageDraft draft,
  ) async {
    sentUserId = userId;
    sentDraft = draft;
    final message = AssalMessageSummary(
      id: 'message-1',
      conversationId: draft.conversationId,
      senderId: userId,
      body: draft.body,
      sentAt: DateTime(2026, 8, 20, 11, 32),
      isMine: true,
    );
    messages.add(message);
    return AssalData(message);
  }

  @override
  Future<AssalLoadState<List<AssalMessageSummary>>> listMessages(
    String conversationId,
  ) async =>
      AssalData(List<AssalMessageSummary>.from(messages));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
