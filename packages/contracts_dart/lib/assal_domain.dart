import 'dart:convert';

enum AssalRole { customer, merchant, admin }
enum ProductType { honey, wax, mix, raw, gift }
enum ProductStatus { draft, pending, active, paused, rejected }
enum StoreStatus { pending, active, paused, rejected, suspended }
enum VerificationStatus { pending, verified, rejected, suspended }
enum ReviewStatus { pending, approved, rejected, hidden }
enum RequestStatus { open, inProgress, answered, closed, cancelled }

extension RequestStatusWire on RequestStatus {
  String get wireValue => switch (this) {
        RequestStatus.open => 'open',
        RequestStatus.inProgress => 'in_progress',
        RequestStatus.answered => 'answered',
        RequestStatus.closed => 'closed',
        RequestStatus.cancelled => 'cancelled',
      };
}

class AssalRegion {
  const AssalRegion({
    required this.id,
    required this.nameAr,
    this.nameEn,
    this.code,
    this.parentRegionId,
    this.isActive = true,
  });

  final String id;
  final String nameAr;
  final String? nameEn;
  final String? code;
  final String? parentRegionId;
  final bool isActive;

  factory AssalRegion.fromJson(Map<String, Object?> json) => AssalRegion(
        id: json['id']! as String,
        nameAr: json['name_ar']! as String,
        nameEn: json['name_en'] as String?,
        code: json['code'] as String?,
        parentRegionId: json['parent_region_id'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );
}

class AssalTaxonomy {
  const AssalTaxonomy({
    required this.id,
    required this.code,
    required this.nameAr,
    this.nameEn,
    this.description,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String code;
  final String nameAr;
  final String? nameEn;
  final String? description;
  final Map<String, Object?> metadata;

  factory AssalTaxonomy.fromJson(Map<String, Object?> json) => AssalTaxonomy(
        id: json['id']! as String,
        code: json['code']! as String,
        nameAr: json['name_ar']! as String,
        nameEn: json['name_en'] as String?,
        description: json['description'] as String?,
        metadata: (json['metadata'] as Map?)?.cast<String, Object?>() ?? const <String, Object?>{},
      );
}

class AssalStoreSummary {
  const AssalStoreSummary({
    required this.id,
    required this.merchantId,
    required this.nameAr,
    required this.slug,
    this.description,
    this.regionId,
    this.logoUrl,
    this.coverUrl,
    this.isVerified = false,
    this.status = StoreStatus.pending,
    this.ratingAverage = 0,
    this.reviewCount = 0,
    this.followersCount = 0,
  });

  final String id;
  final String merchantId;
  final String nameAr;
  final String slug;
  final String? description;
  final String? regionId;
  final String? logoUrl;
  final String? coverUrl;
  final bool isVerified;
  final StoreStatus status;
  final double ratingAverage;
  final int reviewCount;
  final int followersCount;

  factory AssalStoreSummary.fromJson(Map<String, Object?> json) => AssalStoreSummary(
        id: json['id']! as String,
        merchantId: json['merchant_id']! as String,
        nameAr: json['name_ar']! as String,
        slug: json['slug']! as String,
        description: json['description'] as String?,
        regionId: json['region_id'] as String?,
        logoUrl: json['logo_url'] as String?,
        coverUrl: json['cover_url'] as String?,
        isVerified: json['is_verified'] as bool? ?? false,
        status: _storeStatus(json['status'] as String? ?? 'pending'),
        ratingAverage: (json['rating_average'] as num?)?.toDouble() ?? 0,
        reviewCount: json['review_count'] as int? ?? 0,
        followersCount: json['followers_count'] as int? ?? 0,
      );
}

class AssalProductSummary {
  const AssalProductSummary({
    required this.id,
    required this.storeId,
    required this.nameAr,
    required this.productType,
    required this.status,
    this.nameEn,
    this.description,
    this.taxonomyId,
    this.gradeLevel,
    this.isFeatured = false,
    this.primaryImageUrl,
    this.ratingAverage = 0,
    this.reviewCount = 0,
  });

  final String id;
  final String storeId;
  final String nameAr;
  final String? nameEn;
  final String? description;
  final ProductType productType;
  final ProductStatus status;
  final String? taxonomyId;
  final int? gradeLevel;
  final bool isFeatured;
  final String? primaryImageUrl;
  final double ratingAverage;
  final int reviewCount;

  factory AssalProductSummary.fromJson(Map<String, Object?> json) => AssalProductSummary(
        id: json['id']! as String,
        storeId: json['store_id']! as String,
        nameAr: json['name_ar']! as String,
        nameEn: json['name_en'] as String?,
        description: json['description'] as String?,
        productType: _productType(json['product_type'] as String? ?? 'honey'),
        status: _productStatus(json['status'] as String? ?? 'draft'),
        taxonomyId: json['taxonomy_id'] as String?,
        gradeLevel: json['grade_level'] as int?,
        isFeatured: json['is_featured'] as bool? ?? false,
        primaryImageUrl: json['primary_image_url'] as String?,
        ratingAverage: (json['rating_average'] as num?)?.toDouble() ?? 0,
        reviewCount: json['review_count'] as int? ?? 0,
      );
}

class AssalReviewSummary {
  const AssalReviewSummary({
    required this.id,
    required this.productId,
    required this.storeId,
    required this.authorId,
    required this.rating,
    required this.status,
    this.body,
    this.createdAt,
  });

  final String id;
  final String productId;
  final String storeId;
  final String authorId;
  final int rating;
  final ReviewStatus status;
  final String? body;
  final DateTime? createdAt;

  factory AssalReviewSummary.fromJson(Map<String, Object?> json) => AssalReviewSummary(
        id: json['id']! as String,
        productId: json['product_id']! as String,
        storeId: json['store_id']! as String,
        authorId: json['author_id']! as String,
        rating: json['rating']! as int,
        status: _reviewStatus(json['status'] as String? ?? 'pending'),
        body: json['body'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      );
}

class AssalRequestSummary {
  const AssalRequestSummary({
    required this.id,
    required this.requesterId,
    required this.storeId,
    required this.subject,
    required this.status,
    this.body,
    this.preferredHandoffOption,
    this.createdAt,
  });

  final String id;
  final String requesterId;
  final String storeId;
  final String subject;
  final RequestStatus status;
  final String? body;
  final String? preferredHandoffOption;
  final DateTime? createdAt;

  factory AssalRequestSummary.fromJson(Map<String, Object?> json) => AssalRequestSummary(
        id: json['id']! as String,
        requesterId: json['requester_id']! as String,
        storeId: json['store_id']! as String,
        subject: json['subject']! as String,
        status: _requestStatus(json['status'] as String? ?? 'open'),
        body: json['body'] as String?,
        preferredHandoffOption: json['preferred_handoff_option'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      );
}

class AssalNotificationSummary {
  const AssalNotificationSummary({
    required this.id,
    required this.userId,
    required this.notificationType,
    required this.titleAr,
    this.bodyAr,
    this.payload = const <String, Object?>{},
    this.readAt,
  });

  final String id;
  final String userId;
  final String notificationType;
  final String titleAr;
  final String? bodyAr;
  final Map<String, Object?> payload;
  final DateTime? readAt;

  factory AssalNotificationSummary.fromJson(Map<String, Object?> json) => AssalNotificationSummary(
        id: json['id']! as String,
        userId: json['user_id']! as String,
        notificationType: json['notification_type']! as String,
        titleAr: json['title_ar']! as String,
        bodyAr: json['body_ar'] as String?,
        payload: (json['payload'] as Map?)?.cast<String, Object?>() ?? const <String, Object?>{},
        readAt: DateTime.tryParse(json['read_at'] as String? ?? ''),
      );
}

sealed class AssalLoadState<T> {
  const AssalLoadState();
}

final class AssalLoading<T> extends AssalLoadState<T> {
  const AssalLoading();
}

final class AssalData<T> extends AssalLoadState<T> {
  const AssalData(this.value);
  final T value;
}

final class AssalEmpty<T> extends AssalLoadState<T> {
  const AssalEmpty(this.messageAr);
  final String messageAr;
}

final class AssalError<T> extends AssalLoadState<T> {
  const AssalError(this.messageAr, {this.code});
  final String messageAr;
  final String? code;
}

Map<String, Object?> jsonMap(String value) => (jsonDecode(value) as Map).cast<String, Object?>();

AssalRole _role(String value) => AssalRole.values.firstWhere((item) => item.name == value, orElse: () => AssalRole.customer);
ProductType _productType(String value) => ProductType.values.firstWhere((item) => item.name == value, orElse: () => ProductType.honey);
ProductStatus _productStatus(String value) => ProductStatus.values.firstWhere((item) => item.name == value, orElse: () => ProductStatus.draft);
StoreStatus _storeStatus(String value) => StoreStatus.values.firstWhere((item) => item.name == value, orElse: () => StoreStatus.pending);
VerificationStatus _verificationStatus(String value) => VerificationStatus.values.firstWhere((item) => item.name == value, orElse: () => VerificationStatus.pending);
ReviewStatus _reviewStatus(String value) => ReviewStatus.values.firstWhere((item) => item.name == value, orElse: () => ReviewStatus.pending);
RequestStatus _requestStatus(String value) => switch (value) {
      'in_progress' => RequestStatus.inProgress,
      'answered' => RequestStatus.answered,
      'closed' => RequestStatus.closed,
      'cancelled' => RequestStatus.cancelled,
      _ => RequestStatus.open,
    };
