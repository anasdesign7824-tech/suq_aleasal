import 'package:assalkom_contracts/assal_domain.dart';

enum AssalDataSourceMode { demo, production }

enum AssalSort { featured, newest, popular, rating }

class AssalProductQuery {
  const AssalProductQuery({
    this.categoryId,
    this.subcategoryId,
    this.storeId,
    this.regionId,
    this.provinceId,
    this.originCountry,
    this.certificateId,
    this.search,
    this.gradeLevel,
    this.productType,
    this.processingMethod,
    this.processingStatus,
    this.packaging,
    this.availability,
    this.merchantId,
    this.minRating,
    this.minPrice,
    this.maxPrice,
    this.verifiedStoresOnly = false,
    this.featuredOnly = false,
    this.sort = AssalSort.featured,
  });

  final String? categoryId;
  final String? subcategoryId;
  final String? storeId;
  final String? regionId;
  final String? provinceId;
  final String? originCountry;
  final String? certificateId;
  final String? search;
  final int? gradeLevel;
  final ProductType? productType;
  final String? processingMethod;
  final String? processingStatus;
  final String? packaging;
  final String? availability;
  final String? merchantId;
  final double? minRating;
  final double? minPrice;
  final double? maxPrice;
  final bool verifiedStoresOnly;
  final bool featuredOnly;
  final AssalSort sort;
}

class AssalRequestDraft {
  const AssalRequestDraft({
    required this.storeId,
    this.productId,
    required this.subject,
    required this.body,
    this.quantity,
    this.phone,
    this.handoffOption = HandoffOption.contact,
    this.handoffDetails = const <String, Object?>{},
    this.deliveryNote,
    this.contactChannel,
    this.priceNote,
  });

  final String storeId;
  final String? productId;
  final String subject;
  final String body;
  final int? quantity;
  final String? phone;
  final HandoffOption handoffOption;
  final Map<String, Object?> handoffDetails;
  final String? deliveryNote;
  final String? contactChannel;
  final String? priceNote;
}

class AssalReviewDraft {
  const AssalReviewDraft({required this.productId, required this.storeId, required this.rating, required this.body});
  final String productId;
  final String storeId;
  final int rating;
  final String body;
}

class AssalMessageDraft {
  const AssalMessageDraft({required this.conversationId, required this.body});
  final String conversationId;
  final String body;
}

abstract interface class AssalRepository {
  AssalDataSourceMode get mode;
  Future<AssalSession> getSession();
  Future<AssalLoadState<List<AssalRegion>>> listRegions();
  Future<AssalLoadState<List<AssalTaxonomy>>> listTaxonomy();
  Future<AssalLoadState<List<AssalStoreSummary>>> listStores({String? regionId});
  Future<AssalLoadState<AssalStoreSummary>> getStore(String storeId);
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({AssalProductQuery query = const AssalProductQuery()});
  Future<AssalLoadState<AssalProductSummary>> getProduct(String productId);
  Future<AssalLoadState<List<AssalReviewSummary>>> listReviews(String productId);
  Future<AssalLoadState<List<AssalCommentSummary>>> listComments(String targetId);
  Future<AssalLoadState<List<AssalRequestSummary>>> listRequests(String requesterId);
  Future<AssalLoadState<AssalRequestSummary>> createRequest(String requesterId, AssalRequestDraft draft);
  Future<AssalLoadState<List<AssalNotificationSummary>>> listNotifications(String userId);
  Future<AssalLoadState<List<AssalConversationSummary>>> listConversations(String userId);
  Future<AssalLoadState<List<AssalMessageSummary>>> listMessages(String conversationId);
  Future<AssalLoadState<AssalMessageSummary>> sendMessage(String userId, AssalMessageDraft draft);
  Future<AssalLoadState<AssalReviewSummary>> createReview(String authorId, AssalReviewDraft draft);
  Future<AssalLoadState<AssalCommentSummary>> createComment(String authorId, String authorName, String targetId, String body);
  Future<AssalLoadState<bool>> toggleFollow(String userId, String storeId);
  Future<AssalLoadState<bool>> toggleFavorite(String userId, String targetId);
  Future<AssalLoadState<bool>> toggleLike(String userId, String targetId);
  Future<AssalLoadState<AssalSession>> signIn(String email, String password);
  Future<AssalLoadState<AssalSession>> register(String name, String email, String password);
  Future<AssalLoadState<void>> signOut();
}

abstract interface class DemoCatalogLoader { Future<String> loadJson(); }
abstract interface class ProductionQueryGateway {
  Future<List<Map<String, Object?>>> select(String table, {Map<String, Object?> filters = const <String, Object?>{}});
  Future<Map<String, Object?>> insert(String table, Map<String, Object?> values);
  Future<Map<String, Object?>> update(String table, Map<String, Object?> values, {required String id});
}

class ProductionRepositoryNotConfigured implements Exception {
  const ProductionRepositoryNotConfigured();
  @override
  String toString() => 'Production repository requires an explicit Supabase gateway configuration.';
}
