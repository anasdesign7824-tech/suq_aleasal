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

class AssalBannerSummary {
  const AssalBannerSummary({required this.id, required this.titleAr, required this.descriptionAr, required this.ctaLabelAr, required this.imageUrl, this.targetQuery, this.sortOrder = 0, this.isActive = true});
  final String id;
  final String titleAr;
  final String descriptionAr;
  final String ctaLabelAr;
  final String imageUrl;
  final String? targetQuery;
  final int sortOrder;
  final bool isActive;

  factory AssalBannerSummary.fromJson(Map<String, Object?> json) => AssalBannerSummary(
        id: _string(json['id']),
        titleAr: _string(json['title_ar']),
        descriptionAr: _string(json['description_ar']),
        ctaLabelAr: _string(json['cta_label_ar']),
        imageUrl: _string(json['image_url']),
        targetQuery: _stringOrNull(json['target_query']),
        sortOrder: _int(json['sort_order']),
        isActive: json['is_active'] as bool? ?? true,
      );
}

class AssalCategorySummary {
  const AssalCategorySummary({
    required this.id,
    required this.nameAr,
    this.nameEn,
    this.description,
    this.productType = ProductType.honey,
    this.productCount = 0,
  });

  final String id;
  final String nameAr;
  final String? nameEn;
  final String? description;
  final ProductType productType;
  final int productCount;

  factory AssalCategorySummary.fromJson(Map<String, Object?> json) =>
      AssalCategorySummary(
        id: _string(json['id']),
        nameAr: _string(json['name_ar']),
        nameEn: _stringOrNull(json['name_en']),
        description: _stringOrNull(json['description']),
        productType: _productType(_string(json['category_kind'], fallback: 'honey')),
        productCount: _int(json['product_count']),
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
    this.avatarUrl,
    this.merchantNameAr,
    this.galleryUrls = const <String>[],
    this.socialLinks = const <String, String>{},
    this.deliveryOptions = const <String>[],
    this.pickupLocations = const <String>[],
    this.contactPhone,
    this.contactWhatsapp,
    this.contactTelegram,
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
  final String? avatarUrl;
  final String? merchantNameAr;
  final List<String> galleryUrls;
  final Map<String, String> socialLinks;
  final List<String> deliveryOptions;
  final List<String> pickupLocations;
  final String? contactPhone;
  final String? contactWhatsapp;
  final String? contactTelegram;
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
        avatarUrl: _stringOrNull(json['avatar_url']),
        merchantNameAr: _stringOrNull(json['merchant_name_ar']),
        galleryUrls: _strings(json['gallery_urls'] ?? json['gallery']),
        socialLinks: _stringMap(json['social_links']),
        deliveryOptions: _strings(json['delivery_options']),
        pickupLocations: _strings(json['pickup_locations']),
        contactPhone: _stringOrNull(json['contact_phone']),
        contactWhatsapp: _stringOrNull(json['contact_whatsapp']),
        contactTelegram: _stringOrNull(json['contact_telegram']),
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
    this.gradeLevels = const <int>[],
    this.gradeLabelAr,
    this.gradeLabels = const <String>[],
    this.components = const <String>[],
    this.isFeatured = false,
    this.primaryImageUrl,
    this.imageUrls = const <String>[],
    this.originCountry,
    this.provinceNameAr,
    this.honeyIdentity,
    this.qualityLabelAr,
    this.processingMethodAr,
    this.processingStatusAr,
    this.packagingLabelAr,
    this.productionDate,
    this.packagedDate,
    this.shelfLifeLabelAr,
    this.deliveryOptions = const <String>[],
    this.pickupLocations = const <String>[],
    this.viewsCount = 0,
    this.likesCount = 0,
    this.price,
    this.currencyCode = 'YER',
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
  final List<int> gradeLevels;
  final String? gradeLabelAr;
  final List<String> gradeLabels;
  final List<String> components;
  final bool isFeatured;
  final String? primaryImageUrl;
  final List<String> imageUrls;
  final String? originCountry;
  final String? provinceNameAr;
  final String? honeyIdentity;
  final String? qualityLabelAr;
  final String? processingMethodAr;
  final String? processingStatusAr;
  final String? packagingLabelAr;
  final DateTime? productionDate;
  final DateTime? packagedDate;
  final String? shelfLifeLabelAr;
  final List<String> deliveryOptions;
  final List<String> pickupLocations;
  final int viewsCount;
  final int likesCount;
  final double? price;
  final String currencyCode;
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
      gradeLevels: levels,
      gradeLabelAr: _stringOrNull(json['grade_label_ar']),
      gradeLabels: _valueStrings(json['grades'] ?? json['grade_labels']),
      components: _strings(json['components']),
      isFeatured: json['is_featured'] as bool? ?? false,
      primaryImageUrl: _stringOrNull(json['primary_image_url']),
      imageUrls: _strings(json['image_urls'] ?? json['images']),
      originCountry: _stringOrNull(json['origin_country']),
      provinceNameAr: _stringOrNull(json['province_name_ar']),
      honeyIdentity: _stringOrNull(json['honey_identity']),
      qualityLabelAr: _stringOrNull(json['quality_label_ar']),
      processingMethodAr: _stringOrNull(json['processing_method_ar']),
      processingStatusAr: _stringOrNull(json['processing_status_ar']),
      packagingLabelAr: _stringOrNull(json['packaging_label_ar']),
      productionDate: _dateOrNull(json['production_date']),
      packagedDate: _dateOrNull(json['packaged_date']),
      shelfLifeLabelAr: _stringOrNull(json['shelf_life_label_ar']),
      deliveryOptions: _strings(json['delivery_options']),
      pickupLocations: _strings(json['pickup_locations']),
      viewsCount: _int(json['views_count']),
      likesCount: _int(json['likes_count']),
      price: _numberOrNull(json['price']),
      currencyCode: _string(json['currency_code'], fallback: 'YER'),
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
  const AssalReviewSummary({required this.id, required this.productId, required this.storeId, required this.authorId, required this.rating, required this.status, this.authorName, this.body, this.createdAt, this.updatedAt, this.helpfulCount = 0, this.merchantReply, this.isLocal = false});
  final String id;
  final String productId;
  final String storeId;
  final String authorId;
  final int rating;
  final ReviewStatus status;
  final String? authorName;
  final String? body;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int helpfulCount;
  final String? merchantReply;
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
        createdAt: _dateOrNull(json['created_at']),
        updatedAt: _dateOrNull(json['updated_at']),
        helpfulCount: _int(json['helpful_count']),
        merchantReply: _stringOrNull(json['merchant_reply']),
        isLocal: json['is_local'] as bool? ?? false,
      );
}

