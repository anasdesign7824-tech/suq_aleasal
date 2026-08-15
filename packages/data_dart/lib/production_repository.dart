import '../../contracts_dart/lib/assal_domain.dart';
import 'assal_repository.dart';

class ProductionRepository implements AssalRepository {
  const ProductionRepository({required ProductionQueryGateway gateway}) : _gateway = gateway;

  final ProductionQueryGateway _gateway;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.production;

  @override
  Future<AssalLoadState<List<AssalRegion>>> listRegions() async {
    final rows = await _gateway.select('regions', filters: const {'is_active': true});
    final values = rows.map(AssalRegion.fromJson).toList(growable: false);
    return values.isEmpty ? const AssalEmpty('لا توجد مناطق متاحة') : AssalData(values);
  }

  @override
  Future<AssalLoadState<List<AssalTaxonomy>>> listTaxonomy() async {
    final rows = await _gateway.select('honey_taxonomy', filters: const {'is_active': true});
    final values = rows.map(AssalTaxonomy.fromJson).toList(growable: false);
    return values.isEmpty ? const AssalEmpty('لا توجد تصنيفات متاحة') : AssalData(values);
  }

  @override
  Future<AssalLoadState<List<AssalStoreSummary>>> listStores({String? regionId}) async {
    final rows = await _gateway.select('stores', filters: {
      'status': 'active',
      if (regionId != null) 'region_id': regionId,
    });
    final values = rows.map(AssalStoreSummary.fromJson).toList(growable: false);
    return values.isEmpty ? const AssalEmpty('لا توجد متاجر متاحة') : AssalData(values);
  }

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({AssalProductQuery query = const AssalProductQuery()}) async {
    final rows = await _gateway.select('products', filters: {
      'status': 'active',
      if (query.storeId != null) 'store_id': query.storeId,
      if (query.categoryId != null) 'category_id': query.categoryId,
    });
    var values = rows.map(AssalProductSummary.fromJson).toList(growable: false);
    if (query.featuredOnly) values = values.where((item) => item.isFeatured).toList(growable: false);
    final search = query.search?.trim().toLowerCase();
    if (search != null && search.isNotEmpty) values = values.where((item) => item.nameAr.toLowerCase().contains(search)).toList(growable: false);
    return values.isEmpty ? const AssalEmpty('لا توجد منتجات مطابقة للبحث') : AssalData(values);
  }

  @override
  Future<AssalLoadState<AssalProductSummary>> getProduct(String productId) async {
    final rows = await _gateway.select('products', filters: {'id': productId, 'status': 'active'});
    if (rows.isEmpty) return const AssalError('المنتج غير موجود', code: 'not_found');
    return AssalData(AssalProductSummary.fromJson(rows.first));
  }

  @override
  Future<AssalLoadState<List<AssalReviewSummary>>> listReviews(String productId) async {
    final rows = await _gateway.select('reviews', filters: {'product_id': productId, 'status': 'approved'});
    final values = rows.map(AssalReviewSummary.fromJson).toList(growable: false);
    return values.isEmpty ? const AssalEmpty('لا توجد مراجعات بعد') : AssalData(values);
  }

  @override
  Future<AssalLoadState<List<AssalRequestSummary>>> listRequests(String requesterId) async {
    final rows = await _gateway.select('requests', filters: {'requester_id': requesterId});
    final values = rows.map(AssalRequestSummary.fromJson).toList(growable: false);
    return values.isEmpty ? const AssalEmpty('لا توجد طلبات تواصل') : AssalData(values);
  }

  @override
  Future<AssalLoadState<List<AssalNotificationSummary>>> listNotifications(String userId) async {
    final rows = await _gateway.select('notifications', filters: {'user_id': userId});
    final values = rows.map(AssalNotificationSummary.fromJson).toList(growable: false);
    return values.isEmpty ? const AssalEmpty('لا توجد إشعارات جديدة') : AssalData(values);
  }
}
