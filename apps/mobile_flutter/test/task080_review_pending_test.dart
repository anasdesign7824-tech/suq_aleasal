import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_social.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _reviewProduct = AssalProductSummary(
  id: 'product-080',
  storeId: 'store-080',
  nameAr: 'عسل اختبار التقييم',
  productType: ProductType.honey,
  status: ProductStatus.active,
  ratingAverage: 4.5,
  reviewCount: 3,
);

class _PendingReviewRepository implements AssalRepository {
  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => const AssalSession(
        isAuthenticated: true,
        role: AssalRole.customer,
        user: AssalUserProfile(
          id: 'customer-080',
          nameAr: 'عميل الاختبار',
        ),
      );

  @override
  Future<AssalLoadState<List<AssalReviewSummary>>> listReviews(
    String productId,
  ) async => const AssalEmpty<List<AssalReviewSummary>>('لا توجد مراجعات');

  @override
  Future<AssalLoadState<AssalReviewSummary>> createReview(
    String authorId,
    AssalReviewDraft draft,
  ) async => AssalData(
        AssalReviewSummary(
          id: 'review-080',
          productId: draft.productId,
          storeId: draft.storeId,
          authorId: authorId,
          authorName: 'عميل الاختبار',
          rating: draft.rating,
          status: ReviewStatus.pending,
          body: draft.body,
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  testWidgets('TASK 080 shows submitted review as pending moderation',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: ReviewsSection(
              repository: _PendingReviewRepository(),
              product: _reviewProduct,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'أضف مراجعتك'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'تقييم ينتظر المراجعة');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'نشر'));
    await tester.pumpAndSettle();

    expect(find.text('تقييم ينتظر المراجعة'), findsOneWidget);
    expect(
      find.text('قيد المراجعة؛ سيظهر للآخرين بعد الاعتماد.'),
      findsOneWidget,
    );
    expect(
      find.text('تم حفظ تقييمك وسيظهر للآخرين بعد الاعتماد.'),
      findsOneWidget,
    );
  });
}