class AssalCommentSummary {
  const AssalCommentSummary({required this.id, required this.targetId, required this.authorId, required this.authorName, required this.body, this.parentId, this.createdAt, this.updatedAt, this.likeCount = 0, this.replyCount = 0, this.isLiked = false, this.isLocal = false});
  final String id;
  final String targetId;
  final String authorId;
  final String authorName;
  final String body;
  final String? parentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int likeCount;
  final int replyCount;
  final bool isLiked;
  final bool isLocal;

  factory AssalCommentSummary.fromJson(Map<String, Object?> json) => AssalCommentSummary(
        id: _string(json['id']),
        targetId: _string(json['target_id']),
        authorId: _string(json['author_id']),
        authorName: _string(json['author_name'], fallback: 'عميل عسلكم'),
        body: _string(json['body']),
        parentId: _stringOrNull(json['parent_id']),
        createdAt: _dateOrNull(json['created_at']),
        updatedAt: _dateOrNull(json['updated_at']),
        likeCount: _int(json['like_count']),
        replyCount: _int(json['reply_count']),
        isLiked: json['is_liked'] as bool? ?? false,
      );
}

class AssalRequestSummary {
  const AssalRequestSummary({
    required this.id,
    required this.requesterId,
    required this.storeId,
    this.merchantId,
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
    this.deliveryNote,
    this.updatedAt,
    this.createdAt,
  });

