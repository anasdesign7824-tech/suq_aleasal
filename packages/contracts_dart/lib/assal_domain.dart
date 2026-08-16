import 'dart:convert';

enum AssalRole { guest, customer, merchant, admin }
enum ProductType { honey, wax, mix, raw, gift }
enum ProductStatus { draft, pending, active, paused, rejected }
enum StoreStatus { pending, active, paused, rejected, suspended }
enum VerificationStatus { pending, verified, rejected, suspended }
enum ReviewStatus { pending, approved, rejected, hidden }
enum RequestStatus { open, inProgress, answered, closed, cancelled }

enum HandoffOption { pickup, delivery, office, courier, contact }

extension RequestStatusWire on RequestStatus {
  String get wireValue => switch (this) {
        RequestStatus.open => 'open',
        RequestStatus.inProgress => 'in_progress',
        RequestStatus.answered => 'answered',
        RequestStatus.closed => 'closed',
        RequestStatus.cancelled => 'cancelled',
      };

  String get labelAr => switch (this) {
        RequestStatus.open => 'مفتوح',
        RequestStatus.inProgress => 'قيد المتابعة',
        RequestStatus.answered => 'تم الرد',
        RequestStatus.closed => 'مغلق',
        RequestStatus.cancelled => 'ملغي',
      };
}

extension HandoffOptionLabel on HandoffOption {
  String get labelAr => switch (this) {
        HandoffOption.pickup => 'استلام من المتجر',
        HandoffOption.delivery => 'توصيل محلي',
        HandoffOption.office => 'تسليم من مكتب المتجر',
        HandoffOption.courier => 'شركة شحن',
        HandoffOption.contact => 'تحديد التفاصيل بالتواصل',
      };
}

class AssalRegion {
  const AssalRegion({required this.id, required this.nameAr, this.nameEn, this.code, this.parentRegionId, this.isActive = true});
  final String id;
  final String nameAr;
  final String? nameEn;
  final String? code;
  final String? parentRegionId;
  final bool isActive;

  factory AssalRegion.fromJson(Map<String, Object?> json) => AssalRegion(
        id: _string(json['id']),
        nameAr: _string(json['name_ar']),
        nameEn: _stringOrNull(json['name_en']),
        code: _stringOrNull(json['code']),
        parentRegionId: _stringOrNull(json['parent_region_id']),
        isActive: json['is_active'] as bool? ?? true,
      );
}

class AssalTaxonomy {
  const AssalTaxonomy({required this.id, required this.code, required this.nameAr, this.nameEn, this.description, this.metadata = const <String, Object?>{}});
  final String id;
  final String code;
  final String nameAr;
  final String? nameEn;
  final String? description;
  final Map<String, Object?> metadata;

