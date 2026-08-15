import 'dart:convert';

import '../../contracts_dart/lib/assal_domain.dart';
import 'assal_repository.dart';

class InMemoryDemoCatalogLoader implements DemoCatalogLoader {
  const InMemoryDemoCatalogLoader(this.catalogJson);

  final String catalogJson;

  @override
  Future<String> loadJson() async => catalogJson;
}

class DemoRepository implements AssalRepository {
  DemoRepository({required DemoCatalogLoader loader}) : _loader = loader;

  final DemoCatalogLoader _loader;
  Map<String, Object?>? _catalog;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  Future<Map<String, Object?>> _readCatalog() async {
    final cached = _catalog;
    if (cached != null) return cached;
    final decoded = jsonDecode(await _loader.loadJson()) as Map;
    _catalog = decoded.cast<String, Object?>();
    return _catalog!;
  }

  List<Map<String, Object?>> _list(Map<String, Object?> catalog, String key) {
    final value = catalog[key];
    if (value is! List) return const <Map<String, Object?>>[];
    return value.whereType<Map>().map((item) => item.cast<String, Object?>()).toList(growable: false);
  }

  @override
  Future<AssalLoadState<List<AssalRegion>>> listRegions() async {
    final regions = _list(await _readCatalog(), 'regions').map(AssalRegion.fromJson).toList(growable: false);
    return regions.isEmpty ? const AssalEmpty('لا توجد مناطق تجريبية متاحة') : AssalData(regions);
  }

  @override
  Future<AssalLoadState<List<AssalTaxonomy>>> listTaxonomy() async {
    final values = _list(await _readCatalog(), 'products')
        .where((item) => item['subcategory_id'] != null)
        .map((item) => AssalTaxonomy(
              id: item['subcategory_id']! as String,
              code: item['subcategory_id']! as String,
              nameAr: item['subcategory_name_ar']! as String,
              nameEn: null,
              description: null,
              metadata: const <String, Object?>{},
            ))
        .fold<List<AssalTaxonomy>>(<AssalTaxonomy>[], (list, value) {
              if (list.any((item) => item.id == value.id)) return list;
              return [...list, value];
            });
    return values.isEmpty ? const AssalEmpty('لا توجد تصنيفات تجريبية') : AssalData(values);
  }

  @override
  Future<AssalLoadState<List<AssalStoreSummary>>> listStores({String? regionId}) async {
    var stores = _list(await _readCatalog(), 'stores');
    if (regionId != null) stores = stores.where((item) => item['region_id'] == regionId).toList(growable: false);
    final mapped = stores.map(AssalStoreSummary.fromJson).toList(growable: false);
    return mapped.isEmpty ? const AssalEmpty('لا توجد متاجر ضمن هذا الاختيار') : AssalData(mapped);
  }

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({AssalProductQuery query = const AssalProductQuery()}) async {
    var products = _list(await _readCatalog(), 'products');
    if (query.categoryId != null) products = products.where((item) => item['category_id'] == query.categoryId).toList(growable: false);
    if (query.storeId != null) products = products.where((item) => item['store_id'] == query.storeId).toList(growable: false);
    if (query.featuredOnly) products = products.where((item) => item['is_featured'] == true).toList(growable: false);
    final search = query.search?.trim().toLowerCase();
    if (search != null && search.isNotEmpty) {
      products = products.where((item) => (item['name_ar'] as String? ?? '').toLowerCase().contains(search)).toList(growable: false);
    }
    final mapped = products.map(AssalProductSummary.fromJson).toList(growable: false);
    return mapped.isEmpty ? const AssalEmpty('لا توجد منتجات مطابقة للبحث') : AssalData(mapped);
  }

  @override
  Future<AssalLoadState<AssalProductSummary>> getProduct(String productId) async {
    final products = _list(await _readCatalog(), 'products');
    final match = products.where((item) => item['id'] == productId).toList(growable: false);
    if (match.isEmpty) return const AssalError('المنتج غير موجود في البيانات التجريبية', code: 'not_found');
    return AssalData(AssalProductSummary.fromJson(match.first));
  }

  @override
  Future<AssalLoadState<List<AssalReviewSummary>>> listReviews(String productId) async {
    final reviews = _list(await _readCatalog(), 'reviews').where((item) => item['product_id'] == productId).map(AssalReviewSummary.fromJson).toList(growable: false);
    return reviews.isEmpty ? const AssalEmpty('لا توجد مراجعات بعد') : AssalData(reviews);
  }

  @override
  Future<AssalLoadState<List<AssalRequestSummary>>> listRequests(String requesterId) async {
    final requests = _list(await _readCatalog(), 'requests').where((item) => item['requester_id'] == requesterId).map(AssalRequestSummary.fromJson).toList(growable: false);
    return requests.isEmpty ? const AssalEmpty('لا توجد طلبات تواصل') : AssalData(requests);
  }

  @override
  Future<AssalLoadState<List<AssalNotificationSummary>>> listNotifications(String userId) async {
    final notifications = _list(await _readCatalog(), 'notifications').where((item) => item['user_id'] == userId).map(AssalNotificationSummary.fromJson).toList(growable: false);
    return notifications.isEmpty ? const AssalEmpty('لا توجد إشعارات جديدة') : AssalData(notifications);
  }
}
