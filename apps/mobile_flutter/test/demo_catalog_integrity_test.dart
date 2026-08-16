import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/demo_repository.dart';

void main() {
  test('real demo catalog has rich linked discovery data', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final catalog = await rootBundle.loadString('assets/demo_catalog.json');
    final repository = DemoRepository(loader: InMemoryDemoCatalogLoader(catalog));
    final regions = await repository.listRegions();
    final stores = await repository.listStores();
    final products = await repository.listProducts();
    final taxonomy = await repository.listTaxonomy();
    final banners = await repository.listBanners();
    final searches = await repository.listPopularSearches();

    expect((regions as AssalData<List<AssalRegion>>).value.length, greaterThanOrEqualTo(10));
    final storeValues = (stores as AssalData<List<AssalStoreSummary>>).value;
    expect(storeValues.length, greaterThanOrEqualTo(10));
    final productValues = (products as AssalData<List<AssalProductSummary>>).value;
    final storeIds = storeValues.map((store) => store.id).toSet();
    expect(productValues.length, greaterThanOrEqualTo(40));
    expect(productValues.every((product) => storeIds.contains(product.storeId)), isTrue);
    expect((taxonomy as AssalData<List<AssalTaxonomy>>).value.length, greaterThanOrEqualTo(10));
    expect((banners as AssalData<List<AssalBannerSummary>>).value.length, 5);
    expect((searches as AssalData<List<String>>).value.length, greaterThanOrEqualTo(10));

    final catalogMap = jsonDecode(catalog) as Map<String, dynamic>;
    final reviewProductId = ((catalogMap['reviews'] as List).first as Map<String, dynamic>)['product_id'] as String;
    final reviews = await repository.listReviews(reviewProductId);
    expect(reviews, isA<AssalData<List<AssalReviewSummary>>>());
    final commentTargetId = ((catalogMap['comments'] as List).first as Map<String, dynamic>)['target_id'] as String;
    final comments = await repository.listComments(commentTargetId);
    expect(comments, isA<AssalData<List<AssalCommentSummary>>>());
    await repository.signIn('demo@assalkom.app', 'demo123');
    final requests = await repository.listRequests('demo-customer');
    final notifications = await repository.listNotifications('demo-customer');
    final conversations = await repository.listConversations('demo-customer');
    expect((requests as AssalData<List<AssalRequestSummary>>).value.length, greaterThanOrEqualTo(6));
    expect((notifications as AssalData<List<AssalNotificationSummary>>).value.length, greaterThanOrEqualTo(4));
    final conversationValues = (conversations as AssalData<List<AssalConversationSummary>>).value;
    expect(conversationValues.length, greaterThanOrEqualTo(3));
    final messages = await repository.listMessages(conversationValues.first.id);
    expect(messages, isA<AssalData<List<AssalMessageSummary>>>());
  });
}