  factory AssalTaxonomy.fromJson(Map<String, Object?> json) => AssalTaxonomy(
        id: _string(json['id']),
        code: _string(json['code']),
        nameAr: _string(json['name_ar']),
        nameEn: _stringOrNull(json['name_en']),
        description: _stringOrNull(json['description']),
        metadata: _map(json['metadata']),
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
    this.regionNameAr,
    this.logoUrl,
    this.coverUrl,
    this.isVerified = false,
    this.status = StoreStatus.pending,
    this.ratingAverage = 0,
    this.reviewCount = 0,
    this.followersCount = 0,
    this.yearsExperience = 0,
    this.bio,
    this.specialties = const <String>[],
    this.certifications = const <String>[],
  });

  final String id;
  final String merchantId;
  final String nameAr;
  final String slug;
  final String? description;
  final String? regionId;
  final String? regionNameAr;
  final String? logoUrl;
  final String? coverUrl;
  final bool isVerified;
  final StoreStatus status;
  final double ratingAverage;
  final int reviewCount;
  final int followersCount;
  final int yearsExperience;
  final String? bio;
  final List<String> specialties;
  final List<String> certifications;

  factory AssalStoreSummary.fromJson(Map<String, Object?> json) => AssalStoreSummary(
        id: _string(json['id']),
        merchantId: _string(json['merchant_id']),
        nameAr: _string(json['name_ar']),
        slug: _string(json['slug']),
        description: _stringOrNull(json['description']),
        regionId: _stringOrNull(json['region_id']),
        regionNameAr: _stringOrNull(json['region_name_ar']),
        logoUrl: _stringOrNull(json['logo_url']),
        coverUrl: _stringOrNull(json['cover_url']),
        isVerified: json['is_verified'] as bool? ?? false,
        status: _storeStatus(_string(json['status'], fallback: 'pending')),
        ratingAverage: _number(json['rating_average']),
        reviewCount: _int(json['review_count']),
        followersCount: _int(json['followers_count']),
        yearsExperience: _int(json['years_experience']),
        bio: _stringOrNull(json['bio']),
        specialties: _strings(json['specialties']),
        certifications: _strings(json['certifications']),
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
    this.categoryNameAr,
    this.subcategoryNameAr,
    this.regionNameAr,
    this.gradeLevel,
    this.gradeLabelAr,
    this.isFeatured = false,
    this.primaryImageUrl,
    this.ratingAverage = 0,
    this.reviewCount = 0,
    this.tags = const <String>[],
    this.badges = const <String>[],
    this.regions = const <String>[],
    this.forms = const <String>[],
    this.purpose,
    this.availability = 'متاح للاستفسار',
    this.weightLabel,
    this.harvestLabel,
    this.certifications = const <String>[],
  });

  final String id;
  final String storeId;
  final String nameAr;
  final String? nameEn;
  final String? description;
  final ProductType productType;
  final ProductStatus status;
  final String? taxonomyId;
  final String? categoryNameAr;
  final String? subcategoryNameAr;
  final String? regionNameAr;
  final int? gradeLevel;
  final String? gradeLabelAr;
  final bool isFeatured;
  final String? primaryImageUrl;
  final double ratingAverage;
  final int reviewCount;
  final List<String> tags;
  final List<String> badges;
  final List<String> regions;
  final List<String> forms;
  final String? purpose;
  final String availability;
  final String? weightLabel;
  final String? harvestLabel;
  final List<String> certifications;

  factory AssalProductSummary.fromJson(Map<String, Object?> json) {
    final levels = _ints(json['grade_levels']);
    return AssalProductSummary(
      id: _string(json['id']),
      storeId: _string(json['store_id']),
      nameAr: _string(json['name_ar']),
      nameEn: _stringOrNull(json['name_en']),
      description: _stringOrNull(json['description']),
      productType: _productType(_string(json['product_type'], fallback: 'honey')),
      status: _productStatus(_string(json['status'], fallback: 'draft')),
      taxonomyId: _stringOrNull(json['subcategory_id'] ?? json['taxonomy_id']),
      categoryNameAr: _stringOrNull(json['category_name_ar']),
      subcategoryNameAr: _stringOrNull(json['subcategory_name_ar']),
      regionNameAr: _stringOrNull(json['region_name_ar']),
      gradeLevel: _intOrNull(json['grade_level']) ?? (levels.isEmpty ? null : levels.first),
      gradeLabelAr: _stringOrNull(json['grade_label_ar']),
      isFeatured: json['is_featured'] as bool? ?? false,
      primaryImageUrl: _stringOrNull(json['primary_image_url']),
      ratingAverage: _number(json['rating_average']),
      reviewCount: _int(json['review_count']),
      tags: _strings(json['tags']),
      badges: _strings(json['badges']),
      regions: _strings(json['regions']),
      forms: _strings(json['forms']),
      purpose: _stringOrNull(json['purpose']),
      availability: _string(json['availability'], fallback: 'متاح للاستفسار'),
      weightLabel: _stringOrNull(json['weight_label']),
      harvestLabel: _stringOrNull(json['harvest_label']),
      certifications: _strings(json['certifications']),
    );
  }
}

class AssalReviewSummary {
  const AssalReviewSummary({required this.id, required this.productId, required this.storeId, required this.authorId, required this.rating, required this.status, this.authorName, this.body, this.createdAt, this.isLocal = false});
  final String id;
  final String productId;
  final String storeId;
  final String authorId;
  final int rating;
  final ReviewStatus status;
  final String? authorName;
  final String? body;
  final DateTime? createdAt;
  final bool isLocal;

  factory AssalReviewSummary.fromJson(Map<String, Object?> json) => AssalReviewSummary(
        id: _string(json['id']),
        productId: _string(json['product_id']),
        storeId: _string(json['store_id']),
        authorId: _string(json['author_id']),
        rating: _int(json['rating']),
        status: _reviewStatus(_string(json['status'], fallback: 'approved')),
        authorName: _stringOrNull(json['author_name']),
        body: _stringOrNull(json['body']),
        createdAt: DateTime.tryParse(_string(json['created_at'])),
        isLocal: json['is_local'] as bool? ?? false,
      );
}

class AssalCommentSummary {
  const AssalCommentSummary({required this.id, required this.targetId, required this.authorId, required this.authorName, required this.body, this.parentId, this.createdAt, this.isLocal = false});
  final String id;
  final String targetId;
  final String authorId;
  final String authorName;
  final String body;
  final String? parentId;
  final DateTime? createdAt;
  final bool isLocal;
}

class AssalRequestSummary {
  const AssalRequestSummary({
    required this.id,
    required this.requesterId,
    required this.storeId,
    required this.subject,
    required this.status,
    this.productId,
    this.productName,
    this.storeName,
    this.requesterName,
    this.body,
    this.quantity,
    this.phone,
    this.preferredHandoffOption,
    this.priceNote,
    this.createdAt,
  });

  final String id;
  final String requesterId;
  final String storeId;
  final String subject;
  final RequestStatus status;
  final String? productId;
  final String? productName;
  final String? storeName;
  final String? requesterName;
  final String? body;
  final int? quantity;
  final String? phone;
  final String? preferredHandoffOption;
  final String? priceNote;
  final DateTime? createdAt;

