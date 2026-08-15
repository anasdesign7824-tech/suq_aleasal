import '../../contracts_dart/lib/assal_domain.dart';

enum AssalDataSourceMode { demo, production }

class AssalProductQuery {
  const AssalProductQuery({
    this.categoryId,
    this.storeId,
    this.search,
    this.featuredOnly = false,
  });

  final String? categoryId;
  final String? storeId;
  final String? search;
  final bool featuredOnly;
}

abstract interface class AssalRepository {
  AssalDataSourceMode get mode;

  Future<AssalLoadState<List<AssalRegion>>> listRegions();
  Future<AssalLoadState<List<AssalTaxonomy>>> listTaxonomy();
  Future<AssalLoadState<List<AssalStoreSummary>>> listStores({String? regionId});
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({AssalProductQuery query = const AssalProductQuery()});
  Future<AssalLoadState<AssalProductSummary>> getProduct(String productId);
  Future<AssalLoadState<List<AssalReviewSummary>>> listReviews(String productId);
  Future<AssalLoadState<List<AssalRequestSummary>>> listRequests(String requesterId);
  Future<AssalLoadState<List<AssalNotificationSummary>>> listNotifications(String userId);
}

abstract interface class DemoCatalogLoader {
  Future<String> loadJson();
}

abstract interface class ProductionQueryGateway {
  Future<List<Map<String, Object?>>> select(String table, {Map<String, Object?> filters = const <String, Object?>{}});
}

class ProductionRepositoryNotConfigured implements Exception {
  const ProductionRepositoryNotConfigured();

  @override
  String toString() => 'Production repository requires an explicit Supabase gateway configuration.';
}
