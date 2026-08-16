import 'dart:convert';

import 'package:assalkom_contracts/assal_domain.dart';
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
  AssalSession _session = AssalSession.guest;
  final Set<String> _followedStores = <String>{};
  final Set<String> _favorites = <String>{};
  final Set<String> _likes = <String>{};
  final List<AssalReviewSummary> _localReviews = <AssalReviewSummary>[];
  final List<AssalCommentSummary> _localComments = <AssalCommentSummary>[];
  final List<AssalRequestSummary> _localRequests = <AssalRequestSummary>[];
  final List<AssalNotificationSummary> _localNotifications = <AssalNotificationSummary>[];
  final List<AssalConversationSummary> _localConversations = <AssalConversationSummary>[];
  final List<AssalMessageSummary> _localMessages = <AssalMessageSummary>[];

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

  AssalLoadState<List<T>> _listState<T>(List<T> values, String emptyMessage) => values.isEmpty ? AssalEmpty<List<T>>(emptyMessage) : AssalData<List<T>>(values);

  @override
  Future<AssalSession> getSession() async => _session;

  @override
  Future<AssalLoadState<List<AssalRegion>>> listRegions() async {
    final values = _list(await _readCatalog(), 'regions').map(AssalRegion.fromJson).toList(growable: false);
    return _listState(values, 'لا توجد مناطق متاحة حاليًا');
  }

  @override
  Future<AssalLoadState<List<AssalTaxonomy>>> listTaxonomy() async {
    final products = _list(await _readCatalog(), 'products');
    final seen = <String>{};
    final values = <AssalTaxonomy>[];
    for (final product in products) {
      final id = product['subcategory_id'] as String? ?? product['category_id'] as String?;
      final name = product['subcategory_name_ar'] as String? ?? product['category_name_ar'] as String?;
      if (id == null || name == null || !seen.add(id)) continue;
      values.add(AssalTaxonomy(id: id, code: id, nameAr: name, description: 'تصنيف لاكتشاف منتجات العسل اليمني'));
    }
    return _listState(values, 'لا توجد تصنيفات متاحة حاليًا');
  }

  Future<Map<String, String>> _regionNames() async {
    final regions = _list(await _readCatalog(), 'regions');
    return {for (final item in regions) item['id'] as String: item['name_ar'] as String};
  }

  @override
  Future<AssalLoadState<List<AssalBannerSummary>>> listBanners() async {
    final values = _list(await _readCatalog(), 'banners').map(AssalBannerSummary.fromJson).where((banner) => banner.isActive).toList(growable: false)..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return _listState(values, 'لا توجد حملات استكشاف متاحة حاليًا');
  }

  @override
  Future<AssalLoadState<List<String>>> listPopularSearches() async {
    final catalog = await _readCatalog();
    final value = catalog['popular_searches'];
    final values = value is List ? value.whereType<String>().toList(growable: false) : const <String>[];
    return _listState(values, 'لا توجد اقتراحات بحث متاحة حاليًا');
  }

  @override
  Future<AssalLoadState<List<AssalStoreSummary>>> listStores({String? regionId}) async {
    final regions = await _regionNames();
    var rows = _list(await _readCatalog(), 'stores');
    if (regionId != null && regionId.isNotEmpty) rows = rows.where((item) => item['region_id'] == regionId).toList(growable: false);
    final values = rows.map((item) => AssalStoreSummary.fromJson({...item, 'region_name_ar': regions[item['region_id']]})).toList(growable: false);
    return _listState(values, 'لا توجد متاجر ضمن هذا الاختيار');
  }

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listFavoriteProducts(String userId) async {
    final state = await listProducts();
    if (state is AssalData<List<AssalProductSummary>>) {
      return _listState(state.value.where((product) => _favorites.contains(product.id)).toList(growable: false), 'لا توجد منتجات محفوظة بعد.');
    }
    return state;
  }

  @override
  Future<AssalLoadState<List<AssalTaxonomy>>> listFavoriteTaxonomies(String userId) async {
    final productsState = await listFavoriteProducts(userId);
    final taxonomyState = await listTaxonomy();
    if (productsState is AssalData<List<AssalProductSummary>> && taxonomyState is AssalData<List<AssalTaxonomy>>) {
      final ids = productsState.value.map((product) => product.taxonomyId).whereType<String>().toSet();
      return _listState(taxonomyState.value.where((taxonomy) => ids.contains(taxonomy.id)).toList(growable: false), 'لا توجد تصنيفات مرتبطة بالمحفوظات بعد.');
    }
    return const AssalEmpty('لا توجد تصنيفات مرتبطة بالمحفوظات بعد.');
  }

  @override
  Future<AssalLoadState<List<AssalStoreSummary>>> listFollowedStores(String userId) async {
    final state = await listStores();
    if (state is AssalData<List<AssalStoreSummary>>) {
      return _listState(state.value.where((store) => _followedStores.contains(store.id)).toList(growable: false), 'لا توجد متاجر متابَعة بعد.');
    }
    return state;
  }

  @override
  Future<AssalLoadState<AssalStoreSummary>> getStore(String storeId) async {
    final state = await listStores();
    if (state is AssalData<List<AssalStoreSummary>>) {
      final matches = state.value.where((store) => store.id == storeId);
      if (matches.isNotEmpty) return AssalData(matches.first);
    }
    return const AssalError('المتجر غير موجود في البيانات التجريبية', code: 'store_not_found');
  }

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({AssalProductQuery query = const AssalProductQuery()}) async {
    final catalog = await _readCatalog();
    final regions = await _regionNames();
    var rows = _list(catalog, 'products');
    if (query.categoryId != null) rows = rows.where((item) => item['category_id'] == query.categoryId).toList(growable: false);
    if (query.subcategoryId != null) rows = rows.where((item) => item['subcategory_id'] == query.subcategoryId).toList(growable: false);
    if (query.storeId != null) rows = rows.where((item) => item['store_id'] == query.storeId).toList(growable: false);
    if (query.regionId != null) rows = rows.where((item) => (item['regions'] as List?)?.contains(query.regionId) == true || item['region_id'] == query.regionId).toList(growable: false);
    if (query.provinceId != null) rows = rows.where((item) => item['province_id'] == query.provinceId).toList(growable: false);
    if (query.originCountry != null) rows = rows.where((item) => item['origin_country'] == query.originCountry).toList(growable: false);
    if (query.certificateId != null) rows = rows.where((item) => (item['certifications'] as List?)?.contains(query.certificateId) == true).toList(growable: false);
    if (query.merchantId != null) rows = rows.where((item) => item['merchant_id'] == query.merchantId).toList(growable: false);
    if (query.processingMethod != null) rows = rows.where((item) => item['processing_method_ar'] == query.processingMethod).toList(growable: false);
    if (query.processingStatus != null) rows = rows.where((item) => item['processing_status_ar'] == query.processingStatus).toList(growable: false);
    if (query.packaging != null) rows = rows.where((item) => item['packaging_label_ar'] == query.packaging).toList(growable: false);
    if (query.availability != null) rows = rows.where((item) => item['availability'] == query.availability).toList(growable: false);
    if (query.minRating != null) rows = rows.where((item) => item['rating_average'] is num && (item['rating_average'] as num).toDouble() >= query.minRating!).toList(growable: false);
    if (query.minPrice != null) rows = rows.where((item) => item['price'] is num && (item['price'] as num).toDouble() >= query.minPrice!).toList(growable: false);
    if (query.maxPrice != null) rows = rows.where((item) => item['price'] is num && (item['price'] as num).toDouble() <= query.maxPrice!).toList(growable: false);
    if (query.featuredOnly) rows = rows.where((item) => item['is_featured'] == true).toList(growable: false);
    if (query.gradeLevel != null) rows = rows.where((item) => (item['grade_levels'] as List?)?.contains(query.gradeLevel) == true).toList(growable: false);
    if (query.productType != null) rows = rows.where((item) => item['product_type'] == query.productType!.name).toList(growable: false);
    if (query.verifiedStoresOnly) {
      final stores = _list(catalog, 'stores').where((item) => item['is_verified'] == true).map((item) => item['id'] as String).toSet();
      rows = rows.where((item) => stores.contains(item['store_id'])).toList(growable: false);
    }
    final search = query.search?.trim().toLowerCase();
    if (search != null && search.isNotEmpty) {
      rows = rows.where((item) {
        final haystack = [
          item['name_ar'], item['category_name_ar'], item['subcategory_name_ar'],
          ...(item['tags'] is List ? (item['tags'] as List) : const []),
          ...(item['regions'] is List ? (item['regions'] as List) : const []),
        ].whereType<String>().join(' ').toLowerCase();
        return haystack.contains(search);
      }).toList(growable: false);
    }
    var values = rows.map((item) {
      final regionId = item['region_id'] as String?;
      final grades = item['grade_levels'] as List?;
      return AssalProductSummary.fromJson({...item, 'region_name_ar': regions[regionId], 'grade_level': grades?.isEmpty == false ? grades!.first : null});
    }).toList(growable: false);
    values = [...values];
    switch (query.sort) {
      case AssalSort.newest:
        values = values.reversed.toList(growable: false);
      case AssalSort.popular:
        values.sort((a, b) => b.tags.length.compareTo(a.tags.length));
      case AssalSort.rating:
        values.sort((a, b) => b.ratingAverage.compareTo(a.ratingAverage));
      case AssalSort.featured:
        values.sort((a, b) => (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0));
    }
    return _listState(values, search == null || search.isEmpty ? 'لا توجد منتجات متاحة حاليًا' : 'لم نعثر على نتائج مطابقة. جرّب كلمة أخرى.');
  }

  @override
  Future<AssalLoadState<AssalProductSummary>> getProduct(String productId) async {
    final state = await listProducts();
    if (state is AssalData<List<AssalProductSummary>>) {
      final matches = state.value.where((product) => product.id == productId);
      if (matches.isNotEmpty) return AssalData(matches.first);
    }
    return const AssalError('المنتج غير موجود في البيانات التجريبية', code: 'product_not_found');
  }

  @override
  Future<AssalLoadState<List<AssalReviewSummary>>> listReviews(String productId) async {
    final values = [
      ..._list(await _readCatalog(), 'reviews').where((item) => item['product_id'] == productId).map(AssalReviewSummary.fromJson),
      ..._localReviews.where((review) => review.productId == productId),
    ];
    return _listState(values, 'لا توجد مراجعات منشورة بعد. كن أول من يشارك تجربته.');
  }

  @override
  Future<AssalLoadState<List<AssalCommentSummary>>> listComments(String targetId) async {
    final values = [
      ..._list(await _readCatalog(), 'comments').where((item) => item['target_id'] == targetId).map(AssalCommentSummary.fromJson),
      ..._localComments.where((comment) => comment.targetId == targetId),
    ];
    return _listState(values, 'لا توجد تعليقات بعد.');
  }

  @override
  Future<AssalLoadState<List<AssalRequestSummary>>> listRequests(String requesterId) async {
    final values = [
      ..._list(await _readCatalog(), 'requests').where((item) => item['requester_id'] == requesterId).map(AssalRequestSummary.fromJson),
      ..._localRequests.where((request) => request.requesterId == requesterId),
    ];
    return _listState(values, 'لا توجد طلبات تواصل بعد.');
  }

  @override
  Future<AssalLoadState<AssalRequestSummary>> createRequest(String requesterId, AssalRequestDraft draft) async {
    final request = AssalRequestSummary(
      id: 'local-request-${DateTime.now().millisecondsSinceEpoch}',
      requesterId: requesterId,
      storeId: draft.storeId,
      productId: draft.productId,
      subject: draft.subject,
      body: draft.body,
      quantity: draft.quantity,
      phone: draft.phone,
      preferredHandoffOption: draft.handoffOption.labelAr,
      deliveryNote: draft.deliveryNote ?? (draft.handoffDetails['notes'] as String?),
      priceNote: draft.priceNote,
      status: RequestStatus.open,
      createdAt: DateTime.now(),
    );
    _localRequests.insert(0, request);
    _localNotifications.insert(0, AssalNotificationSummary(id: 'local-notification-${request.id}', userId: requesterId, notificationType: 'request', titleAr: 'تم حفظ طلب التواصل', bodyAr: 'سيتابع المتجر طلبك في Demo Mode.', payload: {'request_id': request.id}));
    return AssalData(request);
  }

  @override
  Future<AssalLoadState<List<AssalNotificationSummary>>> listNotifications(String userId) async {
    final values = [
      ..._list(await _readCatalog(), 'notifications').where((item) => item['user_id'] == userId).map(AssalNotificationSummary.fromJson),
      ..._localNotifications.where((notification) => notification.userId == userId),
    ];
    return _listState(values, 'لا توجد إشعارات جديدة.');
  }

  @override
  Future<AssalLoadState<List<AssalConversationSummary>>> listConversations(String userId) async {
    final seeded = _list(await _readCatalog(), 'conversations').map(AssalConversationSummary.fromJson);
    final values = [...seeded, ..._localConversations];
    if (values.isEmpty && _session.isAuthenticated) {
      values.add(AssalConversationSummary(id: 'demo-conversation-doani', storeId: 'demo-store-doani', storeName: 'مناحل دوعن الأصيلة', lastMessage: 'مرحبًا، كيف نساعدك في اختيار العسل؟', updatedAt: DateTime.now()));
    }
    return _listState(values, 'لا توجد محادثات بعد. ابدأ من صفحة المتجر.');
  }

  @override
  Future<AssalLoadState<List<AssalMessageSummary>>> listMessages(String conversationId) async {
    final values = [
      ..._list(await _readCatalog(), 'messages').where((item) => item['conversation_id'] == conversationId).map(AssalMessageSummary.fromJson),
      ..._localMessages.where((message) => message.conversationId == conversationId),
    ];
    if (values.isEmpty) {
      return AssalData([
        AssalMessageSummary(id: 'demo-message-welcome', conversationId: conversationId, senderId: 'demo-merchant-doani', body: 'مرحبًا بك في عسلكم. يسعدنا مساعدتك في معرفة المصدر والجودة.', sentAt: DateTime.now().subtract(const Duration(minutes: 12))),
      ]);
    }
    return AssalData(values);
  }

  @override
  Future<AssalLoadState<AssalMessageSummary>> sendMessage(String userId, AssalMessageDraft draft) async {
    final message = AssalMessageSummary(id: 'local-message-${DateTime.now().microsecondsSinceEpoch}', conversationId: draft.conversationId, senderId: userId, body: draft.body, sentAt: DateTime.now(), isMine: true);
    _localMessages.add(message);
    return AssalData(message);
  }

  @override
  Future<AssalLoadState<AssalReviewSummary>> createReview(String authorId, AssalReviewDraft draft) async {
    final review = AssalReviewSummary(id: 'local-review-${DateTime.now().microsecondsSinceEpoch}', productId: draft.productId, storeId: draft.storeId, authorId: authorId, authorName: _session.user?.nameAr ?? 'عميل Demo', rating: draft.rating, status: ReviewStatus.approved, body: draft.body, createdAt: DateTime.now(), isLocal: true);
    _localReviews.insert(0, review);
    return AssalData(review);
  }

  @override
  Future<AssalLoadState<AssalCommentSummary>> createComment(String authorId, String authorName, String targetId, String body) async {
    final comment = AssalCommentSummary(id: 'local-comment-${DateTime.now().microsecondsSinceEpoch}', targetId: targetId, authorId: authorId, authorName: authorName, body: body, createdAt: DateTime.now(), isLocal: true);
    _localComments.insert(0, comment);
    return AssalData(comment);
  }

  @override
  Future<AssalLoadState<bool>> toggleFollow(String userId, String storeId) async {
    final followed = !_followedStores.contains(storeId);
    followed ? _followedStores.add(storeId) : _followedStores.remove(storeId);
    return AssalData(followed);
  }

  @override
  Future<AssalLoadState<bool>> toggleFavorite(String userId, String targetId) async {
    final favorite = !_favorites.contains(targetId);
    favorite ? _favorites.add(targetId) : _favorites.remove(targetId);
    return AssalData(favorite);
  }

  @override
  Future<AssalLoadState<bool>> toggleLike(String userId, String targetId) async {
    final liked = !_likes.contains(targetId);
    liked ? _likes.add(targetId) : _likes.remove(targetId);
    return AssalData(liked);
  }

  @override
  Future<AssalLoadState<AssalSession>> signIn(String email, String password) async {
    if (!email.contains('@') || password.length < 6) return const AssalError('تحقق من البريد وكلمة المرور. كلمة المرور لا تقل عن 6 أحرف.', code: 'invalid_credentials');
    _session = AssalSession(isAuthenticated: true, role: AssalRole.customer, user: AssalUserProfile(id: 'demo-customer', nameAr: 'عميل عسلكم', email: email, bio: 'أبحث عن العسل اليمني الموثوق ومصدره.', location: 'صنعاء'));
    return AssalData(_session);
  }

  @override
  Future<AssalLoadState<AssalSession>> signInWithGoogle() async => const AssalError('تسجيل Google يحتاج مزود OAuth الإنتاجي، وهو غير متاح دون اتصال في Demo Mode.', code: 'demo_google_auth_unavailable');

  @override
  Future<AssalLoadState<AssalSession>> register(String name, String email, String password) async {
    if (name.trim().length < 2 || !email.contains('@') || password.length < 6) return const AssalError('أدخل اسمًا صحيحًا وبريدًا صالحًا وكلمة مرور من 6 أحرف على الأقل.', code: 'invalid_registration');
    _session = AssalSession(isAuthenticated: true, role: AssalRole.customer, user: AssalUserProfile(id: 'demo-customer', nameAr: name.trim(), email: email, bio: 'عضو جديد في مجتمع عسلكم'));
    return AssalData(_session);
  }

  @override
  Future<AssalLoadState<void>> signOut() async {
    _session = AssalSession.guest;
    return const AssalData(null);
  }
}
