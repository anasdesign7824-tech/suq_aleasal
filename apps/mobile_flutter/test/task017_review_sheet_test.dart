import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_social.dart';

const _product = AssalProductSummary(
  id: 'product-1',
  storeId: 'store-1',
  nameAr: 'عسل السدر الجبلي الفاخر',
  productType: ProductType.honey,
  status: ProductStatus.active,
  ratingAverage: 4.8,
  reviewCount: 128,
);

Future<void> _pumpReviews(
  WidgetTester tester,
  _ReviewRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: ReviewsSection(repository: repository, product: _product),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 017 renders the complete review composer contract',
      (tester) async {
    final repository = _ReviewRepository();
    await _pumpReviews(tester, repository);

    await tester.tap(find.widgetWithText(OutlinedButton, 'أضف مراجعتك'));
    await tester.pumpAndSettle();

    expect(find.text('مراجعتك'), findsOneWidget);
    expect(find.text('اختر تقييمك من 1 إلى 5 نجوم'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNWidgets(5));
    expect(find.text('شارك ما يفيد الآخرين'), findsOneWidget);
    expect(find.text('إلغاء'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'نشر'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'نشر'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('TASK 017 selects a rating and publishes a pending review',
      (tester) async {
    final repository = _ReviewRepository();
    await _pumpReviews(tester, repository);

    await tester.tap(find.widgetWithText(OutlinedButton, 'أضف مراجعتك'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 ★'));
    await tester.enterText(find.byType(TextField), 'مراجعة مفيدة للتجربة');
    await tester.pump();

    final publish = find.widgetWithText(FilledButton, 'نشر');
    expect(tester.widget<FilledButton>(publish).onPressed, isNotNull);
    await tester.tap(publish);
    await tester.pumpAndSettle();

    expect(repository.reviewCalls, 1);
    expect(repository.lastDraft?.rating, 3);
    expect(repository.lastDraft?.body, 'مراجعة مفيدة للتجربة');
    expect(find.text('مراجعة مفيدة للتجربة'), findsOneWidget);
    expect(
      find.text('قيد المراجعة؛ سيظهر للآخرين بعد الاعتماد.'),
      findsOneWidget,
    );
  });

  testWidgets('TASK 017 cancels without sending a review', (tester) async {
    final repository = _ReviewRepository();
    await _pumpReviews(tester, repository);

    await tester.tap(find.widgetWithText(OutlinedButton, 'أضف مراجعتك'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    expect(repository.reviewCalls, 0);
    expect(find.text('مراجعتك'), findsNothing);
  });

  testWidgets('TASK 017 records the review sheet visual contract',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _ReviewRepository();
    await _pumpReviews(tester, repository);
    await tester.tap(find.widgetWithText(OutlinedButton, 'أضف مراجعتك'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile(
        'visual_reference/task017_review_sheet_reference_360x780.png',
      ),
    );
  });
}

class _ReviewRepository implements AssalRepository {
  final session = const AssalSession(
    isAuthenticated: true,
    role: AssalRole.customer,
    user: AssalUserProfile(
      id: 'user-1',
      nameAr: 'عميل الاختبار',
      email: 'review@example.com',
    ),
  );

  int reviewCalls = 0;
  AssalReviewDraft? lastDraft;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => session;

  @override
  Future<AssalLoadState<List<AssalReviewSummary>>> listReviews(
    String productId,
  ) async =>
      const AssalEmpty<List<AssalReviewSummary>>('لا توجد مراجعات بعد.');

  @override
  Future<AssalLoadState<AssalReviewSummary>> createReview(
    String userId,
    AssalReviewDraft draft,
  ) async {
    reviewCalls++;
    lastDraft = draft;
    return AssalData(
      AssalReviewSummary(
        id: 'review-local',
        productId: draft.productId,
        storeId: draft.storeId,
        authorId: userId,
        authorName: 'عميل الاختبار',
        rating: draft.rating,
        status: ReviewStatus.pending,
        body: draft.body,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
