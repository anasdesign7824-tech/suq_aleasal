import 'package:assalkom_contracts/assal_domain.dart';
import 'assal_repository.dart';

class ProductionRepository implements AssalRepository {
  const ProductionRepository({required ProductionQueryGateway gateway}) : _gateway = gateway;
  final ProductionQueryGateway _gateway;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.production;

  AssalLoadState<List<T>> _state<T>(List<T> values, String emptyMessage) => values.isEmpty ? AssalEmpty<List<T>>(emptyMessage) : AssalData<List<T>>(values);

  @override
  Future<AssalSession> getSession() async => AssalSession.guest;

  @override
  Future<AssalLoadState<List<AssalRegion>>> listRegions() async {
    final rows = await _gateway.select('regions', filters: const {'is_active': true});
    final values = rows.map(AssalRegion.fromJson).toList(growable: false);
    return _state(values, 'لا توجد مناطق متاحة');
  }

  @override
  Future<AssalLoadState<List<AssalTaxonomy>>> listTaxonomy() async {
    final rows = await _gateway.select('honey_taxonomy', filters: const {'is_active': true});
    final values = rows.map(AssalTaxonomy.fromJson).toList(growable: false);
    return _state(values, 'لا توجد تصنيفات متاحة');
  }

  @override
  Future<AssalLoadState<List<AssalBannerSummary>>> listBanners() async {
    final rows = await _gateway.select('banners', filters: const {'is_active': true});
    final values = rows.map(AssalBannerSummary.fromJson).toList(growable: false)..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return _state(values, 'لا توجد حملات استكشاف متاحة');
  }

  @override
  Future<AssalLoadState<List<String>>> listPopularSearches() async {
    final rows = await _gateway.select('popular_searches', filters: const {'is_active': true});
    final values = rows.map((row) => row['term_ar']).whereType<String>().toList(growable: false);
    return _state(values, 'لا توجد اقتراحات بحث متاحة');
  }

  @override
  Future<AssalLoadState<List<AssalStoreSummary>>> listStores({String? regionId}) async {
    final rows = await _gateway.select('stores', filters: {'status': 'active', if (regionId != null) 'region_id': regionId});
    final values = rows.map(AssalStoreSummary.fromJson).toList(growable: false);
    return _state(values, 'لا توجد متاجر متاحة');
  }

  @override
  Future<AssalLoadState<AssalStoreSummary>> getStore(String storeId) async {
    final rows = await _gateway.select('stores', filters: {'id': storeId, 'status': 'active'});
    if (rows.isEmpty) return const AssalError('المتجر غير موجود', code: 'not_found');
    return AssalData(AssalStoreSummary.fromJson(rows.first));
  }

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({AssalProductQuery query = const AssalProductQuery()}) async {
    final rows = await _gateway.select('products', filters: {'status': 'active', if (query.storeId != null) 'store_id': query.storeId, if (query.categoryId != null) 'category_id': query.categoryId});
    var values = rows.map(AssalProductSummary.fromJson).toList(growable: false);
    if (query.featuredOnly) values = values.where((item) => item.isFeatured).toList(growable: false);
    if (query.subcategoryId != null) values = values.where((item) => item.taxonomyId == query.subcategoryId).toList(growable: false);
    if (query.productType != null) values = values.where((item) => item.productType == query.productType).toList(growable: false);
    if (query.gradeLevel != null) values = values.where((item) => item.gradeLevel == query.gradeLevel).toList(growable: false);
    final search = query.search?.trim().toLowerCase();
    if (search != null && search.isNotEmpty) values = values.where((item) => '${item.nameAr} ${item.categoryNameAr} ${item.subcategoryNameAr}'.toLowerCase().contains(search)).toList(growable: false);
    return _state(values, 'لا توجد منتجات مطابقة للبحث');
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
    return _state(rows.map(AssalReviewSummary.fromJson).toList(growable: false), 'لا توجد مراجعات بعد');
  }

  @override
  Future<AssalLoadState<List<AssalCommentSummary>>> listComments(String targetId) async => const AssalEmpty('لا توجد تعليقات بعد');

  @override
  Future<AssalLoadState<List<AssalRequestSummary>>> listRequests(String requesterId) async {
    final rows = await _gateway.select('requests', filters: {'requester_id': requesterId});
    return _state(rows.map(AssalRequestSummary.fromJson).toList(growable: false), 'لا توجد طلبات تواصل');
  }

  @override
  Future<AssalLoadState<AssalRequestSummary>> createRequest(String requesterId, AssalRequestDraft draft) async => const AssalError('إرسال الطلب الإنتاجي يحتاج إلى Data Source مصادق عليه.', code: 'production_write_not_configured');

  @override
  Future<AssalLoadState<List<AssalNotificationSummary>>> listNotifications(String userId) async {
    final rows = await _gateway.select('notifications', filters: {'user_id': userId});
    return _state(rows.map(AssalNotificationSummary.fromJson).toList(growable: false), 'لا توجد إشعارات جديدة');
  }

  @override
  Future<AssalLoadState<List<AssalConversationSummary>>> listConversations(String userId) async => const AssalEmpty('لا توجد محادثات');
  @override
  Future<AssalLoadState<List<AssalMessageSummary>>> listMessages(String conversationId) async => const AssalEmpty('لا توجد رسائل');
  @override
  Future<AssalLoadState<AssalMessageSummary>> sendMessage(String userId, AssalMessageDraft draft) async => const AssalError('المراسلة الإنتاجية تحتاج إلى Data Source مصادق عليه.', code: 'production_write_not_configured');
  @override
  Future<AssalLoadState<AssalReviewSummary>> createReview(String authorId, AssalReviewDraft draft) async => const AssalError('المراجعة الإنتاجية تحتاج إلى Data Source مصادق عليه.', code: 'production_write_not_configured');
  @override
  Future<AssalLoadState<AssalCommentSummary>> createComment(String authorId, String authorName, String targetId, String body) async => const AssalError('التعليق الإنتاجي يحتاج إلى Data Source مصادق عليه.', code: 'production_write_not_configured');
  @override
  Future<AssalLoadState<bool>> toggleFollow(String userId, String storeId) async => const AssalError('المتابعة الإنتاجية تحتاج إلى Data Source مصادق عليه.', code: 'production_write_not_configured');
  @override
  Future<AssalLoadState<bool>> toggleFavorite(String userId, String targetId) async => const AssalError('الحفظ الإنتاجي يحتاج إلى Data Source مصادق عليه.', code: 'production_write_not_configured');
  @override
  Future<AssalLoadState<bool>> toggleLike(String userId, String targetId) async => const AssalError('الإعجاب الإنتاجي يحتاج إلى Data Source مصادق عليه.', code: 'production_write_not_configured');
  @override
  Future<AssalLoadState<AssalSession>> signIn(String email, String password) async => const AssalError('المصادقة الإنتاجية موكلة إلى مزود المصادقة.', code: 'production_auth_not_configured');
  @override
  Future<AssalLoadState<AssalSession>> register(String name, String email, String password) async => const AssalError('المصادقة الإنتاجية موكلة إلى مزود المصادقة.', code: 'production_auth_not_configured');
  @override
  Future<AssalLoadState<void>> signOut() async => const AssalData(null);
}
