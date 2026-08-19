import 'dart:typed_data';

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
  const AssalReviewDraft({
    required this.productId,
    required this.storeId,
    required this.rating,
    required this.body,
  });
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
  Future<AssalLoadState<List<AssalCategorySummary>>> listCategories();
  Future<AssalLoadState<List<AssalBannerSummary>>> listBanners();
  Future<AssalLoadState<List<String>>> listPopularSearches();
  Future<AssalLoadState<List<AssalStoreSummary>>> listStores({
    String? regionId,
  });
  Future<AssalLoadState<List<AssalProductSummary>>> listFavoriteProducts(
    String userId,
  );
  Future<AssalLoadState<List<AssalTaxonomy>>> listFavoriteTaxonomies(
    String userId,
  );
  Future<AssalLoadState<List<AssalStoreSummary>>> listFollowedStores(
    String userId,
  );
  Future<AssalLoadState<AssalStoreSummary>> getStore(String storeId);
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({
    AssalProductQuery query = const AssalProductQuery(),
  });
  Future<AssalLoadState<AssalProductSummary>> getProduct(String productId);
  Future<AssalLoadState<List<AssalReviewSummary>>> listReviews(
    String productId,
  );
  Future<AssalLoadState<List<AssalCommentSummary>>> listComments(
    String targetId,
  );
  Future<AssalLoadState<List<AssalRequestSummary>>> listRequests(
    String requesterId,
  );
  Future<AssalLoadState<List<AssalRequestSummary>>> listMerchantRequests(
    String merchantId,
  );
  Future<AssalLoadState<AssalRequestSummary>> createRequest(
    String requesterId,
    AssalRequestDraft draft,
  );
  Future<AssalLoadState<List<AssalNotificationSummary>>> listNotifications(
    String userId,
  );
  Future<AssalLoadState<bool>> markNotificationRead(
    String userId,
    String notificationId,
  );
  Future<AssalLoadState<List<AssalConversationSummary>>> listConversations(
    String userId,
  );
  Future<AssalLoadState<AssalConversationSummary>> createConversation(
    String userId,
    String storeId,
  );
  Future<AssalLoadState<List<AssalMessageSummary>>> listMessages(
    String conversationId,
  );
  Future<AssalLoadState<AssalMessageSummary>> sendMessage(
    String userId,
    AssalMessageDraft draft,
  );
  Future<AssalLoadState<AssalReviewSummary>> createReview(
    String authorId,
    AssalReviewDraft draft,
  );
  Future<AssalLoadState<AssalCommentSummary>> createComment(
    String authorId,
    String authorName,
    String targetId,
    String body,
  );
  Future<AssalLoadState<bool>> toggleFollow(String userId, String storeId);
  Future<AssalLoadState<bool>> toggleFavorite(String userId, String targetId);
  Future<AssalLoadState<bool>> toggleLike(String userId, String targetId);
  Future<AssalLoadState<void>> trackProductView(String productId);
  Future<AssalLoadState<AssalSession>> signIn(String email, String password);
  Future<AssalLoadState<void>> requestEmailOtp(String email);
  Future<AssalLoadState<AssalSession>> verifyEmailOtp(
    String email,
    String token,
  );
  Future<AssalLoadState<AssalSession>> signInWithGoogle();
  Future<AssalLoadState<AssalSession>> signInWithFacebook();
  Future<AssalLoadState<AssalSession>> register(
    String name,
    String email,
    String password,
  );
  Future<AssalLoadState<void>> requestPasswordReset(String email);
  Future<AssalLoadState<void>> resendEmailConfirmation(String email);
  Future<AssalLoadState<AssalSession>> verifyEmailConfirmation(
    String email,
    String token,
  );
  Future<AssalLoadState<void>> deleteAccount();
  Future<AssalLoadState<AssalMerchantApplicationSummary>>
      submitMerchantApplication(
          String userId, AssalMerchantApplicationDraft draft);
  Future<AssalLoadState<AssalMerchantApplicationSummary?>>
      loadMerchantApplication(String userId);
  Future<AssalLoadState<AssalMerchantApplicationDraft?>>
      loadMerchantApplicationDraft(String userId);
  Future<AssalLoadState<void>> saveMerchantApplicationDraft(
    String userId,
    AssalMerchantApplicationDraft draft,
  );
  Future<AssalLoadState<void>> clearMerchantApplicationDraft(String userId);
  Future<AssalLoadState<AssalMerchantWorkspaceSummary?>> loadMerchantWorkspace(
    String userId,
  );
  Future<AssalLoadState<AssalMerchantWorkspaceSummary>> openMerchantWorkspace(
    String userId,
    AssalMerchantWorkspaceDraft draft,
  );
  Future<AssalLoadState<void>> updateMerchantWorkspace(
    String userId,
    String storeId,
    AssalMerchantWorkspaceDraft draft,
  );
  Future<AssalLoadState<List<AssalProductSummary>>> listMerchantProducts(
    String userId,
  );
  Future<AssalLoadState<AssalProductSummary>> createMerchantProduct(
    String userId,
    String storeId,
    AssalProductDraft draft,
  );
  Future<AssalLoadState<AssalProductSummary>> updateMerchantProduct(
    String userId,
    String productId,
    AssalProductDraft draft,
  );
  Future<AssalLoadState<void>> deleteMerchantProduct(
    String userId,
    String productId,
  );
  Future<AssalLoadState<void>> updateUserProfile(
    String userId,
    AssalUserProfilePatch patch,
  );
  Future<AssalLoadState<String>> uploadMerchantImage(
    String userId,
    String kind,
    Uint8List bytes,
    String extension,
  );
  Future<AssalLoadState<String>> uploadStoreGalleryImage(
    String userId,
    String storeId,
    Uint8List bytes,
    String extension,
  );
  Future<AssalLoadState<String>> uploadProductImage(
    String userId,
    String productId,
    Uint8List bytes,
    String extension,
  );
  Future<AssalLoadState<void>> signOut();
}