  final String id;
  final String requesterId;
  final String storeId;
  final String? merchantId;
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
  final String? deliveryNote;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  factory AssalRequestSummary.fromJson(Map<String, Object?> json) => AssalRequestSummary(
        id: _string(json['id']),
        requesterId: _string(json['requester_id']),
        storeId: _string(json['store_id']),
        merchantId: _stringOrNull(json['merchant_id']),
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
        deliveryNote: _stringOrNull(json['delivery_note']),
        updatedAt: _dateOrNull(json['updated_at']),
        createdAt: _dateOrNull(json['created_at']),
      );
}

class AssalMerchantApplicationDraft {
  const AssalMerchantApplicationDraft({
    required this.displayName,
    required this.phone,
    required this.experience,
    required this.location,
    required this.specialties,
    this.certificateNote,
    this.storeDescription,
    this.regionId,
    this.logoUrl,
    this.coverUrl,
  });
  final String displayName;
  final String phone;
  final String experience;
  final String location;
  final String specialties;
  final String? certificateNote;
  final String? storeDescription;
  final String? regionId;
  final String? logoUrl;
  final String? coverUrl;
}

class AssalMerchantApplicationSummary {
  const AssalMerchantApplicationSummary({
    required this.id,
    required this.userId,
    required this.status,
    required this.displayName,
    required this.submittedAt,
    this.reviewNote,
    this.storeId,
    this.storeStatus,
    this.storeVerified = false,
    this.storeLogoUrl,
    this.storeCoverUrl,
  });
  final String id;
  final String userId;
  final String status;
  final String displayName;
  final DateTime submittedAt;
  final String? reviewNote;
  final String? storeId;
  final String? storeStatus;
  final bool storeVerified;
  final String? storeLogoUrl;
  final String? storeCoverUrl;
}

class AssalMerchantWorkspaceDraft {
  const AssalMerchantWorkspaceDraft({
    required this.businessName,
    this.description,
    this.regionId,
    this.phone,
    this.logoUrl,
    this.coverUrl,
  });

  final String businessName;
  final String? description;
  final String? regionId;
  final String? phone;
  final String? logoUrl;
  final String? coverUrl;
}

class AssalMerchantWorkspaceSummary {
  const AssalMerchantWorkspaceSummary({
    required this.store,
    required this.verificationStatus,
    required this.publicStatus,
    this.canEdit = true,
    this.canPublish = false,
  });

  final AssalStoreSummary store;
  final String verificationStatus;
  final String publicStatus;
  final bool canEdit;
  final bool canPublish;

  factory AssalMerchantWorkspaceSummary.fromJson(Map<String, Object?> json) {
    final rawStore = json['store'];
    final store = rawStore is Map
        ? AssalStoreSummary.fromJson(rawStore.cast<String, Object?>())
        : AssalStoreSummary(
            id: '',
            merchantId: '',
            nameAr: '',
            slug: '',
          );
    return AssalMerchantWorkspaceSummary(
      store: store,
      verificationStatus: _string(
        json['verification_status'],
        fallback: 'pending',
      ),
      publicStatus: _string(json['public_status'], fallback: 'pending'),
      canEdit: json['can_edit'] as bool? ?? true,
      canPublish: json['can_publish'] as bool? ?? false,
    );
  }
}

class AssalProductDraft {
  const AssalProductDraft({
    required this.nameAr,
    this.nameEn,
    this.description,
    this.taxonomyId,
    this.productType = ProductType.honey,
    this.gradeLevel,
    this.metadata = const <String, Object?>{},
    this.imageUrls = const <String>[],
  });

  final String nameAr;
  final String? nameEn;
  final String? description;
  final String? taxonomyId;
  final ProductType productType;
  final int? gradeLevel;
  final Map<String, Object?> metadata;
  final List<String> imageUrls;
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
  const AssalUserProfile({required this.id, required this.nameAr, this.email, this.avatarUrl, this.coverUrl, this.bio, this.phone, this.location, this.preferences = const <String, Object?>{}, this.createdAt, this.updatedAt, this.followersCount = 0, this.followingCount = 0, this.role = AssalRole.customer});
  final String id;
  final String nameAr;
  final String? email;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final String? phone;
  final String? location;
  final Map<String, Object?> preferences;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int followersCount;
  final int followingCount;
  final AssalRole role;

