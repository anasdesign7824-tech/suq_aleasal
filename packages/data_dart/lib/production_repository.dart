import 'package:assalkom_contracts/assal_domain.dart';
import 'assal_repository.dart';

class ProductionRepository implements AssalRepository {
  const ProductionRepository({required ProductionQueryGateway gateway, AssalAuthGateway? authGateway}) : _gateway = gateway, _authGateway = authGateway;
  final ProductionQueryGateway _gateway;
  final AssalAuthGateway? _authGateway;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.production;

  AssalLoadState<List<T>> _state<T>(List<T> values, String emptyMessage) => values.isEmpty ? AssalEmpty<List<T>>(emptyMessage) : AssalData<List<T>>(values);

  @override
  Future<AssalSession> getSession() async {
    final auth = _authGateway;
    if (auth == null) return AssalSession.guest;
    try {
      return _sessionFromIdentity(await auth.currentIdentity());
    } on Object {
      return AssalSession.guest;
    }
  }

  AssalSession _sessionFromIdentity(AssalAuthIdentity? identity, {Map<String, Object?> profile = const <String, Object?>{}, bool isAdmin = false}) {
    if (identity == null) return AssalSession.guest;
    final role = isAdmin ? AssalRole.admin : _roleFrom(profile['role']);
    final user = AssalUserProfile.fromJson({
      'id': identity.id,
      'name_ar': profile['display_name'] ?? identity.displayName ?? 'عميل عسلكم',
      'email': identity.email,
      'avatar_url': profile['avatar_url'] ?? identity.avatarUrl,
      'bio': profile['bio'],
      'phone': profile['phone'],
      'role': role.name,
      'is_active': profile['is_active'] ?? true,
      'created_at': profile['created_at'],
      'updated_at': profile['updated_at'],
    });
    return AssalSession(isAuthenticated: true, role: role, user: user);
  }

  AssalRole _roleFrom(Object? value) => switch (value) {
        'admin' => AssalRole.admin,
        'merchant' => AssalRole.merchant,
        _ => AssalRole.customer,
      };

  Future<AssalSession> _sessionForIdentity(AssalAuthIdentity? identity) async {
    if (identity == null) return AssalSession.guest;
    Map<String, Object?> profile = const <String, Object?>{};
    var isAdmin = false;
    try {
      final rows = await _gateway.select('profiles', filters: {'user_id': identity.id});
      if (rows.isNotEmpty) profile = rows.first;
    } on Object {
      // Auth remains valid even if profile hydration is temporarily unavailable.
    }
    try {
      final rows = await _gateway.select('admin_users', filters: {'user_id': identity.id});
      isAdmin = rows.isNotEmpty;
    } on Object {
      isAdmin = false;
    }
    return _sessionFromIdentity(identity, profile: profile, isAdmin: isAdmin);
  }

  Future<AssalLoadState<AssalSession>> _authOperation(Future<AssalAuthIdentity?> Function(AssalAuthGateway auth) operation) async {
    final auth = _authGateway;
    if (auth == null) return const AssalError('المصادقة الإنتاجية غير مهيأة بعد.', code: 'production_auth_not_configured');
    try {
      final identity = await operation(auth);
      if (identity == null) return const AssalError('لم تكتمل جلسة المصادقة.', code: 'auth_session_missing');
      return AssalData(await _sessionForIdentity(identity));
    } on AssalAuthFailure catch (error) {
      return AssalError(error.messageAr, code: error.code);
    } on Object {
      return const AssalError('تعذر إكمال المصادقة. تحقق من الاتصال والإعدادات ثم حاول مرة أخرى.', code: 'auth_unexpected_error');
    }
  }

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
  Future<AssalLoadState<List<AssalProductSummary>>> listFavoriteProducts(String userId) async {
    final rows = await _gateway.select('favorites', filters: {'user_id': userId, 'target_type': 'product'});
    final ids = rows.map((row) => row['target_id']).whereType<String>().toSet();
    if (ids.isEmpty) return const AssalEmpty('لا توجد منتجات محفوظة');
    final products = await _gateway.select('products', filters: const {'status': 'active'});
    return _state(products.where((row) => ids.contains(row['id'])).map(AssalProductSummary.fromJson).toList(growable: false), 'لا توجد منتجات محفوظة');
  }

  @override
  Future<AssalLoadState<List<AssalTaxonomy>>> listFavoriteTaxonomies(String userId) async {
    final favoriteRows = await _gateway.select('favorites', filters: {'user_id': userId, 'target_type': 'product'});
    final productIds = favoriteRows.map((row) => row['target_id']).whereType<String>().toSet();
    if (productIds.isEmpty) return const AssalEmpty('لا توجد تصنيفات مرتبطة بالمحفوظات بعد.');
    final products = await _gateway.select('products', filters: const {'status': 'active'});
    final taxonomyIds = products.where((row) => productIds.contains(row['id'])).map((row) => row['subcategory_id'] ?? row['category_id']).whereType<String>().toSet();
    final taxonomies = await _gateway.select('taxonomies', filters: const {'status': 'active'});
    return _state(taxonomies.where((row) => taxonomyIds.contains(row['id'])).map(AssalTaxonomy.fromJson).toList(growable: false), 'لا توجد تصنيفات مرتبطة بالمحفوظات بعد.');
  }