abstract interface class DemoCatalogLoader {
  Future<String> loadJson();
}

abstract interface class ProductionQueryGateway {
  Future<List<Map<String, Object?>>> select(
    String table, {
    Map<String, Object?> filters = const <String, Object?>{},
  });
  Future<Map<String, Object?>> insert(
    String table,
    Map<String, Object?> values,
  );
  Future<Map<String, Object?>> update(
    String table,
    Map<String, Object?> values, {
    required String id,
  });
  Future<void> delete(
    String table, {
    Map<String, Object?> filters = const <String, Object?>{},
  });
  Future<Map<String, Object?>> upsert(
    String table,
    Map<String, Object?> values, {
    String? onConflict,
  });
  Future<Map<String, Object?>> rpc(
    String function,
    Map<String, Object?> params,
  );
  Future<String> uploadPublicImage(
    String path,
    Uint8List bytes,
    String extension,
  );
}

class AssalAuthIdentity {
  const AssalAuthIdentity({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
  });
  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
}

abstract interface class AssalAuthGateway {
  Future<AssalAuthIdentity?> currentIdentity();
  Future<AssalAuthIdentity?> signInWithPassword(String email, String password);
  Future<void> requestEmailOtp(String email);
  Future<AssalAuthIdentity?> verifyEmailOtp(String email, String token);
  Future<AssalAuthIdentity?> signUp({
    required String name,
    required String email,
    required String password,
  });
  Future<void> requestPasswordReset(String email);
  Future<void> resendEmailConfirmation(String email);
  Future<AssalAuthIdentity?> verifyEmailConfirmation(
    String email,
    String token,
  );
  Future<void> deleteAccount();
  Future<AssalAuthIdentity?> signInWithGoogle();
  Future<AssalAuthIdentity?> signInWithFacebook();
  Future<void> signOut();
}

class AssalAuthFailure implements Exception {
  const AssalAuthFailure(this.messageAr, {this.code});
  final String messageAr;
  final String? code;
  @override
  String toString() => messageAr;
}

class ProductionRepositoryNotConfigured implements Exception {
  const ProductionRepositoryNotConfigured();
  @override
  String toString() =>
      'Production repository requires an explicit Supabase gateway configuration.';
}