  factory AssalUserProfile.fromJson(Map<String, Object?> json) => AssalUserProfile(
        id: _string(json['id']),
        nameAr: _string(json['name_ar'], fallback: 'عميل عسلكم'),
        email: _stringOrNull(json['email']),
        avatarUrl: _stringOrNull(json['avatar_url']),
        coverUrl: _stringOrNull(json['cover_url']),
        bio: _stringOrNull(json['bio']),
        phone: _stringOrNull(json['phone']),
        location: _stringOrNull(json['location'] ?? json['location_label']),
        preferences: _map(json['preferences']),
        createdAt: _dateOrNull(json['created_at']),
        updatedAt: _dateOrNull(json['updated_at']),
        followersCount: _int(json['followers_count']),
        followingCount: _int(json['following_count']),
        role: _role(_string(json['role'], fallback: 'customer')),
      );
}

class AssalUserProfilePatch {
  const AssalUserProfilePatch({this.nameAr, this.bio, this.phone, this.locationLabel, this.avatarUrl, this.coverUrl, this.latitude, this.longitude});
  final String? nameAr;
  final String? bio;
  final String? phone;
  final String? locationLabel;
  final String? avatarUrl;
  final String? coverUrl;
  final double? latitude;
  final double? longitude;
}

class AssalSession {
  const AssalSession({required this.isAuthenticated, required this.role, this.user});
  final bool isAuthenticated;
  final AssalRole role;
  final AssalUserProfile? user;
  static const guest = AssalSession(isAuthenticated: false, role: AssalRole.guest);
}

class AssalConversationSummary {
  const AssalConversationSummary({required this.id, required this.storeId, required this.storeName, required this.lastMessage, required this.updatedAt, this.participantIds = const <String>[], this.unreadCount = 0, this.lastReadAt});
  final String id;
  final String storeId;
  final String storeName;
  final String lastMessage;
  final DateTime updatedAt;
  final List<String> participantIds;
  final int unreadCount;
  final DateTime? lastReadAt;

  factory AssalConversationSummary.fromJson(Map<String, Object?> json) => AssalConversationSummary(
        id: _string(json['id']),
        storeId: _string(json['store_id']),
        storeName: _string(json['store_name'], fallback: 'متجر عسلكم'),
        lastMessage: _string(json['last_message']),
        updatedAt: _dateOrNull(json['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        participantIds: _strings(json['participant_ids']),
        unreadCount: _int(json['unread_count']),
        lastReadAt: _dateOrNull(json['last_read_at']),
      );
}

class AssalMessageSummary {
  const AssalMessageSummary({required this.id, required this.conversationId, required this.senderId, required this.body, required this.sentAt, this.isMine = false, this.readAt, this.attachments = const <String>[]});
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime sentAt;
  final bool isMine;
  final DateTime? readAt;
  final List<String> attachments;

  factory AssalMessageSummary.fromJson(Map<String, Object?> json) => AssalMessageSummary(
        id: _string(json['id']),
        conversationId: _string(json['conversation_id']),
        senderId: _string(json['sender_id']),
        body: _string(json['body']),
        sentAt: _dateOrNull(json['sent_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        isMine: json['is_mine'] as bool? ?? false,
        readAt: _dateOrNull(json['read_at']),
        attachments: _strings(json['attachments']),
      );
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
double? _numberOrNull(Object? value) => value is num ? value.toDouble() : double.tryParse('$value');
List<String> _strings(Object? value) => value is List ? value.whereType<String>().toList(growable: false) : const <String>[];
List<String> _valueStrings(Object? value) => value is List ? value.map((item) => '$item').toList(growable: false) : const <String>[];
List<int> _ints(Object? value) => value is List ? value.whereType<num>().map((item) => item.toInt()).toList(growable: false) : const <int>[];
Map<String, Object?> _map(Object? value) => value is Map ? value.cast<String, Object?>() : const <String, Object?>{};
Map<String, String> _stringMap(Object? value) => value is Map ? value.map((key, item) => MapEntry('$key', '$item')) : const <String, String>{};
DateTime? _dateOrNull(Object? value) => value is DateTime ? value : DateTime.tryParse(_string(value));

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
