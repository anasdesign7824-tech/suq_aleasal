import 'package:assalkom/features/customer/customer_account.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _customer = AssalUserProfile(
  id: 'customer-072',
  nameAr: 'عميل الرسائل',
  role: AssalRole.customer,
);

class _EmptyMessagesRepository implements AssalRepository {
  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => const AssalSession(
        isAuthenticated: true,
        role: AssalRole.customer,
        user: _customer,
      );

  @override
  Future<AssalLoadState<List<AssalConversationSummary>>> listConversations(
    String userId,
  ) async =>
      const AssalEmpty<List<AssalConversationSummary>>('لا توجد محادثات بعد.');

  @override
  Future<AssalLoadState<List<AssalMessageSummary>>> listMessages(
    String conversationId,
  ) async =>
      const AssalEmpty<List<AssalMessageSummary>>('لا توجد رسائل بعد. ابدأ المحادثة برسالة جديدة.');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

final _conversation = AssalConversationSummary(
  id: 'conversation-072',
  storeId: 'store-072',
  storeName: 'مناحل الاختبار',
  lastMessage: '',
  updatedAt: DateTime(2026, 8, 24),
);

void main() {
  testWidgets('TASK 072 preserves the empty conversation list action',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MessagesScreen(repository: _EmptyMessagesRepository()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('لا توجد محادثات بعد.'), findsOneWidget);
    expect(find.text('استكشف المتاجر'), findsOneWidget);
    expect(find.text('تسجيل الدخول لعرض الرسائل'), findsNothing);
  });

  testWidgets('TASK 072 renders an empty authenticated message history',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConversationScreen(
          repository: _EmptyMessagesRepository(),
          conversation: _conversation,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('مناحل الاختبار'), findsAtLeastNWidgets(1));
    expect(
      find.text('لا توجد رسائل بعد. ابدأ المحادثة برسالة جديدة.'),
      findsOneWidget,
    );
    expect(find.byTooltip('إرسال'), findsOneWidget);
    expect(find.text('يلزم تسجيل الدخول للإرسال'), findsNothing);
  });
}
