import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_social.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _PendingCommentRepository implements AssalRepository {
  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => const AssalSession(
        isAuthenticated: true,
        role: AssalRole.customer,
        user: AssalUserProfile(
          id: 'customer-079',
          nameAr: 'عميل الاختبار',
        ),
      );

  @override
  Future<AssalLoadState<List<AssalCommentSummary>>> listComments(
    String targetId,
  ) async => const AssalEmpty<List<AssalCommentSummary>>('لا توجد تعليقات');

  @override
  Future<AssalLoadState<AssalCommentSummary>> createComment(
    String authorId,
    String authorName,
    String targetId,
    String body,
  ) async => AssalData(
        AssalCommentSummary(
          id: 'comment-079',
          targetId: targetId,
          authorId: authorId,
          authorName: authorName,
          body: body,
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  testWidgets('TASK 079 shows submitted comment as pending moderation',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: CommentsSection(
              repository: _PendingCommentRepository(),
              targetId: 'product-079',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'تعليق ينتظر المراجعة');
    await tester.pump();
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.text('تعليق ينتظر المراجعة'), findsOneWidget);
    expect(
      find.text('قيد المراجعة؛ سيظهر للآخرين بعد الاعتماد.'),
      findsOneWidget,
    );
    expect(
      find.text('تم حفظ تعليقك؛ تتم مراجعته قبل ظهوره للآخرين.'),
      findsOneWidget,
    );
  });
}