  @override
  Future<AssalLoadState<List<AssalStoreSummary>>> listFollowedStores(String userId) async {
    final rows = await _gateway.select('store_follows', filters: {'user_id': userId});
    final ids = rows.map((row) => row['store_id']).whereType<String>().toSet();
    if (ids.isEmpty) return const AssalEmpty('لا توجد متاجر متابَعة');
    final stores = await _gateway.select('stores', filters: const {'status': 'active'});
    return _state(stores.where((row) => ids.contains(row['id'])).map(AssalStoreSummary.fromJson).toList(growable: false), 'لا توجد متاجر متابَعة');
  }

  @override
  Future<AssalLoadState<AssalStoreSummary>> getStore(String storeId) async {
    final rows = await _gateway.select('stores', filters: {'id': storeId, 'status': 'active'});
    if (rows.isEmpty) return const AssalError('المتجر غير موجود', code: 'not_found');
    return AssalData(AssalStoreSummary.fromJson(rows.first));
  }

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({AssalProductQuery query = const AssalProductQuery()}) async {
    final rows = await _gateway.select('products', filters: {
      'status': 'active',
      if (query.storeId != null) 'store_id': query.storeId,
      if (query.categoryId != null) 'category_id': query.categoryId,
      if (query.regionId != null) 'region_id': query.regionId,
      if (query.provinceId != null) 'province_id': query.provinceId,
      if (query.merchantId != null) 'merchant_id': query.merchantId,
      if (query.availability != null) 'availability': query.availability,
      if (query.processingMethod != null) 'processing_method_ar': query.processingMethod,
      if (query.processingStatus != null) 'processing_status_ar': query.processingStatus,
      if (query.packaging != null) 'packaging_label_ar': query.packaging,
    });
    var values = rows.map(AssalProductSummary.fromJson).toList(growable: false);
    if (query.featuredOnly) values = values.where((item) => item.isFeatured).toList(growable: false);
    if (query.subcategoryId != null) values = values.where((item) => item.taxonomyId == query.subcategoryId).toList(growable: false);
    if (query.productType != null) values = values.where((item) => item.productType == query.productType).toList(growable: false);
    if (query.gradeLevel != null) values = values.where((item) => item.gradeLevel == query.gradeLevel).toList(growable: false);
    if (query.originCountry != null) values = values.where((item) => item.originCountry == query.originCountry).toList(growable: false);
    if (query.certificateId != null) values = values.where((item) => item.certifications.contains(query.certificateId)).toList(growable: false);
    if (query.minRating != null) values = values.where((item) => item.ratingAverage >= query.minRating!).toList(growable: false);
    if (query.minPrice != null) values = values.where((item) => item.price != null && item.price! >= query.minPrice!).toList(growable: false);
    if (query.maxPrice != null) values = values.where((item) => item.price != null && item.price! <= query.maxPrice!).toList(growable: false);
    if (query.verifiedStoresOnly) {
      final stores = await _gateway.select('stores', filters: const {'status': 'active', 'is_verified': true});
      final ids = stores.map((row) => row['id']).whereType<String>().toSet();
      values = values.where((item) => ids.contains(item.storeId)).toList(growable: false);
    }
    final search = query.search?.trim().toLowerCase();
    if (search != null && search.isNotEmpty) values = values.where((item) => '${item.nameAr} ${item.categoryNameAr} ${item.subcategoryNameAr} ${item.honeyIdentity} ${item.regionNameAr} ${item.provinceNameAr}'.toLowerCase().contains(search)).toList(growable: false);
    switch (query.sort) {
      case AssalSort.newest:
        values = values.reversed.toList(growable: false);
      case AssalSort.popular:
        values = [...values]..sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
      case AssalSort.rating:
        values = [...values]..sort((a, b) => b.ratingAverage.compareTo(a.ratingAverage));
      case AssalSort.featured:
        values = [...values]..sort((a, b) => (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0));
    }
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
  Future<AssalLoadState<bool>> markNotificationRead(String userId, String notificationId) async {
    await _gateway.update('notifications', {'read_at': DateTime.now().toIso8601String()}, id: notificationId);
    return const AssalData(true);
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
  Future<AssalLoadState<AssalSession>> signIn(String email, String password) => _authOperation((auth) async => auth.signInWithPassword(email, password));

  @override
  Future<AssalLoadState<AssalSession>> signInWithGoogle() => _authOperation((auth) => auth.signInWithGoogle());

  @override
  Future<AssalLoadState<AssalSession>> signInWithFacebook() => _authOperation((auth) => auth.signInWithFacebook());

  @override
  Future<AssalLoadState<AssalSession>> register(String name, String email, String password) => _authOperation((auth) => auth.signUp(name: name, email: email, password: password));
  @override
  Future<AssalLoadState<AssalMerchantApplicationSummary>> submitMerchantApplication(String userId, AssalMerchantApplicationDraft draft) async => const AssalError('طلب التحول إلى تاجر يحتاج تهيئة مصدر الإنتاج والمراجعة الإدارية.', code: 'production_merchant_application_not_configured');

  @override
  Future<AssalLoadState<void>> signOut() async {
    final auth = _authGateway;
    if (auth == null) return const AssalData(null);
    try {
      await auth.signOut();
      return const AssalData(null);
    } on Object {
      return const AssalError('تعذر تسجيل الخروج. حاول مرة أخرى.', code: 'sign_out_failed');
    }
  }
}
