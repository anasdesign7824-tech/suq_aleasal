import 'package:assalkom_data/demo_repository.dart';

const testCatalogJson = '''
{
  "regions": [{"id":"r1","name_ar":"حضرموت","is_active":true}],
  "stores": [{"id":"s1","merchant_id":"m1","name_ar":"مناحل دوعن","slug":"doani","status":"active","is_verified":true,"followers_count":12}],
  "products": [{"id":"p1","store_id":"s1","merchant_id":"m1","category_id":"c1","subcategory_id":"sub1","subcategory_name_ar":"السدر","category_name_ar":"العسل السائل","name_ar":"سدر يمني من وديانه","product_type":"honey","status":"active","is_featured":true,"grade_levels":[1],"tags":["موثق"],"regions":["حضرموت"],"primary_image_url":""}],
  "banners": [{"id":"b1","title_ar":"الثقة تبدأ من المصدر","body_ar":"منتجات يمنية بمصدر واضح","image_url":"","cta_label_ar":"استكشف","cta_url":"","is_active":true,"sort_order":0}],
  "popular_searches": ["سدر"],
  "reviews": [],
  "comments": [],
  "requests": [],
  "notifications": [],
  "conversations": [],
  "messages": []
}
''';

DemoRepository buildTestDemoRepository() =>
    DemoRepository(loader: const InMemoryDemoCatalogLoader(testCatalogJson));
