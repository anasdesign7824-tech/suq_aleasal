import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_data/demo_repository.dart';

void main() {
  const catalog = '''
  {
    "regions": [{"id":"r1","name_ar":"حضرموت","is_active":true}],
    "stores": [{"id":"s1","merchant_id":"m1","name_ar":"مناحل دوعن","slug":"doani","status":"active","is_verified":true,"followers_count":12}],
    "products": [{"id":"p1","store_id":"s1","category_id":"c1","subcategory_id":"sub1","subcategory_name_ar":"السدر","category_name_ar":"العسل السائل","name_ar":"سدر دوعني","product_type":"honey","status":"active","is_featured":true,"grade_levels":[1],"tags":["موثق"],"regions":["حضرموت"],"primary_image_url":"assets/logo-internal.svg"}],
    "reviews": [],
    "requests": [],
    "notifications": []
  }
  ''';

  test('customer demo journey remains usable without Supabase', () async {
    final repository = DemoRepository(loader: const InMemoryDemoCatalogLoader(catalog));

    expect((await repository.getSession()).isAuthenticated, isFalse);
    final products = await repository.listProducts(query: const AssalProductQuery(featuredOnly: true));
    expect(products, isA<AssalData<List<AssalProductSummary>>>());
    final stores = await repository.listStores();
    expect(stores, isA<AssalData<List<AssalStoreSummary>>>());
    final filtered = await repository.listProducts(query: const AssalProductQuery(gradeLevel: 1, productType: ProductType.honey, verifiedStoresOnly: true));
    expect(filtered, isA<AssalData<List<AssalProductSummary>>>());

    final auth = await repository.signIn('demo@assalkom.app', 'demo123');
    expect(auth, isA<AssalData<AssalSession>>());
    final session = (auth as AssalData<AssalSession>).value;
    expect(session.isAuthenticated, isTrue);

    final follow = await repository.toggleFollow(session.user!.id, 's1');
    final favorite = await repository.toggleFavorite(session.user!.id, 'p1');
    final like = await repository.toggleLike(session.user!.id, 'p1');
    expect((follow as AssalData<bool>).value, isTrue);
    expect((favorite as AssalData<bool>).value, isTrue);
    expect((like as AssalData<bool>).value, isTrue);

    final request = await repository.createRequest(session.user!.id, const AssalRequestDraft(storeId: 's1', productId: 'p1', subject: 'استفسار عن سدر دوعني', body: 'أرغب في معرفة التوفر وطريقة الاستلام.', quantity: 1, handoffOption: HandoffOption.pickup, deliveryNote: 'التواصل قبل الوصول'));
    expect(request, isA<AssalData<AssalRequestSummary>>());
    final requests = await repository.listRequests(session.user!.id);
    expect(requests, isA<AssalData<List<AssalRequestSummary>>>());

    final review = await repository.createReview(session.user!.id, const AssalReviewDraft(productId: 'p1', storeId: 's1', rating: 5, body: 'تجربة واضحة ومصدر موثق.'));
    final comment = await repository.createComment(session.user!.id, 'عميل عسلكم', 'p1', 'هل يتوفر وزن نصف كيلو؟');
    expect(review, isA<AssalData<AssalReviewSummary>>());
    expect(comment, isA<AssalData<AssalCommentSummary>>());

    final message = await repository.sendMessage(session.user!.id, const AssalMessageDraft(conversationId: 'demo-conversation-s1', body: 'مرحبًا، أحتاج مساعدة في الاختيار.'));
    expect(message, isA<AssalData<AssalMessageSummary>>());
    final messages = await repository.listMessages('demo-conversation-s1');
    expect(messages, isA<AssalData<List<AssalMessageSummary>>>());

    final notifications = await repository.listNotifications(session.user!.id);
    expect(notifications, isA<AssalData<List<AssalNotificationSummary>>>());
  });
}
