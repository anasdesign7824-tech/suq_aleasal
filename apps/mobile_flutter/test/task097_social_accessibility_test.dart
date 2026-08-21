import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_social.dart';

void main() {
  testWidgets(
      'comment composer disables duplicate submit and supports keyboard submit',
      (tester) async {
    final repository = _SocialRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body:
                CommentsSection(repository: repository, targetId: 'product-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    await tester.enterText(field, 'تعليق اختبار');
    await tester.pump();

    final sendButton = find.byType(IconButton);
    expect(tester.widget<IconButton>(sendButton).onPressed, isNotNull);
    expect(
      tester.widget<TextField>(field).textInputAction,
      TextInputAction.send,
    );
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    expect(repository.commentCalls, 1);
    expect(tester.widget<TextField>(field).enabled, isFalse);
    expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed, isNull);
    expect(find.byTooltip('جارٍ إرسال التعليق'), findsOneWidget);

    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    expect(repository.commentCalls, 1);

    repository.commentCompleter.complete(
      const AssalData(
        AssalCommentSummary(
          id: 'comment-1',
          targetId: 'product-1',
          authorId: 'user-1',
          authorName: 'عميل الاختبار',
          body: 'تعليق اختبار',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(field).enabled, isTrue);
    expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed, isNull);
  });

  testWidgets(
      'review composer keeps publish disabled until text exists and gates retry',
      (tester) async {
    final repository = _SocialRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: ReviewsSection(
              repository: repository,
              product: _product,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'أضف مراجعتك'));
    await tester.pumpAndSettle();

    final publish = find.widgetWithText(FilledButton, 'نشر');
    expect(tester.widget<FilledButton>(publish).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'مراجعة اختبارية');
    await tester.pump();
    expect(tester.widget<FilledButton>(publish).onPressed, isNotNull);

    await tester.tap(publish);
    await tester.pump();
    expect(repository.reviewCalls, 1);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'جارٍ إرسال المراجعة...'),
          )
          .onPressed,
      isNull,
    );

    repository.reviewCompleter.complete(
      const AssalData(
        AssalReviewSummary(
          id: 'review-1',
          productId: 'product-1',
          storeId: 'store-1',
          authorId: 'user-1',
          rating: 5,
          status: ReviewStatus.pending,
          body: 'مراجعة اختبارية',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, 'أضف مراجعتك'), findsOneWidget);
  });
}

const _product = AssalProductSummary(
  id: 'product-1',
  storeId: 'store-1',
  nameAr: 'عسل اختبار',
  productType: ProductType.honey,
  status: ProductStatus.active,
);

class _SocialRepository implements AssalRepository {
  _SocialRepository()
      : session = const AssalSession(
          isAuthenticated: true,
          role: AssalRole.customer,
          user: AssalUserProfile(
            id: 'user-1',
            nameAr: 'عميل الاختبار',
            email: 'test@example.com',
          ),
        );

  final AssalSession session;
  final Completer<AssalLoadState<AssalCommentSummary>> commentCompleter =
      Completer<AssalLoadState<AssalCommentSummary>>();
  final Completer<AssalLoadState<AssalReviewSummary>> reviewCompleter =
      Completer<AssalLoadState<AssalReviewSummary>>();
  int commentCalls = 0;
  int reviewCalls = 0;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => session;

  @override
  Future<AssalLoadState<List<AssalReviewSummary>>> listReviews(
    String productId,
  ) async =>
      const AssalEmpty<List<AssalReviewSummary>>('لا توجد مراجعات');

  @override
  Future<AssalLoadState<List<AssalCommentSummary>>> listComments(
    String targetId,
  ) async =>
      const AssalEmpty<List<AssalCommentSummary>>('لا توجد تعليقات');

  @override
  Future<AssalLoadState<AssalReviewSummary>> createReview(
    String authorId,
    AssalReviewDraft draft,
  ) {
    reviewCalls++;
    return reviewCompleter.future;
  }

  @override
  Future<AssalLoadState<AssalCommentSummary>> createComment(
    String authorId,
    String authorName,
    String targetId,
    String body,
  ) {
    commentCalls++;
    return commentCompleter.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
