import 'package:assalkom_contracts/assal_domain.dart';

import 'dart:async';
import 'dart:developer' as developer;

import 'assal_repository.dart';

class ProductionRepository implements AssalRepository {
  const ProductionRepository({
    required ProductionQueryGateway gateway,
    AssalAuthGateway? authGateway,
  }) : _gateway = gateway,
       _authGateway = authGateway;
  final ProductionQueryGateway _gateway;
  final AssalAuthGateway? _authGateway;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.production;

  AssalLoadState<List<T>> _state<T>(List<T> values, String emptyMessage) =>
      values.isEmpty
      ? AssalEmpty<List<T>>(emptyMessage)
      : AssalData<List<T>>(values);

  Future<AssalLoadState<T>> _write<T>({
    required String resource,
    required Future<T> Function() write,
  }) async {
    final started = DateTime.now();
    try {
      final value = await write();
      developer.log('write_ok resource=$resource elapsed_ms=${DateTime.now().difference(started).inMilliseconds}', name: 'assalkom.production');
      return AssalData(value);
    } on TimeoutException catch (error, stackTrace) {
      developer.log('write_timeout resource=$resource', name: 'assalkom.production', error: error, stackTrace: stackTrace);
      return const AssalError('تأخر الاتصال بالخدمة. حاول مرة أخرى.', code: 'timeout');
    } on Object catch (error, stackTrace) {
      final raw = error.toString();
      final isSchema = raw.contains('PGRST205') || raw.contains('PGRST204') || raw.contains('column') || raw.contains('relation');
      final isAuth = raw.contains('42501') || raw.contains('permission') || raw.contains('JWT') || raw.contains('row-level security');
      final code = isSchema ? 'schema_mismatch' : (isAuth ? 'permission_denied' : 'data_write_failed');
      final message = isSchema ? 'تعذر حفظ البيانات بسبب عدم توافق إعدادات الخدمة.' : (isAuth ? 'لا تملك صلاحية تنفيذ هذا الإجراء.' : 'تعذر حفظ البيانات الآن. حاول مرة أخرى.');
      developer.log('write_failed resource=$resource code=$code', name: 'assalkom.production', error: error, stackTrace: stackTrace);
      return AssalError(message, code: code);
    }
  }

  Future<AssalLoadState<List<T>>> _readList<T>({
    required String resource,
    required String emptyMessage,
    required Future<List<T>> Function() read,
  }) async {
    final started = DateTime.now();
    try {
      final values = await read();
      developer.log(
        'read_ok resource=$resource count=${values.length} elapsed_ms=${DateTime.now().difference(started).inMilliseconds}',
        name: 'assalkom.production',
      );
      return _state(values, emptyMessage);
    } on TimeoutException catch (error, stackTrace) {
      developer.log(
        'read_timeout resource=$resource',
        name: 'assalkom.production',
        error: error,
        stackTrace: stackTrace,
      );
      return AssalError<List<T>>(
        'تأخر الاتصال بالخدمة. حاول مرة أخرى.',
        code: 'timeout',
      );
    } on Object catch (error, stackTrace) {
      final raw = error.toString();
      final isSchema =
          raw.contains('PGRST205') ||
          raw.contains('PGRST204') ||
          raw.contains('column') ||
          raw.contains('relation');
      final isNetwork =
          raw.contains('SocketException') ||
          raw.contains('Failed host lookup') ||
          raw.contains('Connection reset');
      final code = isSchema
          ? 'schema_mismatch'
          : (isNetwork ? 'network' : 'data_read_failed');
      final message = isSchema
          ? 'تعذر قراءة إعدادات الخدمة. يحتاج هذا الجزء إلى تحديث قاعدة البيانات.'
          : (isNetwork
                ? 'تعذر الوصول إلى الخدمة الآن. تحقق من الاتصال ثم أعد المحاولة.'
                : 'تعذر قراءة البيانات الآن. حاول مرة أخرى.');
      developer.log(
        'read_failed resource=$resource code=$code elapsed_ms=${DateTime.now().difference(started).inMilliseconds}',
        name: 'assalkom.production',
        error: error,
        stackTrace: stackTrace,
      );
      return AssalError<List<T>>(message, code: code);
    }
  }

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