  factory AssalRequestSummary.fromJson(Map<String, Object?> json) => AssalRequestSummary(
        id: _string(json['id']),
        requesterId: _string(json['requester_id']),
        storeId: _string(json['store_id']),
        subject: _string(json['subject']),
        status: _requestStatus(_string(json['status'], fallback: 'open')),
        productId: _stringOrNull(json['product_id']),
        productName: _stringOrNull(json['product_name']),
        storeName: _stringOrNull(json['store_name']),
        requesterName: _stringOrNull(json['requester_name']),
        body: _stringOrNull(json['body']),
        quantity: _intOrNull(json['quantity']),
        phone: _stringOrNull(json['phone']),
        preferredHandoffOption: _stringOrNull(json['preferred_handoff_option']),
        priceNote: _stringOrNull(json['price_note']),
        createdAt: DateTime.tryParse(_string(json['created_at'])),
      );
}

class AssalNotificationSummary {
  const AssalNotificationSummary({required this.id, required this.userId, required this.notificationType, required this.titleAr, this.bodyAr, this.payload = const <String, Object?>{}, this.readAt});
  final String id;
  final String userId;
  final String notificationType;
  final String titleAr;
  final String? bodyAr;
  final Map<String, Object?> payload;
  final DateTime? readAt;

  factory AssalNotificationSummary.fromJson(Map<String, Object?> json) => AssalNotificationSummary(
        id: _string(json['id']),
        userId: _string(json['user_id']),
        notificationType: _string(json['notification_type']),
        titleAr: _string(json['title_ar']),
        bodyAr: _stringOrNull(json['body_ar']),
        payload: _map(json['payload']),
        readAt: DateTime.tryParse(_string(json['read_at'])),
      );
}

class AssalUserProfile {
  const AssalUserProfile({required this.id, required this.nameAr, this.email, this.avatarUrl, this.bio, this.location, this.followersCount = 0, this.followingCount = 0, this.role = AssalRole.customer});
  final String id;
  final String nameAr;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final String? location;
  final int followersCount;
  final int followingCount;
  final AssalRole role;
}

class AssalSession {
  const AssalSession({required this.isAuthenticated, required this.role, this.user});
  final bool isAuthenticated;
  final AssalRole role;
  final AssalUserProfile? user;
  static const guest = AssalSession(isAuthenticated: false, role: AssalRole.guest);
}

class AssalConversationSummary {
  const AssalConversationSummary({required this.id, required this.storeId, required this.storeName, required this.lastMessage, required this.updatedAt, this.unreadCount = 0});
  final String id;
  final String storeId;
  final String storeName;
  final String lastMessage;
  final DateTime updatedAt;
  final int unreadCount;
}

class AssalMessageSummary {
  const AssalMessageSummary({required this.id, required this.conversationId, required this.senderId, required this.body, required this.sentAt, this.isMine = false});
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime sentAt;
  final bool isMine;
}

sealed class AssalLoadState<T> { const AssalLoadState(); }
final class AssalLoading<T> extends AssalLoadState<T> { const AssalLoading(); }
final class AssalData<T> extends AssalLoadState<T> { const AssalData(this.value); final T value; }
final class AssalEmpty<T> extends AssalLoadState<T> { const AssalEmpty(this.messageAr); final String messageAr; }
final class AssalError<T> extends AssalLoadState<T> { const AssalError(this.messageAr, {this.code}); final String messageAr; final String? code; }

String _string(Object? value, {String fallback = ''}) => value is String ? value : fallback;
String? _stringOrNull(Object? value) => value is String && value.trim().isNotEmpty ? value : null;
int _int(Object? value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
int? _intOrNull(Object? value) => value == null ? null : _int(value);
double _number(Object? value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
List<String> _strings(Object? value) => value is List ? value.whereType<String>().toList(growable: false) : const <String>[];
List<int> _ints(Object? value) => value is List ? value.whereType<num>().map((item) => item.toInt()).toList(growable: false) : const <int>[];
Map<String, Object?> _map(Object? value) => value is Map ? value.cast<String, Object?>() : const <String, Object?>{};

Map<String, Object?> jsonMap(String value) => (jsonDecode(value) as Map).cast<String, Object?>();

AssalRole _role(String value) => AssalRole.values.firstWhere((item) => item.name == value, orElse: () => AssalRole.customer);
ProductType _productType(String value) => ProductType.values.firstWhere((item) => item.name == value, orElse: () => ProductType.honey);
ProductStatus _productStatus(String value) => ProductStatus.values.firstWhere((item) => item.name == value, orElse: () => ProductStatus.draft);
StoreStatus _storeStatus(String value) => StoreStatus.values.firstWhere((item) => item.name == value, orElse: () => StoreStatus.pending);
ReviewStatus _reviewStatus(String value) => ReviewStatus.values.firstWhere((item) => item.name == value, orElse: () => ReviewStatus.approved);
RequestStatus _requestStatus(String value) => switch (value) {
      'in_progress' => RequestStatus.inProgress,
      'answered' => RequestStatus.answered,
      'closed' => RequestStatus.closed,
      'cancelled' => RequestStatus.cancelled,
      _ => RequestStatus.open,
    };
