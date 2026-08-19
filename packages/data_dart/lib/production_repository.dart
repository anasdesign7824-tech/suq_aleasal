import 'package:assalkom_contracts/assal_domain.dart';

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'assal_repository.dart';

class ProductionRepository implements AssalRepository {
  ProductionRepository({
    required ProductionQueryGateway gateway,
    AssalAuthGateway? authGateway,
  })  : _gateway = gateway,
        _authGateway = authGateway;
  final ProductionQueryGateway _gateway;
  final AssalAuthGateway? _authGateway;
  AssalSession? _cachedSession;
  String? _cachedIdentityId;
  Future<AssalSession>? _sessionHydration;
  DateTime? _lastActivityPingAt;

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
      developer.log(
          'write_ok resource=$resource elapsed_ms=${DateTime.now().difference(started).inMilliseconds}',
          name: 'assalkom.production');
      return AssalData(value);
    } on TimeoutException catch (error, stackTrace) {
      developer.log('write_timeout resource=$resource',
          name: 'assalkom.production', error: error, stackTrace: stackTrace);
      return const AssalError('تأخر الاتصال بالخدمة. حاول مرة أخرى.',
          code: 'timeout');
    } on Object catch (error, stackTrace) {
      final raw = error.toString();
      final isSchema = raw.contains('PGRST205') ||
          raw.contains('PGRST204') ||
          raw.contains('column') ||
          raw.contains('relation');
      final isAuth = raw.contains('42501') ||
          raw.contains('permission') ||
          raw.contains('JWT') ||
          raw.contains('row-level security');
      final code = isSchema
          ? 'schema_mismatch'
          : (isAuth ? 'permission_denied' : 'data_write_failed');
      final message = isSchema
          ? 'تعذر حفظ البيانات بسبب عدم توافق إعدادات الخدمة.'
          : (isAuth
              ? 'لا تملك صلاحية تنفيذ هذا الإجراء.'
              : 'تعذر حفظ البيانات الآن. حاول مرة أخرى.');
      developer.log('write_failed resource=$resource code=$code',
          name: 'assalkom.production', error: error, stackTrace: stackTrace);
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
      final isSchema = raw.contains('PGRST205') ||
          raw.contains('PGRST204') ||
          raw.contains('column') ||
          raw.contains('relation');
      final isNetwork = raw.contains('SocketException') ||
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
    final identity = await auth.currentIdentity();
    if (identity == null) {
      _clearSessionCache();
      return AssalSession.guest;
    }
    if (_cachedIdentityId == identity.id && _cachedSession != null) {
      return _cachedSession!;
    }
    final inFlight = _sessionHydration;
    if (inFlight != null && _cachedIdentityId == identity.id) {
      return inFlight;
    }
    final hydration = _sessionForIdentity(identity);
    _sessionHydration = hydration;
    _cachedIdentityId = identity.id;
    try {
      final session = await hydration;
      _cachedSession = session;
      return session;
    } on Object {
      _clearSessionCache();
      return AssalSession.guest;
    } finally {
      if (identical(_sessionHydration, hydration)) _sessionHydration = null;
    }
  }

  void _clearSessionCache() {
    _cachedSession = null;
    _cachedIdentityId = null;
    _sessionHydration = null;
  }

  void _cacheSession(AssalSession session) {
    _cachedSession = session;
    _cachedIdentityId = session.user?.id;
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
      'cover_url': profile['cover_url'],
      'bio': profile['bio'],
      'phone': profile['phone'],
      'location_label': profile['location_label'],
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
    final hydrated = await Future.wait<List<Map<String, Object?>>>([
      _gateway
          .select('profiles', filters: {'user_id': identity.id})
          .then((rows) => rows, onError: (_) => <Map<String, Object?>>[]),
      _gateway
          .select('admin_users', filters: {'user_id': identity.id})
          .then((rows) => rows, onError: (_) => <Map<String, Object?>>[]),
    ]);
    final profile = hydrated[0].isEmpty
        ? const <String, Object?>{}
        : hydrated[0].first;
    final isAdmin = hydrated[1].isNotEmpty;
    final now = DateTime.now().toUtc();
    final shouldPing = _lastActivityPingAt == null ||
        now.difference(_lastActivityPingAt!).inMinutes >= 5;
    if (shouldPing) {
      _lastActivityPingAt = now;
      unawaited(_recordActivity(identity.id, now));
    }
    return _sessionFromIdentity(identity, profile: profile, isAdmin: isAdmin);
  }

  Future<void> _recordActivity(String userId, DateTime now) async {
    try {
      await _gateway.update(
        'users',
        {'last_seen_at': now.toIso8601String()},
        id: userId,
      );
    } on Object {
      // Activity telemetry must never invalidate an otherwise valid session.
    }
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
      final session = await _sessionForIdentity(identity);
      _cacheSession(session);
      return AssalData(session);
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
          final values = rows
              .map(AssalBannerSummary.fromJson)
              .toList(growable: false)
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
  }) =>
      _readList(
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
  ) =>
      _readList(
        resource: 'customer_favorite_products',
        emptyMessage: 'لا توجد منتجات محفوظة',
        read: () async {
          final rows = await _gateway.select(
            'customer_favorite_products',
            filters: {'user_id': userId},
          );
          return rows.map(AssalProductSummary.fromJson).toList(growable: false);
        },
      );

  @override
  Future<AssalLoadState<List<AssalTaxonomy>>> listFavoriteTaxonomies(
    String userId,
  ) async {
    final products = await _gateway.select(
      'customer_favorite_products',
      filters: {'user_id': userId},
    );
    final taxonomyIds = products
        .map((row) => row['subcategory_id'] ?? row['category_id'])
        .whereType<String>()
        .toSet();
    if (taxonomyIds.isEmpty) {
      return const AssalEmpty('لا توجد تصنيفات مرتبطة بالمحفوظات بعد.');
    }
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
  ) =>
      _readList(
        resource: 'customer_followed_stores',
        emptyMessage: 'لا توجد متاجر متابَعة',
        read: () async {
          final rows = await _gateway.select(
            'customer_followed_stores',
            filters: {'user_id': userId},
          );
          return rows.map(AssalStoreSummary.fromJson).toList(growable: false);
        },
      );

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
  }) =>
      _readList(
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
              if (query.availability != null)
                'availability': query.availability,
              if (query.processingMethod != null)
                'processing_method_ar': query.processingMethod,
              if (query.processingStatus != null)
                'processing_status_ar': query.processingStatus,
              if (query.packaging != null)
                'packaging_label_ar': query.packaging,
            },
          );
          var values =
              rows.map(AssalProductSummary.fromJson).toList(growable: false);
          if (query.featuredOnly)
            values =
                values.where((item) => item.isFeatured).toList(growable: false);
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
                .where(
                    (item) => item.certifications.contains(query.certificateId))
                .toList(growable: false);
          if (query.minRating != null)
            values = values
                .where((item) => item.ratingAverage >= query.minRating!)
                .toList(growable: false);
          if (query.minPrice != null)
            values = values
                .where(
                  (item) =>
                      item.price != null && item.price! >= query.minPrice!,
                )
                .toList(growable: false);
          if (query.maxPrice != null)
            values = values
                .where(
                  (item) =>
                      item.price != null && item.price! <= query.maxPrice!,
                )
                .toList(growable: false);
          if (query.verifiedStoresOnly) {
            final stores = await _gateway.select(
              'customer_stores',
              filters: const {'status': 'active', 'is_verified': true},
            );
            final ids =
                stores.map((row) => row['id']).whereType<String>().toSet();
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
              values = [...values]..sort(
                  (a, b) =>
                      (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0),
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
  ) =>
      _readList(
        resource: 'customer_comments',
        emptyMessage: 'لا توجد تعليقات بعد',
        read: () async {
          final rows = await _gateway.select(
            'customer_comments',
            filters: {'target_id': targetId},
          );
          return rows
              .map(AssalCommentSummary.fromJson)
              .toList(growable: false);
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
  Future<AssalLoadState<List<AssalRequestSummary>>> listMerchantRequests(
    String merchantId,
  ) async {
    final stores = await _gateway.select(
      'stores',
      filters: {'merchant_id': merchantId},
    );
    final storeIds = stores
        .map((row) => row['id'])
        .whereType<String>()
        .toList(growable: false);
    if (storeIds.isEmpty) {
      return const AssalData(<AssalRequestSummary>[]);
    }
    final rows = <Map<String, Object?>>[];
    for (final storeId in storeIds) {
      rows.addAll(
          await _gateway.select('requests', filters: {'store_id': storeId}));
    }
    return _state(
      rows.map(AssalRequestSummary.fromJson).toList(growable: false),
      'لا توجد طلبات لهذا المتجر',
    );
  }

  @override
  Future<AssalLoadState<AssalRequestSummary>> createRequest(
    String requesterId,
    AssalRequestDraft draft,
  ) =>
      _write(
        resource: 'requests.create_atomic',
        write: () async {
          final row = await _gateway.rpc('customer_create_request', {
            'p_store_id': draft.storeId,
            'p_subject': draft.subject.trim(),
            'p_body': draft.body.trim().isEmpty ? null : draft.body.trim(),
            'p_preferred_handoff_option': draft.handoffOption.name,
            'p_phone': draft.phone,
            'p_contact_channel': draft.contactChannel,
            'p_delivery_note': draft.deliveryNote,
            'p_price_note': draft.priceNote,
            'p_handoff_details': draft.handoffDetails,
            'p_product_id': draft.productId,
            'p_quantity': draft.quantity ?? 1,
          });
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
  ) =>
      _write(
        resource: 'notifications.read',
        write: () async {
          final rows = await _gateway.select('notifications',
              filters: {'id': notificationId, 'user_id': userId});
          if (rows.isEmpty) throw StateError('notification_not_owned');
          await _gateway.update(
              'notifications', {'read_at': DateTime.now().toIso8601String()},
              id: notificationId);
          return true;
        },
      );

  @override
  Future<AssalLoadState<List<AssalConversationSummary>>> listConversations(
    String userId,
  ) =>
      _readList(
        resource: 'customer_conversations',
        emptyMessage: 'لا توجد محادثات بعد',
        read: () async {
          final rows = await _gateway.select(
            'customer_conversations',
            filters: {'user_id': userId},
          );
          final values = rows
              .map(AssalConversationSummary.fromJson)
              .toList(growable: false);
          values.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return values;
        },
      );

  @override
  Future<AssalLoadState<AssalConversationSummary>> createConversation(
    String userId,
    String storeId,
  ) =>
      _write(
        resource: 'conversations.create_atomic',
        write: () async {
          final row = await _gateway.rpc('customer_create_conversation', {
            'p_store_id': storeId,
          });
          return AssalConversationSummary.fromJson(row);
        },
      );

  @override
  Future<AssalLoadState<List<AssalMessageSummary>>> listMessages(
    String conversationId,
  ) =>
      _readList(
        resource: 'messages',
        emptyMessage: 'لا توجد رسائل بعد',
        read: () async {
          final identity = await _authGateway?.currentIdentity();
          final rows = await _gateway
              .select('messages', filters: {'conversation_id': conversationId});
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
  ) =>
      _write(
        resource: 'messages.create_atomic',
        write: () async {
          final row = await _gateway.rpc('customer_send_message', {
            'p_conversation_id': draft.conversationId,
            'p_body': draft.body.trim(),
          });
          return AssalMessageSummary.fromJson(row);
        },
      );
  @override
  Future<AssalLoadState<AssalReviewSummary>> createReview(
    String authorId,
    AssalReviewDraft draft,
  ) =>
      _write(
        resource: 'reviews.create_atomic',
        write: () async {
          final row = await _gateway.rpc('customer_create_review', {
            'p_product_id': draft.productId,
            'p_store_id': draft.storeId,
            'p_rating': draft.rating,
            'p_body': draft.body.trim(),
          });
          return AssalReviewSummary.fromJson(row);
        },
      );

  @override
  Future<AssalLoadState<AssalCommentSummary>> createComment(
    String authorId,
    String authorName,
    String targetId,
    String body,
  ) =>
      _write(
        resource: 'comments.create_atomic',
        write: () async {
          final row = await _gateway.rpc('customer_create_comment', {
            'p_target_id': targetId,
            'p_body': body.trim(),
          });
          return AssalCommentSummary.fromJson(row);
        },
      );

  @override
  Future<AssalLoadState<bool>> toggleFollow(
    String userId,
    String storeId,
  ) =>
      _write(
        resource: 'store_followers.toggle_atomic',
        write: () async {
          final value = await _gateway.rpc('customer_toggle_store_follow', {
            'p_store_id': storeId,
          });
          return value['following'] == true;
        },
      );

  @override
  Future<AssalLoadState<bool>> toggleFavorite(
    String userId,
    String targetId,
  ) =>
      _write(
        resource: 'favorites.toggle_atomic',
        write: () async {
          final value = await _gateway.rpc('customer_toggle_favorite', {
            'p_product_id': targetId,
          });
          return value['saved'] == true;
        },
      );

  @override
  Future<AssalLoadState<bool>> toggleLike(
    String userId,
    String targetId,
  ) =>
      _write(
        resource: 'product_likes.toggle_atomic',
        write: () async {
          final value = await _gateway.rpc('customer_toggle_product_like', {
            'p_product_id': targetId,
          });
          return value['liked'] == true;
        },
      );

  @override
  Future<AssalLoadState<void>> trackProductView(String productId) => _write(
        resource: 'product_view_events.create',
        write: () async {
          final identity = await _authGateway?.currentIdentity();
          await _gateway.insert('product_view_events',
              {'product_id': productId, 'viewer_id': identity?.id});
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
      final session = await _sessionForIdentity(identity);
      _cacheSession(session);
      return AssalData(session);
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
      final session = await _sessionForIdentity(identity);
      _cacheSession(session);
      return AssalData(session);
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
  ) =>
      _authOperation(
        (auth) => auth.signUp(name: name, email: email, password: password),
      );
  AssalMerchantApplicationSummary _merchantApplicationFromRow(
          Map<String, Object?> row) =>
      AssalMerchantApplicationSummary(
        id: '${row['id'] ?? ''}',
        userId: '${row['user_id'] ?? ''}',
        status: '${row['status'] ?? 'submitted'}',
        displayName: '${row['display_name'] ?? ''}',
        submittedAt:
            DateTime.tryParse('${row['submitted_at'] ?? ''}') ?? DateTime.now(),
        reviewNote: row['review_note'] as String?,
        storeId: row['store_id'] is String ? row['store_id'] as String : null,
        storeStatus: row['store_status'] as String?,
        storeVerified: row['store_verified'] == true,
        storeLogoUrl: row['store_logo_url'] as String?,
        storeCoverUrl: row['store_cover_url'] as String?,
      );

  @override
  Future<AssalLoadState<AssalMerchantApplicationSummary>>
      submitMerchantApplication(
    String userId,
    AssalMerchantApplicationDraft draft,
  ) =>
          _write(
            resource: 'merchant_applications.submit',
            write: () async {
              if (draft.displayName.trim().length < 2 ||
                  draft.phone.trim().length < 6 ||
                  draft.experience.trim().length < 4 ||
                  draft.location.trim().length < 2 ||
                  draft.specialties.trim().length < 2)
                throw StateError('invalid_merchant_application');
              final row = await _gateway.upsert('merchant_applications', {
                'user_id': userId,
                'display_name': draft.displayName.trim(),
                'phone': draft.phone.trim(),
                'experience': draft.experience.trim(),
                'location': draft.location.trim(),
                'specialties': draft.specialties.trim(),
                'certificate_note': draft.certificateNote?.trim(),
                'store_description': draft.storeDescription?.trim(),
                'region_id': draft.regionId,
                'logo_url': draft.logoUrl,
                'cover_url': draft.coverUrl,
                'status': 'submitted',
                'submitted_at': DateTime.now().toIso8601String(),
              });
              await _gateway.delete('merchant_application_drafts',
                  filters: {'user_id': userId});
              return _merchantApplicationFromRow(row);
            },
          );

  @override
  Future<AssalLoadState<AssalMerchantApplicationSummary?>>
      loadMerchantApplication(String userId) => _write(
            resource: 'merchant_applications.read',
            write: () async {
              final rows = await _gateway.select('merchant_applications',
                  filters: {'user_id': userId});
              if (rows.isEmpty) return null;
              final value = Map<String, Object?>.from(rows.first);
              final stores = await _gateway
                  .select('stores', filters: {'merchant_id': userId});
              if (stores.isNotEmpty) {
                final store = stores.first;
                value['store_id'] = store['id'];
                value['store_status'] = store['status'];
                value['store_verified'] = store['is_verified'];
                value['store_logo_url'] = store['logo_url'];
                value['store_cover_url'] = store['cover_url'];
              }
              return _merchantApplicationFromRow(value);
            },
          );

  @override
  Future<AssalLoadState<AssalMerchantApplicationDraft?>>
      loadMerchantApplicationDraft(String userId) => _write(
            resource: 'merchant_application_drafts.read',
            write: () async {
              final rows = await _gateway.select('merchant_application_drafts',
                  filters: {'user_id': userId});
              if (rows.isEmpty) return null;
              final row = rows.first;
              return AssalMerchantApplicationDraft(
                displayName: '${row['display_name'] ?? ''}',
                phone: '${row['phone'] ?? ''}',
                experience: '${row['experience'] ?? ''}',
                location: '${row['location'] ?? ''}',
                specialties: '${row['specialties'] ?? ''}',
                certificateNote: row['certificate_note'] as String?,
                storeDescription: row['store_description'] as String?,
                regionId: row['region_id'] as String?,
                logoUrl: row['logo_url'] as String?,
                coverUrl: row['cover_url'] as String?,
              );
            },
          );

  @override
  Future<AssalLoadState<void>> saveMerchantApplicationDraft(
    String userId,
    AssalMerchantApplicationDraft draft,
  ) =>
      _write(
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
            'store_description': draft.storeDescription,
            'region_id': draft.regionId,
            'logo_url': draft.logoUrl,
            'cover_url': draft.coverUrl,
            'updated_at': DateTime.now().toIso8601String(),
          });
        },
      );

  @override
  Future<AssalLoadState<void>> clearMerchantApplicationDraft(
    String userId,
  ) =>
      _write(
        resource: 'merchant_application_drafts.delete',
        write: () => _gateway.delete('merchant_application_drafts',
            filters: {'user_id': userId}),
      );

  @override
  Future<AssalLoadState<AssalMerchantWorkspaceSummary?>> loadMerchantWorkspace(
    String userId,
  ) =>
      _write(
        resource: 'merchant_workspace.read',
        write: () async {
          final stores =
              await _gateway.select('stores', filters: {'merchant_id': userId});
          if (stores.isEmpty) return null;
          final store = AssalStoreSummary.fromJson(stores.first);
          final status = '${stores.first['status'] ?? 'pending'}';
          final badges = await _gateway.select(
            'store_badges',
            filters: {'store_id': store.id},
          );
          final proVerified = badges.any((row) =>
              row['status'] == 'active' &&
              (row['expires_at'] == null ||
                  DateTime.tryParse('${row['expires_at']}')?.isAfter(DateTime.now().toUtc()) == true));
          final verificationRequests = await _gateway.select(
            'store_verification_requests',
            filters: {'store_id': store.id},
          );
          final subscriptions = await _gateway.select(
            'merchant_subscriptions',
            filters: {'merchant_id': userId, 'status': 'active'},
          );
          Map<String, Object?>? activeSubscription;
          for (final candidate in subscriptions) {
            final endsAt = DateTime.tryParse('${candidate['ends_at'] ?? ''}');
            if (endsAt == null || endsAt.isAfter(DateTime.now().toUtc())) {
              activeSubscription = candidate;
              break;
            }
          }
          Map<String, Object?>? plan;
          if (activeSubscription != null) {
            final plans = await _gateway.select(
              'subscription_plans',
              filters: {'id': activeSubscription['plan_id']},
            );
            if (plans.isNotEmpty) plan = plans.first;
          }
          final designRequests = activeSubscription == null
              ? const <Map<String, Object?>>[]
              : await _gateway.select('design_requests', filters: {
                  'subscription_id': activeSubscription['id'],
                });
          verificationRequests.sort((left, right) =>
              '${right['created_at'] ?? ''}'.compareTo('${left['created_at'] ?? ''}'));
          final latestVerification = verificationRequests.isEmpty
              ? null
              : verificationRequests.first;
          final verificationStatus = proVerified
              ? 'approved'
              : '${latestVerification?['status'] ?? 'not_requested'}';
          return AssalMerchantWorkspaceSummary(
            store: store,
            verificationStatus: verificationStatus,
            publicStatus: status,
            canEdit: true,
            canPublish: status == 'active',
            planCode: plan == null ? null : '${plan['code'] ?? ''}',
            planStatus: activeSubscription == null ? null : 'active',
            storeLimit: plan == null ? 1 : (plan['store_limit'] as num?)?.toInt() ?? 1,
            productLimit: plan == null ? 25 : (plan['product_limit'] as num?)?.toInt() ?? 25,
            designRequestsRemaining: plan == null
                ? 0
                : ((plan['entitlements'] is Map)
                        ? (((plan['entitlements'] as Map)['design_requests_per_cycle'] as num?)?.toInt() ?? 0)
                        : 0) - designRequests.where((row) => row['status'] != 'cancelled').length,
          );
        },
      );

  @override
  Future<AssalLoadState<AssalMerchantWorkspaceSummary>> openMerchantWorkspace(
    String userId,
    AssalMerchantWorkspaceDraft draft,
  ) =>
      _write(
        resource: 'merchant_workspace.open',
        write: () async {
          final row = await _gateway.rpc('merchant_open_workspace', {
            'p_business_name': draft.businessName.trim(),
            'p_description': draft.description?.trim(),
            'p_region_id': draft.regionId,
            'p_phone': draft.phone?.trim(),
            'p_logo_url': draft.logoUrl,
            'p_cover_url': draft.coverUrl,
          });
          return AssalMerchantWorkspaceSummary.fromJson(row);
        },
      );

  @override
  Future<AssalLoadState<void>> updateMerchantWorkspace(
    String userId,
    String storeId,
    AssalMerchantWorkspaceDraft draft,
  ) =>
      _write(
        resource: 'merchant_workspace.update',
        write: () async {
          final ownedStores = await _gateway.select(
            'stores',
            filters: {'id': storeId, 'merchant_id': userId},
          );
          if (ownedStores.isEmpty)
            throw StateError('merchant_workspace_not_owned');
          await _gateway.update(
            'stores',
            {
              'name_ar': draft.businessName.trim(),
              'description': draft.description?.trim(),
              'phone': draft.phone?.trim(),
              'logo_url': draft.logoUrl,
              'cover_url': draft.coverUrl,
              'region_id': draft.regionId,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
            id: storeId,
          );
        },
      );

  Future<List<String>> _merchantStoreIds(String userId) async {
    final stores =
        await _gateway.select('stores', filters: {'merchant_id': userId});
    return stores
        .map((row) => row['id'])
        .whereType<String>()
        .toList(growable: false);
  }

  Future<AssalProductSummary> _productSummaryFromRow(
    Map<String, Object?> row,
  ) async {
    final value = Map<String, Object?>.from(row);
    final rawMetadata = row['metadata'];
    if (rawMetadata is Map) {
      value.addAll(Map<String, Object?>.from(rawMetadata));
    }
    final images = await _gateway
        .select('product_images', filters: {'product_id': row['id']});
    final imageUrls = images
        .map((image) => image['image_url'])
        .whereType<String>()
        .toList(growable: false);
    value['image_urls'] = imageUrls;
    value['primary_image_url'] = imageUrls.isEmpty ? null : imageUrls.first;
    value['status'] = row['status'] ?? 'draft';
    value['product_type'] = row['product_type'] ?? 'honey';
    return AssalProductSummary.fromJson(value);
  }

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listMerchantProducts(
    String userId,
  ) =>
      _readList(
        resource: 'merchant_products.read',
        emptyMessage: 'لا توجد منتجات في مساحة التاجر بعد.',
        read: () async {
          final storeIds = await _merchantStoreIds(userId);
          final rows = <Map<String, Object?>>[];
          for (final storeId in storeIds) {
            rows.addAll(await _gateway
                .select('products', filters: {'store_id': storeId}));
          }
          return Future.wait(rows.map(_productSummaryFromRow));
        },
      );

  @override
  Future<AssalLoadState<AssalProductSummary>> createMerchantProduct(
    String userId,
    String storeId,
    AssalProductDraft draft,
  ) =>
      _write(
        resource: 'merchant_products.create',
        write: () async {
          if (draft.nameAr.trim().length < 2)
            throw StateError('invalid_product_name');
          final ownedStores = await _gateway.select(
            'stores',
            filters: {'id': storeId, 'merchant_id': userId},
          );
          if (ownedStores.isEmpty) throw StateError('merchant_store_not_owned');
          final row = await _gateway.insert('products', {
            'store_id': storeId,
            'taxonomy_id': draft.taxonomyId,
            'name_ar': draft.nameAr.trim(),
            'name_en': draft.nameEn?.trim(),
            'description': draft.description?.trim(),
            'product_type': draft.productType.name,
            'grade_level': draft.gradeLevel,
            'status': 'pending',
            'metadata': draft.metadata,
          });
          for (var index = 0; index < draft.imageUrls.length; index++) {
            await _gateway.insert('product_images', {
              'product_id': row['id'],
              'image_url': draft.imageUrls[index],
              'sort_order': index,
            });
          }
          return _productSummaryFromRow(row);
        },
      );

  @override
  Future<AssalLoadState<AssalProductSummary>> updateMerchantProduct(
    String userId,
    String productId,
    AssalProductDraft draft,
  ) =>
      _write(
        resource: 'merchant_products.update',
        write: () async {
          final rows =
              await _gateway.select('products', filters: {'id': productId});
          if (rows.isEmpty) throw StateError('product_not_found');
          final current = rows.first;
          final storeId = current['store_id'];
          if (storeId is! String) throw StateError('product_store_missing');
          final ownedStores = await _gateway.select(
            'stores',
            filters: {'id': storeId, 'merchant_id': userId},
          );
          if (ownedStores.isEmpty) throw StateError('merchant_store_not_owned');
          final patch = <String, Object?>{
            'name_ar': draft.nameAr.trim(),
            'name_en': draft.nameEn?.trim(),
            'description': draft.description?.trim(),
            'taxonomy_id': draft.taxonomyId,
            'product_type': draft.productType.name,
            'grade_level': draft.gradeLevel,
            'metadata': draft.metadata,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          };
          if (current['status'] == 'active') {
            await _gateway.insert('product_revisions', {
              'product_id': productId,
              'store_id': storeId,
              'editor_user_id': userId,
              'base_updated_at': current['updated_at'],
              'status': 'pending_review',
              'payload': patch,
            });
            return _productSummaryFromRow(current);
          }
          final updated =
              await _gateway.update('products', patch, id: productId);
          return _productSummaryFromRow(updated);
        },
      );

  @override
  Future<AssalLoadState<void>> deleteMerchantProduct(
    String userId,
    String productId,
  ) =>
      _write(
        resource: 'merchant_products.delete',
        write: () async {
          final rows = await _gateway.select(
            'products',
            filters: {'id': productId},
          );
          if (rows.isEmpty) throw StateError('product_not_found');
          final storeId = rows.first['store_id'];
          if (storeId is! String) throw StateError('product_store_missing');
          final stores = await _gateway.select(
            'stores',
            filters: {'id': storeId, 'merchant_id': userId},
          );
          if (stores.isEmpty) throw StateError('merchant_store_not_owned');
          await _gateway.delete('products', filters: {'id': productId});
        },
      );

  @override
  Future<AssalLoadState<void>> updateUserProfile(
    String userId,
    AssalUserProfilePatch patch,
  ) async {
    final auth = _authGateway;
    if (auth == null) {
      return const AssalError(
        'المصادقة الإنتاجية غير مهيأة بعد.',
        code: 'production_auth_not_configured',
      );
    }
    final identity = await auth.currentIdentity();
    if (identity == null || identity.id != userId) {
      return const AssalError(
        'يمكنك تعديل ملفك الشخصي فقط بعد تسجيل الدخول بالحساب نفسه.',
        code: 'profile_not_owned',
      );
    }
    return _write(
      resource: 'profiles.update',
      write: () async {
        await _gateway.upsert(
          'profiles',
          {
            'user_id': userId,
            if (patch.nameAr != null) 'display_name': patch.nameAr!.trim(),
            if (patch.bio != null) 'bio': patch.bio?.trim(),
            if (patch.phone != null) 'phone': patch.phone?.trim(),
            if (patch.locationLabel != null)
              'location_label': patch.locationLabel?.trim(),
            if (patch.avatarUrl != null) 'avatar_url': patch.avatarUrl,
            if (patch.coverUrl != null) 'cover_url': patch.coverUrl,
            if (patch.latitude != null) 'latitude': patch.latitude,
            if (patch.longitude != null) 'longitude': patch.longitude,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          onConflict: 'user_id',
        );
      },
    );
  }

  @override
  Future<AssalLoadState<String>> uploadMerchantImage(
    String userId,
    String kind,
    Uint8List bytes,
    String extension,
  ) {
    final safeKind = kind == 'cover' ? 'cover' : 'logo';
    final safeExtension = switch (extension.toLowerCase()) {
      'png' => 'png',
      'webp' => 'webp',
      _ => 'jpg',
    };
    return _write(
      resource: 'merchant_image.upload',
      write: () async {
        final path =
            '$userId/merchant/$safeKind-${DateTime.now().toUtc().millisecondsSinceEpoch}.$safeExtension';
        return _gateway.uploadPublicImage(path, bytes, safeExtension);
      },
    );
  }

  @override
  Future<AssalLoadState<String>> uploadStoreGalleryImage(
    String userId,
    String storeId,
    Uint8List bytes,
    String extension,
  ) =>
      _write(
        resource: 'store_gallery_image.upload',
        write: () async {
          final stores = await _gateway.select(
            'stores',
            filters: {'id': storeId, 'merchant_id': userId},
          );
          if (stores.isEmpty) throw StateError('merchant_store_not_owned');
          final safeExtension =
              extension.toLowerCase() == 'png' ? 'png' : 'jpg';

          final path =
              '$userId/store/$storeId/gallery-${DateTime.now().toUtc().millisecondsSinceEpoch}.$safeExtension';
          final url =
              await _gateway.uploadPublicImage(path, bytes, safeExtension);
          await _gateway.insert('store_gallery', {
            'store_id': storeId,
            'media_url': url,
            'sort_order': 0,
          });
          return url;
        },
      );

  @override
  Future<AssalLoadState<String>> uploadProductImage(
    String userId,
    String productId,
    Uint8List bytes,
    String extension,
  ) =>
      _write(
        resource: 'product_image.upload',
        write: () async {
          final products = await _gateway.select(
            'products',
            filters: {'id': productId},
          );
          if (products.isEmpty) throw StateError('product_not_found');
          final storeId = products.first['store_id'];
          if (storeId is! String) throw StateError('product_store_missing');
          final stores = await _gateway.select(
            'stores',
            filters: {'id': storeId, 'merchant_id': userId},
          );
          if (stores.isEmpty) throw StateError('merchant_store_not_owned');
          final safeExtension =
              extension.toLowerCase() == 'png' ? 'png' : 'jpg';
          final path =
              '$userId/product/$productId/image-${DateTime.now().toUtc().millisecondsSinceEpoch}.$safeExtension';

          final url =
              await _gateway.uploadPublicImage(path, bytes, safeExtension);
          await _gateway.insert('product_images', {
            'product_id': productId,
            'image_url': url,
            'sort_order': 0,
          });
          return url;
        },
      );

  String _verificationPaymentWire(VerificationPaymentStatus value) => switch (value) {
        VerificationPaymentStatus.notStarted => 'not_started',
        VerificationPaymentStatus.pending => 'pending',
        VerificationPaymentStatus.paid => 'paid',
        VerificationPaymentStatus.failed => 'failed',
        VerificationPaymentStatus.refunded => 'refunded',
        VerificationPaymentStatus.waived => 'waived',
      };

  String _verificationDocumentWire(VerificationDocumentType value) => switch (value) {
        VerificationDocumentType.identity => 'identity',
        VerificationDocumentType.businessRegistration => 'business_registration',
        VerificationDocumentType.taxOrLicense => 'tax_or_license',
        VerificationDocumentType.originCertificate => 'origin_certificate',
        VerificationDocumentType.qualityCertificate => 'quality_certificate',
        VerificationDocumentType.addressProof => 'address_proof',
        VerificationDocumentType.other => 'other',
      };

  Future<AssalStoreVerificationSummary> _verificationSummary(
    Map<String, Object?> row,
  ) async {
    final value = Map<String, Object?>.from(row);
    final documents = await _gateway.select(
      'store_verification_documents',
      filters: {'request_id': row['id']},
    );
    value['document_count'] = documents.length;
    value['document_types'] = documents
        .map((row) => row['document_type'])
        .whereType<String>()
        .toList(growable: false);
    return AssalStoreVerificationSummary.fromJson(value);
  }

  @override
  Future<AssalLoadState<AssalStoreVerificationSummary?>> loadStoreVerification(
    String userId,
    String storeId,
  ) =>
      _write(
        resource: 'store_verification.read',
        write: () async {
          final rows = await _gateway.select(
            'store_verification_requests',
            filters: {'merchant_id': userId, 'store_id': storeId},
          );
          if (rows.isEmpty) return null;
          final sorted = [...rows]
            ..sort((a, b) => '${b['created_at']}'.compareTo('${a['created_at']}'));
          return _verificationSummary(sorted.first);
        },
      );

  @override
  Future<AssalLoadState<AssalStoreVerificationSummary>>
      createStoreVerificationRequest(
    String userId,
    AssalStoreVerificationDraft draft,
  ) =>
          _write(
            resource: 'store_verification.create',
            write: () async {
              final stores = await _gateway.select(
                'stores',
                filters: {'id': draft.storeId, 'merchant_id': userId},
              );
              if (stores.isEmpty) throw StateError('merchant_store_not_owned');
              final existing = await _gateway.select(
                'store_verification_requests',
                filters: {'store_id': draft.storeId, 'merchant_id': userId},
              );
              final open = existing.where((row) {
                const openStatuses = {
                  'draft',
                  'payment_pending',
                  'submitted',
                  'under_review',
                  'needs_more_info',
                  'approved',
                };
                return openStatuses.contains(row['status']);
              }).toList(growable: false);
              if (open.isNotEmpty) return _verificationSummary(open.first);
              final row = await _gateway.insert('store_verification_requests', {
                'store_id': draft.storeId,
                'merchant_id': userId,
                'plan_code': draft.planCode,
                'status': 'draft',
                'payment_status': _verificationPaymentWire(draft.paymentStatus),
              });
              return _verificationSummary(row);
            },
          );

  @override
  Future<AssalLoadState<AssalStoreVerificationSummary>>
      submitStoreVerification(String userId, String requestId) =>
          _write(
            resource: 'store_verification.submit',
            write: () async {
              final rows = await _gateway.select(
                'store_verification_requests',
                filters: {'id': requestId, 'merchant_id': userId},
              );
              if (rows.isEmpty) throw StateError('verification_request_not_found');
              final current = rows.first;
              final paymentStatus = '${current['payment_status'] ?? 'not_started'}';
              if (paymentStatus != 'paid' && paymentStatus != 'waived') {
                throw StateError('verification_payment_required');
              }
              final updated = await _gateway.update(
                'store_verification_requests',
                {
                  'status': 'submitted',
                  'submitted_at': DateTime.now().toUtc().toIso8601String(),
                  'updated_at': DateTime.now().toUtc().toIso8601String(),
                },
                id: requestId,
              );
              await _gateway.insert('store_verification_events', {
                'request_id': requestId,
                'actor_user_id': userId,
                'from_status': current['status'],
                'to_status': 'submitted',
                'note': 'تم إرسال طلب توثيق Pro للمراجعة.',
              });
              return _verificationSummary(updated);
            },
          );

  @override
  Future<AssalLoadState<AssalStoreVerificationSummary>>
      submitVerificationPaymentReference(
    String userId,
    String requestId,
    String paymentReference,
  ) =>
          _write(
            resource: 'store_verification.payment_reference',
            write: () async {
              final row = await _gateway.rpc(
                'merchant_submit_verification_payment_reference',
                {
                  'p_request_id': requestId,
                  'p_payment_reference': paymentReference.trim(),
                },
              );
              return _verificationSummary(row);
            },
          );

  @override
  Future<AssalLoadState<String>> uploadVerificationDocument(
    String userId,
    String requestId,
    Uint8List bytes,
    String extension,
  ) =>
      _write(
        resource: 'store_verification_document.upload',
        write: () async {
          final requests = await _gateway.select(
            'store_verification_requests',
            filters: {'id': requestId, 'merchant_id': userId},
          );
          if (requests.isEmpty) throw StateError('verification_request_not_found');
          final safeExtension = switch (extension.toLowerCase()) {
            'png' => 'png',
            'webp' => 'webp',
            'pdf' => 'pdf',
            _ => 'jpg',
          };
          final path =
              '$userId/verification/$requestId/document-${DateTime.now().toUtc().millisecondsSinceEpoch}.$safeExtension';
          return _gateway.uploadPrivateImage(path, bytes, safeExtension);
        },
      );

  @override
  Future<AssalLoadState<AssalStoreVerificationSummary>>
      addVerificationDocument(
    String userId,
    String requestId,
    AssalVerificationDocumentDraft draft,
  ) =>
          _write(
            resource: 'store_verification_document.create',
            write: () async {
              final requests = await _gateway.select(
                'store_verification_requests',
                filters: {'id': requestId, 'merchant_id': userId},
              );
              if (requests.isEmpty) throw StateError('verification_request_not_found');
              await _gateway.insert('store_verification_documents', {
                'request_id': requestId,
                'store_id': requests.first['store_id'],
                'merchant_id': userId,
                'document_type': _verificationDocumentWire(draft.documentType),
                'file_path': draft.filePath,
                'file_name': draft.fileName,
                'mime_type': draft.mimeType,
                'byte_size': draft.byteSize,
              });
              return _verificationSummary(requests.first);
            },
          );

  @override
  Future<AssalLoadState<List<AssalSubscriptionPlan>>> listSubscriptionPlans() =>
      _readList(
        resource: 'subscription_plans.read',
        emptyMessage: 'لا توجد خطط متاحة حاليًا.',
        read: () async {
          final rows = await _gateway.select('subscription_plans', filters: {'is_active': true});
          return rows.map(AssalSubscriptionPlan.fromJson).toList(growable: false);
        },
      );

  @override
  Future<AssalLoadState<AssalSubscriptionCampaign?>> loadSubscriptionCampaign() =>
      _write(
        resource: 'subscription_campaign.read',
        write: () async {
          final rows = await _gateway.select('subscription_campaigns', filters: {'is_active': true});
          if (rows.isEmpty) return null;
          return AssalSubscriptionCampaign.fromJson(rows.first);
        },
      );

  @override
  Future<AssalLoadState<AssalLocalTransferSettings?>> loadLocalTransferSettings() =>
      _write(
        resource: 'local_transfer_settings.read',
        write: () async {
          final rows = await _gateway.select('local_transfer_settings', filters: {'code': 'primary', 'is_active': true});
          if (rows.isEmpty) return null;
          return AssalLocalTransferSettings.fromJson(rows.first);
        },
      );

  @override
  Future<AssalLoadState<AssalPaymentRequest>> createSubscriptionPaymentRequest(
    String userId,
    String planId,
  ) =>
      _write(
        resource: 'subscription_payment.create',
        write: () async {
          final row = await _gateway.rpc('merchant_create_subscription_payment_request', {'p_plan_id': planId});
          return AssalPaymentRequest.fromJson(row);
        },
      );

  @override
  Future<AssalLoadState<String>> uploadPaymentProof(
    String userId,
    String paymentRequestId,
    Uint8List bytes,
    String extension,
  ) =>
      _write(
        resource: 'payment_proof.upload',
        write: () => _gateway.uploadPrivateImage(
          '$userId/payment-proofs/$paymentRequestId-${DateTime.now().toUtc().millisecondsSinceEpoch}.$extension',
          bytes,
          extension,
        ),
      );

  @override
  Future<AssalLoadState<AssalPaymentRequest>> submitPaymentProof(
    String userId,
    String paymentRequestId,
    String paymentReference,
    String proofPath,
    String proofFileName,
    String proofMimeType,
    int proofByteSize,
    DateTime transferDate,
    double submittedAmount,
    String senderName,
    String senderPhone,
  ) =>
      _write(
        resource: 'payment_proof.submit',
        write: () async {
          final row = await _gateway.rpc('merchant_submit_payment_proof', {
            'p_payment_request_id': paymentRequestId,
            'p_payment_reference': paymentReference.trim(),
            'p_proof_path': proofPath,
            'p_proof_file_name': proofFileName,
            'p_proof_mime_type': proofMimeType,
            'p_proof_byte_size': proofByteSize,
            'p_transfer_date': transferDate.toUtc().toIso8601String().substring(0, 10),
            'p_submitted_amount': submittedAmount,
            'p_sender_name': senderName.trim(),
            'p_sender_phone': senderPhone.trim(),
          });
          return AssalPaymentRequest.fromJson(row);
        },
      );

  @override
  Future<AssalLoadState<AssalDesignRequest>> createDesignRequest(
    String userId,
    String storeId,
    AssalDesignRequestDraft draft,
  ) =>
      _write(
        resource: 'design_request.create',
        write: () async {
          final row = await _gateway.rpc('merchant_create_design_request', {
            'p_store_id': storeId,
            'p_title': draft.title.trim(),
            'p_description': draft.description.trim(),
            'p_brand_name': draft.brandName?.trim(),
            'p_brand_colors': draft.brandColors,
            'p_product_scope': draft.productScope,
          });
          return AssalDesignRequest.fromJson(row);
        },
      );

  @override
  Future<AssalLoadState<void>> signOut() async {
    final auth = _authGateway;
    if (auth == null) return const AssalData(null);
    try {
      await auth.signOut();
      _clearSessionCache();
      return const AssalData(null);
    } on Object {
      return const AssalError(
        'تعذر تسجيل الخروج. حاول مرة أخرى.',
        code: 'sign_out_failed',
      );
    }
  }
}