  AssalSession _sessionFromIdentity(
    AssalAuthIdentity? identity, {
    Map<String, Object?> profile = const <String, Object?>{},
    bool isAdmin = false,
  }) {
    if (identity == null) return AssalSession.guest;
    final role = isAdmin ? AssalRole.admin : _roleFrom(profile['role']);
    final user = AssalUserProfile.fromJson({
      'id': identity.id,
      'name_ar':
          profile['display_name'] ?? identity.displayName ?? 'عميل عسلكم',
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
      final rows = await _gateway.select(
        'profiles',
        filters: {'user_id': identity.id},
      );
      if (rows.isNotEmpty) profile = rows.first;
    } on Object {
      // Auth remains valid even if profile hydration is temporarily unavailable.
    }
    try {
      final rows = await _gateway.select(
        'admin_users',
        filters: {'user_id': identity.id},
      );
      isAdmin = rows.isNotEmpty;
    } on Object {
      isAdmin = false;
    }
    return _sessionFromIdentity(identity, profile: profile, isAdmin: isAdmin);
  }

  Future<AssalLoadState<AssalSession>> _authOperation(
    Future<AssalAuthIdentity?> Function(AssalAuthGateway auth) operation,
  ) async {
    final auth = _authGateway;
    if (auth == null)
      return const AssalError(
        'المصادقة الإنتاجية غير مهيأة بعد.',
        code: 'production_auth_not_configured',
      );
    try {
      final identity = await operation(auth);
      if (identity == null)
        return const AssalError(
          'لم تكتمل جلسة المصادقة.',
          code: 'auth_session_missing',
        );
      return AssalData(await _sessionForIdentity(identity));
    } on AssalAuthFailure catch (error) {
      return AssalError(error.messageAr, code: error.code);
    } on Object {
      return const AssalError(
        'تعذر إكمال المصادقة. تحقق من الاتصال والإعدادات ثم حاول مرة أخرى.',
        code: 'auth_unexpected_error',
      );
    }
  }

  @override
  Future<AssalLoadState<List<AssalRegion>>> listRegions() => _readList(
    resource: 'regions',
    emptyMessage: 'لا توجد مناطق منشورة بعد',
    read: () async {
      final rows = await _gateway.select(
        'regions',
        filters: const {'is_active': true},
      );
      return rows.map(AssalRegion.fromJson).toList(growable: false);
    },
  );

  @override
  Future<AssalLoadState<List<AssalTaxonomy>>> listTaxonomy() => _readList(
    resource: 'honey_taxonomy',
    emptyMessage: 'لا توجد تصنيفات منشورة بعد',
    read: () async {
      final rows = await _gateway.select(
        'honey_taxonomy',
        filters: const {'is_active': true},
      );
      return rows.map(AssalTaxonomy.fromJson).toList(growable: false);
    },
  );

  @override
  Future<AssalLoadState<List<AssalCategorySummary>>> listCategories() =>
      _readList(
        resource: 'categories',
        emptyMessage: 'لا توجد أقسام منشورة بعد',
        read: () async {
          final rows = await _gateway.select(
            'categories',
            filters: const {'is_active': true},
          );
          return rows
              .map(AssalCategorySummary.fromJson)
              .toList(growable: false);
        },
      );

  @override
  Future<AssalLoadState<List<AssalBannerSummary>>> listBanners() => _readList(
    resource: 'banners',
    emptyMessage: 'لا توجد حملات استكشاف منشورة بعد',
    read: () async {
      final rows = await _gateway.select(
        'customer_banners',
        filters: const {'is_active': true},
      );
      final values =
          rows.map(AssalBannerSummary.fromJson).toList(growable: false)
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return values;
    },
  );

  @override
  Future<AssalLoadState<List<String>>> listPopularSearches() async {
    try {
      final rows = await _gateway.select(
        'popular_searches',
        filters: const {'is_active': true},
      );
      final values = rows
          .map((row) => row['term_ar'])
          .whereType<String>()
          .toList(growable: false);
      return _state(values, 'لا توجد اقتراحات بحث متاحة');
    } on Object {
      return const AssalEmpty('لا توجد اقتراحات بحث متاحة بعد');
    }
  }

  @override
  Future<AssalLoadState<List<AssalStoreSummary>>> listStores({
    String? regionId,
  }) => _readList(
    resource: 'stores',
    emptyMessage: 'لا توجد متاجر منشورة بعد',
    read: () async {
      final rows = await _gateway.select(
        'customer_stores',
        filters: {
          'status': 'active',
          if (regionId != null) 'region_id': regionId,
        },
      );
      return rows.map(AssalStoreSummary.fromJson).toList(growable: false);
    },
  );

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listFavoriteProducts(
    String userId,
  ) async {
    final rows = await _gateway.select(
      'favorites',
      filters: {'user_id': userId},
    );
    final ids = rows
        .map((row) => row['product_id'])
        .whereType<String>()
        .toSet();
    if (ids.isEmpty) return const AssalEmpty('لا توجد منتجات محفوظة');
    final products = await _gateway.select(
      'customer_products',
      filters: const {'status': 'active'},
    );
    return _state(
      products
          .where((row) => ids.contains(row['id']))
          .map(AssalProductSummary.fromJson)
          .toList(growable: false),
      'لا توجد منتجات محفوظة',
    );
  }

  @override
  Future<AssalLoadState<List<AssalTaxonomy>>> listFavoriteTaxonomies(
    String userId,
  ) async {
    final favoriteRows = await _gateway.select(
      'favorites',
      filters: {'user_id': userId},
    );
    final productIds = favoriteRows
        .map((row) => row['product_id'])
        .whereType<String>()
        .toSet();
    if (productIds.isEmpty)
      return const AssalEmpty('لا توجد تصنيفات مرتبطة بالمحفوظات بعد.');
    final products = await _gateway.select(
      'customer_products',
      filters: const {'status': 'active'},
    );
    final taxonomyIds = products
        .where((row) => productIds.contains(row['id']))
        .map((row) => row['subcategory_id'] ?? row['category_id'])
        .whereType<String>()
        .toSet();
    final taxonomies = await _gateway.select(
      'honey_taxonomy',
      filters: const {'is_active': true},
    );
    return _state(
      taxonomies
          .where((row) => taxonomyIds.contains(row['id']))
          .map(AssalTaxonomy.fromJson)
          .toList(growable: false),
      'لا توجد تصنيفات مرتبطة بالمحفوظات بعد.',
    );
  }

  @override
  Future<AssalLoadState<List<AssalStoreSummary>>> listFollowedStores(
    String userId,
  ) async {
    final rows = await _gateway.select(
      'store_followers',
      filters: {'user_id': userId},
    );
    final ids = rows.map((row) => row['store_id']).whereType<String>().toSet();
    if (ids.isEmpty) return const AssalEmpty('لا توجد متاجر متابَعة');
    final stores = await _gateway.select(
      'customer_stores',
      filters: const {'status': 'active'},
    );
    return _state(
      stores
          .where((row) => ids.contains(row['id']))
          .map(AssalStoreSummary.fromJson)
          .toList(growable: false),
      'لا توجد متاجر متابَعة',
    );
  }

  @override
  Future<AssalLoadState<AssalStoreSummary>> getStore(String storeId) async {
    final rows = await _gateway.select(
      'customer_stores',
      filters: {'id': storeId, 'status': 'active'},
    );
    if (rows.isEmpty)
      return const AssalError('المتجر غير موجود', code: 'not_found');
    return AssalData(AssalStoreSummary.fromJson(rows.first));
  }

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({
    AssalProductQuery query = const AssalProductQuery(),
  }) => _readList(
    resource: 'products',
    emptyMessage: 'لا توجد منتجات منشورة بعد',
    read: () async {
      final rows = await _gateway.select(
        'customer_products',
        filters: {
          'status': 'active',
          if (query.storeId != null) 'store_id': query.storeId,
          if (query.categoryId != null) 'category_id': query.categoryId,
          if (query.regionId != null) 'region_id': query.regionId,
          if (query.provinceId != null) 'province_id': query.provinceId,
          if (query.merchantId != null) 'merchant_id': query.merchantId,
          if (query.availability != null) 'availability': query.availability,
          if (query.processingMethod != null)
            'processing_method_ar': query.processingMethod,
          if (query.processingStatus != null)
            'processing_status_ar': query.processingStatus,
          if (query.packaging != null) 'packaging_label_ar': query.packaging,
        },
      );
      var values = rows
          .map(AssalProductSummary.fromJson)
          .toList(growable: false);
      if (query.featuredOnly)
        values = values
            .where((item) => item.isFeatured)
            .toList(growable: false);
      if (query.subcategoryId != null)
        values = values
            .where((item) => item.taxonomyId == query.subcategoryId)
            .toList(growable: false);
      if (query.productType != null)
        values = values
            .where((item) => item.productType == query.productType)
            .toList(growable: false);
      if (query.gradeLevel != null)
        values = values
            .where((item) => item.gradeLevel == query.gradeLevel)
            .toList(growable: false);
      if (query.originCountry != null)
        values = values
            .where((item) => item.originCountry == query.originCountry)
            .toList(growable: false);
      if (query.certificateId != null)
        values = values
            .where((item) => item.certifications.contains(query.certificateId))
            .toList(growable: false);
      if (query.minRating != null)
        values = values
            .where((item) => item.ratingAverage >= query.minRating!)
            .toList(growable: false);
      if (query.minPrice != null)
        values = values
            .where(
              (item) => item.price != null && item.price! >= query.minPrice!,
            )
            .toList(growable: false);
      if (query.maxPrice != null)
        values = values
            .where(
              (item) => item.price != null && item.price! <= query.maxPrice!,
            )
            .toList(growable: false);
      if (query.verifiedStoresOnly) {
        final stores = await _gateway.select(
          'customer_stores',
          filters: const {'status': 'active', 'is_verified': true},
        );
        final ids = stores.map((row) => row['id']).whereType<String>().toSet();
        values = values
            .where((item) => ids.contains(item.storeId))
            .toList(growable: false);
      }
      final search = query.search?.trim().toLowerCase();
      if (search != null && search.isNotEmpty)
        values = values
            .where(
              (item) =>
                  '${item.nameAr} ${item.categoryNameAr} ${item.subcategoryNameAr} ${item.honeyIdentity} ${item.regionNameAr} ${item.provinceNameAr}'
                      .toLowerCase()
                      .contains(search),
            )
            .toList(growable: false);
      switch (query.sort) {
        case AssalSort.newest:
          values = values.reversed.toList(growable: false);
        case AssalSort.popular:
          values = [...values]
            ..sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
        case AssalSort.rating:
          values = [...values]
            ..sort((a, b) => b.ratingAverage.compareTo(a.ratingAverage));
        case AssalSort.featured:
          values = [...values]
            ..sort(
              (a, b) => (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0),
            );
      }
      return values;
    },
  );

  @override
  Future<AssalLoadState<AssalProductSummary>> getProduct(
    String productId,
  ) async {
    final rows = await _gateway.select(
      'customer_products',
      filters: {'id': productId, 'status': 'active'},
    );
    if (rows.isEmpty)
      return const AssalError('المنتج غير موجود', code: 'not_found');
    return AssalData(AssalProductSummary.fromJson(rows.first));
  }

  @override
  Future<AssalLoadState<List<AssalReviewSummary>>> listReviews(
    String productId,
  ) async {
    final rows = await _gateway.select(
      'reviews',
      filters: {'product_id': productId, 'status': 'approved'},
    );
    return _state(
      rows.map(AssalReviewSummary.fromJson).toList(growable: false),
      'لا توجد مراجعات بعد',
    );
  }

  @override
  Future<AssalLoadState<List<AssalCommentSummary>>> listComments(
    String targetId,
  ) => _readList(
    resource: 'comments',
    emptyMessage: 'لا توجد تعليقات بعد',
    read: () async {
      final productRows = await _gateway.select('comments', filters: {'product_id': targetId, 'status': 'approved'});
      final reviewRows = await _gateway.select('comments', filters: {'review_id': targetId, 'status': 'approved'});
      final rows = [...productRows, ...reviewRows];
      final values = <AssalCommentSummary>[];
      for (final row in rows) {
        final value = Map<String, Object?>.from(row);
        final authorId = value['author_id'];
        if (authorId is String) {
          final users = await _gateway.select('profiles', filters: {'user_id': authorId});
          if (users.isNotEmpty) value['author_name'] = users.first['display_name'];
        }
        value['target_id'] = value['product_id'] ?? value['review_id'];
        values.add(AssalCommentSummary.fromJson(value));
      }
      return values;
    },
  );

  @override
  Future<AssalLoadState<List<AssalRequestSummary>>> listRequests(
    String requesterId,
  ) async {
    final rows = await _gateway.select(
      'requests',
      filters: {'requester_id': requesterId},
    );
    return _state(
      rows.map(AssalRequestSummary.fromJson).toList(growable: false),
      'لا توجد طلبات تواصل',
    );
  }

  @override
  Future<AssalLoadState<AssalRequestSummary>> createRequest(
    String requesterId,
    AssalRequestDraft draft,
  ) => _write(
    resource: 'requests.create',
    write: () async {
      final row = await _gateway.insert('requests', {
        'requester_id': requesterId,
        'store_id': draft.storeId,
        'subject': draft.subject.trim(),
        'body': draft.body.trim().isEmpty ? null : draft.body.trim(),
        'preferred_handoff_option': draft.handoffOption.name,
        'phone': draft.phone,
        'contact_channel': draft.contactChannel,
        'delivery_note': draft.deliveryNote,
        'price_note': draft.priceNote,
        'handoff_details': draft.handoffDetails,
      });
      if (draft.productId != null) {
        await _gateway.insert('request_items', {
          'request_id': row['id'],
          'product_id': draft.productId,
          'quantity': draft.quantity ?? 1,
          'note': draft.priceNote ?? draft.deliveryNote,
        });
      }
      return AssalRequestSummary.fromJson(row);
    },
  );

  @override
  Future<AssalLoadState<List<AssalNotificationSummary>>> listNotifications(
    String userId,
  ) async {
    final rows = await _gateway.select(
      'notifications',
      filters: {'user_id': userId},
    );
    return _state(
      rows.map(AssalNotificationSummary.fromJson).toList(growable: false),
      'لا توجد إشعارات جديدة',
    );
  }

  @override
  Future<AssalLoadState<bool>> markNotificationRead(
    String userId,
    String notificationId,
  ) => _write(
    resource: 'notifications.read',
    write: () async {
      final rows = await _gateway.select('notifications', filters: {'id': notificationId, 'user_id': userId});
      if (rows.isEmpty) throw StateError('notification_not_owned');
      await _gateway.update('notifications', {'read_at': DateTime.now().toIso8601String()}, id: notificationId);
      return true;
    },
  );

  @override
  Future<AssalLoadState<List<AssalConversationSummary>>> listConversations(
    String userId,
  ) => _readList(
    resource: 'conversations',
    emptyMessage: 'لا توجد محادثات بعد',
    read: () async {
      final memberships = await _gateway.select('conversation_participants', filters: {'user_id': userId});
      final values = <AssalConversationSummary>[];
      for (final membership in memberships) {
        final conversationId = membership['conversation_id'];
        if (conversationId is! String) continue;
        final rows = await _gateway.select('conversations', filters: {'id': conversationId});
        if (rows.isEmpty) continue;
        final row = Map<String, Object?>.from(rows.first);
        final storeId = row['store_id'];
        if (storeId is String) {
          final stores = await _gateway.select('customer_stores', filters: {'id': storeId});
          if (stores.isNotEmpty) row['store_name'] = stores.first['name_ar'];
        }
        final messages = await _gateway.select('messages', filters: {'conversation_id': conversationId});
        if (messages.isNotEmpty) {
          final last = messages.last;
          row['last_message'] = last['body'];
          row['updated_at'] = last['created_at'];
        }
        row['participant_ids'] = [userId];
        values.add(AssalConversationSummary.fromJson(row));
      }
      values.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return values;
    },
  );

  @override
  Future<AssalLoadState<AssalConversationSummary>> createConversation(
    String userId,
    String storeId,
  ) => _write(
    resource: 'conversations.create',
    write: () async {
      final existing = await _gateway.select('conversations', filters: {'store_id': storeId, 'created_by': userId});
      Map<String, Object?> row;
      if (existing.isNotEmpty) {
        row = Map<String, Object?>.from(existing.first);
      } else {
        row = await _gateway.insert('conversations', {'store_id': storeId, 'created_by': userId});
      }
      final conversationId = row['id'];
      if (conversationId is! String) throw StateError('conversation_id_missing');
      final participants = await _gateway.select('conversation_participants', filters: {'conversation_id': conversationId, 'user_id': userId});
      if (participants.isEmpty) await _gateway.insert('conversation_participants', {'conversation_id': conversationId, 'user_id': userId});
      final stores = await _gateway.select('customer_stores', filters: {'id': storeId});
      row['store_name'] = stores.isEmpty ? 'متجر عسلكم' : stores.first['name_ar'];
      row['last_message'] = 'ابدأ محادثة جديدة';
      row['updated_at'] = row['last_message_at'] ?? row['created_at'];
      row['participant_ids'] = [userId];
      return AssalConversationSummary.fromJson(row);
    },
  );

  @override
  Future<AssalLoadState<List<AssalMessageSummary>>> listMessages(
    String conversationId,
  ) => _readList(
    resource: 'messages',
    emptyMessage: 'لا توجد رسائل بعد',
    read: () async {
      final identity = await _authGateway?.currentIdentity();
      final rows = await _gateway.select('messages', filters: {'conversation_id': conversationId});
      return rows.map((row) {
        final value = Map<String, Object?>.from(row);
        value['sent_at'] = value['created_at'];
        value['is_mine'] = identity?.id == value['sender_id'];
        return AssalMessageSummary.fromJson(value);
      }).toList(growable: false);
    },
  );

  @override
  Future<AssalLoadState<AssalMessageSummary>> sendMessage(
    String userId,
    AssalMessageDraft draft,
  ) => _write(
    resource: 'messages.create',
    write: () async {
      final body = draft.body.trim();
      if (body.isEmpty) throw StateError('message_empty');
      final participants = await _gateway.select('conversation_participants', filters: {'conversation_id': draft.conversationId, 'user_id': userId});
      if (participants.isEmpty) throw StateError('conversation_not_owned');
      final row = await _gateway.insert('messages', {'conversation_id': draft.conversationId, 'sender_id': userId, 'body': body});
      await _gateway.update('conversations', {'last_message_at': row['created_at']}, id: draft.conversationId);
      final value = Map<String, Object?>.from(row)..['sent_at'] = row['created_at']..['is_mine'] = true;
      return AssalMessageSummary.fromJson(value);
    },
  );
  @override
  Future<AssalLoadState<AssalReviewSummary>> createReview(
    String authorId,
    AssalReviewDraft draft,
  ) => _write(
    resource: 'reviews.create',
    write: () async {
      if (draft.rating < 1 || draft.rating > 5 || draft.body.trim().isEmpty) throw StateError('invalid_review');
      final row = await _gateway.insert('reviews', {
        'product_id': draft.productId,
        'store_id': draft.storeId,
        'author_id': authorId,
        'rating': draft.rating,
        'body': draft.body.trim(),
        'status': 'pending',
      });
      final value = Map<String, Object?>.from(row)..['author_name'] = 'عميل عسلكم';
      return AssalReviewSummary.fromJson(value);
    },
  );

  @override
  Future<AssalLoadState<AssalCommentSummary>> createComment(
    String authorId,
    String authorName,
    String targetId,
    String body,
  ) => _write(
    resource: 'comments.create',
    write: () async {
      final trimmed = body.trim();
      if (trimmed.isEmpty) throw StateError('comment_empty');
      final products = await _gateway.select('products', filters: {'id': targetId});
      final row = await _gateway.insert('comments', {
        'author_id': authorId,
        if (products.isNotEmpty) 'product_id': targetId else 'review_id': targetId,
        'body': trimmed,
        'status': 'pending',
      });
      final value = Map<String, Object?>.from(row)
        ..['target_id'] = targetId
        ..['author_name'] = authorName;
      return AssalCommentSummary.fromJson(value);
    },
  );

  @override
  Future<AssalLoadState<bool>> toggleFollow(
    String userId,
    String storeId,
  ) => _write(
    resource: 'store_followers.toggle',
    write: () async {
      final rows = await _gateway.select('store_followers', filters: {'user_id': userId, 'store_id': storeId});
      if (rows.isNotEmpty) {
        await _gateway.delete('store_followers', filters: {'user_id': userId, 'store_id': storeId});
        return false;
      }
      await _gateway.insert('store_followers', {'user_id': userId, 'store_id': storeId});
      return true;
    },
  );

  @override
  Future<AssalLoadState<bool>> toggleFavorite(
    String userId,
    String targetId,
  ) => _write(
    resource: 'favorites.toggle',
    write: () async {
      final rows = await _gateway.select('favorites', filters: {'user_id': userId, 'product_id': targetId});
      if (rows.isNotEmpty) {
        await _gateway.delete('favorites', filters: {'user_id': userId, 'product_id': targetId});
        return false;
      }
      await _gateway.insert('favorites', {'user_id': userId, 'product_id': targetId});
      return true;
    },
  );

  @override
  Future<AssalLoadState<bool>> toggleLike(
    String userId,
    String targetId,
  ) => _write(
    resource: 'product_likes.toggle',
    write: () async {
      final rows = await _gateway.select('product_likes', filters: {'user_id': userId, 'product_id': targetId});
      if (rows.isNotEmpty) {
        await _gateway.delete('product_likes', filters: {'user_id': userId, 'product_id': targetId});
        return false;
      }
      await _gateway.insert('product_likes', {'user_id': userId, 'product_id': targetId});
      return true;
    },
  );

  @override
  Future<AssalLoadState<void>> trackProductView(String productId) => _write(
    resource: 'product_view_events.create',
    write: () async {
      final identity = await _authGateway?.currentIdentity();
      await _gateway.insert('product_view_events', {'product_id': productId, 'viewer_id': identity?.id});
    },
  );
  @override
  Future<AssalLoadState<AssalSession>> signIn(String email, String password) =>
      _authOperation((auth) async => auth.signInWithPassword(email, password));

  @override
  Future<AssalLoadState<void>> requestEmailOtp(String email) async {
    final auth = _authGateway;
    if (auth == null) {
      return const AssalError(
        'المصادقة الإنتاجية غير مهيأة بعد.',
        code: 'production_auth_not_configured',
      );
    }
    try {
      await auth.requestEmailOtp(email.trim());
      return const AssalData(null);
    } on AssalAuthFailure catch (error) {
      return AssalError(error.messageAr, code: error.code);
    } on Object {
      return const AssalError(
        'تعذر إرسال رمز تسجيل الدخول. تحقق من البريد وحاول مرة أخرى.',
        code: 'email_otp_request_failed',
      );
    }
  }

  @override
  Future<AssalLoadState<AssalSession>> verifyEmailOtp(
    String email,
    String token,
  ) async {
    final auth = _authGateway;
    if (auth == null) {
      return const AssalError(
        'المصادقة الإنتاجية غير مهيأة بعد.',
        code: 'production_auth_not_configured',
      );
    }
    try {
      final identity = await auth.verifyEmailOtp(email.trim(), token);
      if (identity == null) {
        return const AssalError(
          'لم تكتمل جلسة تسجيل الدخول.',
          code: 'email_otp_session_missing',
        );
      }
      return AssalData(await _sessionForIdentity(identity));
    } on AssalAuthFailure catch (error) {
      return AssalError(error.messageAr, code: error.code);
    } on Object {
      return const AssalError(
        'تعذر التحقق من رمز تسجيل الدخول. حاول مرة أخرى.',
        code: 'email_otp_verify_failed',
      );
    }
  }

  @override
  Future<AssalLoadState<void>> requestPasswordReset(String email) async {
    final auth = _authGateway;
    if (auth == null)
      return const AssalError(
        'المصادقة الإنتاجية غير مهيأة بعد.',
        code: 'production_auth_not_configured',
      );
    try {
      await auth.requestPasswordReset(email.trim());
      return const AssalData(null);
    } on AssalAuthFailure catch (error) {
      return AssalError(error.messageAr, code: error.code);
    } on Object {
      return const AssalError(
        'تعذر إرسال رابط إعادة التعيين. حاول مرة أخرى.',
        code: 'password_reset_failed',
      );
    }
  }

  @override
  Future<AssalLoadState<void>> resendEmailConfirmation(String email) async {
    final auth = _authGateway;
    if (auth == null) {
      return const AssalError(
        'المصادقة الإنتاجية غير مهيأة بعد.',
        code: 'production_auth_not_configured',
      );
    }
    try {
      await auth.resendEmailConfirmation(email.trim());
      return const AssalData(null);
    } on AssalAuthFailure catch (error) {
      return AssalError(error.messageAr, code: error.code);
    } on Object {
      return const AssalError(
        'تعذر إرسال رسالة التأكيد الآن. انتظر قليلًا ثم حاول مرة أخرى.',
        code: 'email_confirmation_resend_failed',
      );
    }
  }

  @override
  Future<AssalLoadState<AssalSession>> verifyEmailConfirmation(
    String email,
    String token,
  ) async {
    final auth = _authGateway;
    if (auth == null) {
      return const AssalError(
        'المصادقة الإنتاجية غير مهيأة بعد.',
        code: 'production_auth_not_configured',
      );
    }
    try {
      final identity = await auth.verifyEmailConfirmation(email.trim(), token);
      if (identity == null) {
        return const AssalError(
          'لم يكتمل التحقق من البريد الإلكتروني.',
          code: 'email_otp_session_missing',
        );
      }
      return AssalData(await _sessionForIdentity(identity));
    } on AssalAuthFailure catch (error) {
      return AssalError(error.messageAr, code: error.code);
    } on Object {
      return const AssalError(
        'تعذر التحقق من الرمز الآن. تحقق من الرمز وحاول مرة أخرى.',
        code: 'email_otp_verify_failed',
      );
    }
  }

  @override
  Future<AssalLoadState<void>> deleteAccount() async {
    final auth = _authGateway;
    if (auth == null) {
      return const AssalError(
        'المصادقة الإنتاجية غير مهيأة بعد.',
        code: 'production_auth_not_configured',
      );
    }
    try {
      await auth.deleteAccount();
      return const AssalData(null);
    } on AssalAuthFailure catch (error) {
      return AssalError(error.messageAr, code: error.code);
    } on Object {
      return const AssalError(
        'تعذر حذف الحساب الآن. حاول مرة أخرى.',
        code: 'account_delete_failed',
      );
    }
  }

  @override
  Future<AssalLoadState<AssalSession>> signInWithGoogle() =>
      _authOperation((auth) => auth.signInWithGoogle());

  @override
  Future<AssalLoadState<AssalSession>> signInWithFacebook() =>
      _authOperation((auth) => auth.signInWithFacebook());

  @override
  Future<AssalLoadState<AssalSession>> register(
    String name,
    String email,
    String password,
  ) => _authOperation(
    (auth) => auth.signUp(name: name, email: email, password: password),
  );
  AssalMerchantApplicationSummary _merchantApplicationFromRow(Map<String, Object?> row) => AssalMerchantApplicationSummary(
    id: '${row['id'] ?? ''}',
    userId: '${row['user_id'] ?? ''}',
    status: '${row['status'] ?? 'submitted'}',
    displayName: '${row['display_name'] ?? ''}',
    submittedAt: DateTime.tryParse('${row['submitted_at'] ?? ''}') ?? DateTime.now(),
  );

  @override
  Future<AssalLoadState<AssalMerchantApplicationSummary>>
  submitMerchantApplication(
    String userId,
    AssalMerchantApplicationDraft draft,
  ) => _write(
    resource: 'merchant_applications.submit',
    write: () async {
      if (draft.displayName.trim().length < 2 || draft.phone.trim().length < 6 || draft.experience.trim().length < 4 || draft.location.trim().length < 2 || draft.specialties.trim().length < 2) throw StateError('invalid_merchant_application');
      final row = await _gateway.upsert('merchant_applications', {
        'user_id': userId,
        'display_name': draft.displayName.trim(),
        'phone': draft.phone.trim(),
        'experience': draft.experience.trim(),
        'location': draft.location.trim(),
        'specialties': draft.specialties.trim(),
        'certificate_note': draft.certificateNote?.trim(),
        'status': 'submitted',
        'submitted_at': DateTime.now().toIso8601String(),
      });
      await _gateway.delete('merchant_application_drafts', filters: {'user_id': userId});
      return _merchantApplicationFromRow(row);
    },
  );

  @override
  Future<AssalLoadState<AssalMerchantApplicationSummary?>>
  loadMerchantApplication(String userId) => _write(
    resource: 'merchant_applications.read',
    write: () async {
      final rows = await _gateway.select('merchant_applications', filters: {'user_id': userId});
      return rows.isEmpty ? null : _merchantApplicationFromRow(rows.first);
    },
  );

  @override
  Future<AssalLoadState<AssalMerchantApplicationDraft?>>
  loadMerchantApplicationDraft(String userId) => _write(
    resource: 'merchant_application_drafts.read',
    write: () async {
      final rows = await _gateway.select('merchant_application_drafts', filters: {'user_id': userId});
      if (rows.isEmpty) return null;
      final row = rows.first;
      return AssalMerchantApplicationDraft(
        displayName: '${row['display_name'] ?? ''}',
        phone: '${row['phone'] ?? ''}',
        experience: '${row['experience'] ?? ''}',
        location: '${row['location'] ?? ''}',
        specialties: '${row['specialties'] ?? ''}',
        certificateNote: row['certificate_note'] as String?,
      );
    },
  );

  @override
  Future<AssalLoadState<void>> saveMerchantApplicationDraft(
    String userId,
    AssalMerchantApplicationDraft draft,
  ) => _write(
    resource: 'merchant_application_drafts.write',
    write: () async {
      await _gateway.upsert('merchant_application_drafts', {
        'user_id': userId,
        'display_name': draft.displayName,
        'phone': draft.phone,
        'experience': draft.experience,
        'location': draft.location,
        'specialties': draft.specialties,
        'certificate_note': draft.certificateNote,
        'updated_at': DateTime.now().toIso8601String(),
      });
    },
  );

  @override
  Future<AssalLoadState<void>> clearMerchantApplicationDraft(
    String userId,
  ) => _write(
    resource: 'merchant_application_drafts.delete',
    write: () => _gateway.delete('merchant_application_drafts', filters: {'user_id': userId}),
  );
  @override
  Future<AssalLoadState<void>> signOut() async {
    final auth = _authGateway;
    if (auth == null) return const AssalData(null);
    try {
      await auth.signOut();
      return const AssalData(null);
    } on Object {
      return const AssalError(
        'تعذر تسجيل الخروج. حاول مرة أخرى.',
        code: 'sign_out_failed',
      );
    }
  }
}
