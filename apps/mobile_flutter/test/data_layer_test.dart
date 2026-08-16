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
    "products": [{"id":"p1","store_id":"s1","category_id":"c1","name_ar":"سدر دوعني","product_type":"honey","status":"active","is_featured":true,"rating_average":4.8,"review_count":2,"subcategory_id":"sub1","subcategory_name_ar":"السدر"}],
    "reviews": [],
    "requests": [],
    "notifications": []
  }
  ''';

  test('DemoRepository returns demo data and empty states', () async {
    final repository = DemoRepository(loader: const InMemoryDemoCatalogLoader(catalog));
    final products = await repository.listProducts(query: const AssalProductQuery(featuredOnly: true));
    expect(repository.mode, AssalDataSourceMode.demo);
    expect(products, isA<AssalData<List<AssalProductSummary>>>());
    final reviews = await repository.listReviews('p1');
    expect(reviews, isA<AssalEmpty<List<AssalReviewSummary>>>());
  });

  test('Factory rejects production without an explicit gateway', () {
    expect(() => const AssalRepositoryFactory().create(mode: AssalDataSourceMode.production, demoLoader: const InMemoryDemoCatalogLoader(catalog)), throwsA(isA<ProductionRepositoryNotConfigured>()));
  });
}
