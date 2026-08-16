import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_data/demo_repository.dart';
import 'package:assalkom_data/repository_factory.dart';

void main() {
  const catalog = '''
  {
    "regions": [{"id":"r1","name_ar":"حضرموت","is_active":true}],
    "stores": [{"id":"s1","merchant_id":"m1","name_ar":"متجر تجريبي","slug":"demo","status":"active","is_verified":true}],
    "products": [{"id":"p1","store_id":"s1","category_id":"c1","name_ar":"سدر دوعني","product_type":"honey","status":"active","is_featured":true,"rating_average":4.8,"review_count":2,"subcategory_id":"sub1","subcategory_name_ar":"السدر","region_id":"r1","province_id":"pvn1","origin_country":"اليمن","certifications":["cert1"],"merchant_id":"m1","processing_method_ar":"خام","processing_status_ar":"مصفى","packaging_label_ar":"زجاج 500غ","availability":"متاح","price":22000,"currency_code":"YER"}],
    "reviews": [],
    "comments": [{"id":"c1","target_id":"p1","author_id":"u1","author_name":"عميل","body":"مفيد","created_at":"2026-08-01T10:00:00Z"}],
    "requests": [],
    "notifications": [],
    "banners": [{"id":"b1","title_ar":"اكتشف","description_ar":"مصدر موثق","cta_label_ar":"ابدأ","image_url":"logo.svg","sort_order":1,"is_active":true}],
    "popular_searches": ["سدر دوعني"],
    "conversations": [{"id":"cv1","store_id":"s1","store_name":"متجر تجريبي","last_message":"مرحبًا","updated_at":"2026-08-01T10:00:00Z"}],
    "messages": [{"id":"msg1","conversation_id":"cv1","sender_id":"m1","body":"مرحبًا","sent_at":"2026-08-01T10:00:00Z"}]
  }
  ''';

  test('DemoRepository returns demo data and empty states', () async {
    final repository = DemoRepository(loader: const InMemoryDemoCatalogLoader(catalog));
    final products = await repository.listProducts(query: const AssalProductQuery(featuredOnly: true));
    expect(repository.mode, AssalDataSourceMode.demo);
    expect(products, isA<AssalData<List<AssalProductSummary>>>());
    final honeyMatrix = await repository.listProducts(query: const AssalProductQuery(regionId: 'r1', provinceId: 'pvn1', originCountry: 'اليمن', certificateId: 'cert1', processingMethod: 'خام', processingStatus: 'مصفى', packaging: 'زجاج 500غ', availability: 'متاح', merchantId: 'm1', minRating: 4, minPrice: 20000, maxPrice: 25000));
    expect((honeyMatrix as AssalData<List<AssalProductSummary>>).value, hasLength(1));
    final reviews = await repository.listReviews('p1');
    expect(reviews, isA<AssalEmpty<List<AssalReviewSummary>>>());
    await repository.signIn('demo@assalkom.app', 'demo123');
    await repository.toggleFavorite('demo-customer', 'p1');
    final favoriteTaxonomies = await repository.listFavoriteTaxonomies('demo-customer');
    expect((favoriteTaxonomies as AssalData<List<AssalTaxonomy>>).value, hasLength(1));
    final banners = await repository.listBanners();
    expect((banners as AssalData<List<AssalBannerSummary>>).value, hasLength(1));
    final searches = await repository.listPopularSearches();
    expect((searches as AssalData<List<String>>).value, contains('سدر دوعني'));
    final comments = await repository.listComments('p1');
    expect(comments, isA<AssalData<List<AssalCommentSummary>>>());
    final conversations = await repository.listConversations('demo-customer');
    expect(conversations, isA<AssalData<List<AssalConversationSummary>>>());
  });

  test('Factory rejects production without an explicit gateway', () {
    expect(() => const AssalRepositoryFactory().create(mode: AssalDataSourceMode.production, demoLoader: const InMemoryDemoCatalogLoader(catalog)), throwsA(isA<ProductionRepositoryNotConfigured>()));
  });
}
