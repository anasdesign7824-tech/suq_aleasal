import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_catalog.dart';
import 'package:assalkom/features/customer/customer_social.dart';

const _product = AssalProductSummary(
  id: 'product-1',
  storeId: 'store-1',
  nameAr: 'عسل السدر الجبلي الفاخر',
  productType: ProductType.honey,
  status: ProductStatus.active,
  categoryNameAr: 'عسل السدر',
  price: 15000,
  currencyCode: 'YER',
  availability: 'متوفر',
  ratingAverage: 4.8,
  reviewCount: 128,
  likesCount: 2300,
);

const _store = AssalStoreSummary(
  id: 'store-1',
  merchantId: 'merchant-1',
  nameAr: 'مناحل جبال اليمن',
  slug: 'mountain-hives',
  status: StoreStatus.active,
  regionNameAr: 'إب، اليمن',
);

const _review = AssalReviewSummary(
  id: 'review-1',
  productId: 'product-1',
  storeId: 'store-1',
  authorId: 'user-2',
  authorName: 'محمد اليماني',
  rating: 5,
  status: ReviewStatus.approved,
  body: 'عسل ممتاز وتجربة موفقة.',
);

const _comment = AssalCommentSummary(
  id: 'comment-1',
  targetId: 'product-1',
  authorId: 'user-2',
  authorName: 'علي الحضرمي',
  body: 'تجربة جميلة وأنصح بهذا المنتج.',
);

Future<void> _pumpInteractionTab(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ProductDetailScreen(
        repository: _SocialProductRepository(),
        productId: _product.id,
        initialProduct: _product,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.drag(
    find.byType(NestedScrollView),
    const Offset(0, -1500),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('التقييمات والتفاعل'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('التقييمات والتفاعل'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 016 renders the integrated social product tab',
      (tester) async {
    await _pumpInteractionTab(tester);

    expect(find.text('التقييم العام'), findsOneWidget);
    expect(find.text('4.8'), findsNWidgets(2));
    expect(find.text('من 5 · 128 تقييم'), findsOneWidget);
    expect(find.text('إعجاب'), findsOneWidget);
    expect(find.text('حفظ'), findsOneWidget);
    expect(find.text('المراجعات'), findsOneWidget);
    expect(find.text('محمد اليماني'), findsOneWidget);
    expect(find.text('التعليقات'), findsOneWidget);
    expect(find.text('علي الحضرمي'), findsOneWidget);
    expect(find.text('اكتب تعليقًا مفيدًا'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'أضف مراجعتك'), findsOneWidget);
  });

  testWidgets('TASK 016 submits a comment and keeps the local result visible',
      (tester) async {
    final repository = _SocialProductRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body:
                CommentsSection(repository: repository, targetId: _product.id),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    await tester.enterText(field, 'تعليق جديد للتاجر');
    await tester.pump();
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(repository.commentCalls, 1);
    expect(find.text('تعليق جديد للتاجر'), findsOneWidget);
    expect(find.text('تم حفظ التعليق والمزامنة مع التاجر.'), findsOneWidget);
  });

  testWidgets('TASK 016 submits a review and exposes pending moderation state',
      (tester) async {
    final repository = _SocialProductRepository();
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

    await tester.tap(find.widgetWithText(OutlinedButton, 'أضف مراجعتك'));
    await tester.pumpAndSettle();
    final body = find.byType(TextField);
    await tester.enterText(body, 'مراجعة جديدة مفيدة');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'نشر'));
    await tester.pumpAndSettle();

    expect(repository.reviewCalls, 1);
    expect(find.text('مراجعة جديدة مفيدة'), findsOneWidget);
    expect(
      find.text('قيد المراجعة؛ سيظهر للآخرين بعد الاعتماد.'),
      findsOneWidget,
    );
  });

  testWidgets('TASK 016 records the social interaction visual contract',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 2560);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpInteractionTab(tester);
    await expectLater(
      find.byType(ProductDetailScreen),
      matchesGoldenFile(
        'visual_reference/task016_product_detail_social_reference_360x640.png',
      ),
    );
  });
}

class _SocialProductRepository implements AssalRepository {
  final session = const AssalSession(
    isAuthenticated: true,
    role: AssalRole.customer,
    user: AssalUserProfile(
      id: 'user-1',
      nameAr: 'عميل عسلكم',
      email: 'customer@example.com',
    ),
  );

  int commentCalls = 0;
  int reviewCalls = 0;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => session;

  @override
  Future<AssalLoadState<void>> trackProductView(String productId) async =>
      const AssalData<void>(null);

  @override
  Future<AssalLoadState<AssalProductInteractionState>>
      loadProductInteractionState(String userId, String productId) async =>
          const AssalData(AssalProductInteractionState());

  @override
  Future<AssalLoadState<AssalProductSummary>> getProduct(
          String productId) async =>
      const AssalData(_product);

  @override
  Future<AssalLoadState<AssalStoreSummary>> getStore(String storeId) async =>
      const AssalData(_store);

  @override
  Future<AssalLoadState<List<AssalReviewSummary>>> listReviews(
    String productId,
  ) async =>
      const AssalData(<AssalReviewSummary>[_review]);

  @override
  Future<AssalLoadState<List<AssalCommentSummary>>> listComments(
    String targetId,
  ) async =>
      const AssalData(<AssalCommentSummary>[_comment]);

  @override
  Future<AssalLoadState<AssalCommentSummary>> createComment(
    String userId,
    String userName,
    String targetId,
    String body,
  ) async {
    commentCalls++;
    return AssalData(
      AssalCommentSummary(
        id: 'comment-local',
        targetId: targetId,
        authorId: userId,
        authorName: userName,
        body: body,
      ),
    );
  }

  @override
  Future<AssalLoadState<AssalReviewSummary>> createReview(
    String userId,
    AssalReviewDraft draft,
  ) async {
    reviewCalls++;
    return AssalData(
      AssalReviewSummary(
        id: 'review-local',
        productId: draft.productId,
        storeId: draft.storeId,
        authorId: userId,
        authorName: 'عميل عسلكم',
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
