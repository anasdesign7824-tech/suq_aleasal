import 'package:flutter_test/flutter_test.dart';

import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_data/demo_repository.dart';
import 'package:assalkom_data/production_repository.dart';
import 'package:assalkom_data/repository_factory.dart';

void main() {
  const catalog = '''
  {
    "regions": [{"id":"r1","name_ar":"حضرموت","is_active":true}],
    "stores": [{"id":"s1","merchant_id":"m1","name_ar":"متجر تجريبي","slug":"demo","status":"active","is_verified":true}],
    "products": [{"id":"p1","store_id":"s1","category_id":"c1","name_ar":"سدر دوعني","product_type":"honey","status":"active","is_featured":true,"rating_average":4.8,"review_count":2,"subcategory_id":"sub1","subcategory_name_ar":"السدر","region_id":"r1","province_id":"pvn1","origin_country":"اليمن","certifications":["cert1"],"merchant_id":"m1","processing_method_ar":"خام","processing_status_ar":"مصفى","packaging_label_ar":"زجاج 500غ","availability":"متاح","price":22000,"currency_code":"YER"}],
    "reviews": [],
    "comments": [{"id":"c1","target_id":"p1","author_id":"u1","author_name":"عميل","body":"مفيد","created_at":"2026-08-01T10:00:00Z"}],
    "requests": [],
    "notifications": [],
    "banners": [{"id":"b1","title_ar":"اكتشف","description_ar":"مصدر موثق","cta_label_ar":"ابدأ","image_url":"logo.svg","sort_order":1,"is_active":true}],
    "popular_searches": ["سدر دوعني"],
    "conversations": [{"id":"cv1","store_id":"s1","store_name":"متجر تجريبي","last_message":"مرحبًا","updated_at":"2026-08-01T10:00:00Z"}],
    "messages": [{"id":"msg1","conversation_id":"cv1","sender_id":"m1","body":"مرحبًا","sent_at":"2026-08-01T10:00:00Z"}]
  }
  ''';

  test('DemoRepository returns demo data and empty states', () async {
    final repository =
        DemoRepository(loader: const InMemoryDemoCatalogLoader(catalog));
    final products = await repository.listProducts(
        query: const AssalProductQuery(featuredOnly: true));
    expect(repository.mode, AssalDataSourceMode.demo);
    expect(products, isA<AssalData<List<AssalProductSummary>>>());
    final honeyMatrix = await repository.listProducts(
        query: const AssalProductQuery(
            regionId: 'r1',
            provinceId: 'pvn1',
            originCountry: 'اليمن',
            certificateId: 'cert1',
            processingMethod: 'خام',
            processingStatus: 'مصفى',
            packaging: 'زجاج 500غ',
            availability: 'متاح',
            merchantId: 'm1',
            minRating: 4,
            minPrice: 20000,
            maxPrice: 25000));
    expect((honeyMatrix as AssalData<List<AssalProductSummary>>).value,
        hasLength(1));
    final reviews = await repository.listReviews('p1');
    expect(reviews, isA<AssalEmpty<List<AssalReviewSummary>>>());
    await repository.signIn('demo@assalkom.app', 'demo123');
    await repository.toggleFavorite('demo-customer', 'p1');
    final favoriteTaxonomies =
        await repository.listFavoriteTaxonomies('demo-customer');
    expect((favoriteTaxonomies as AssalData<List<AssalTaxonomy>>).value,
        hasLength(1));
    final banners = await repository.listBanners();
    expect(
        (banners as AssalData<List<AssalBannerSummary>>).value, hasLength(1));
    final searches = await repository.listPopularSearches();
    expect((searches as AssalData<List<String>>).value, contains('سدر دوعني'));
    final comments = await repository.listComments('p1');
    expect(comments, isA<AssalData<List<AssalCommentSummary>>>());
    final conversations = await repository.listConversations('demo-customer');
    expect(conversations, isA<AssalData<List<AssalConversationSummary>>>());
  });

  test('DemoRepository saves, restores, and clears merchant drafts', () async {
    final repository =
        DemoRepository(loader: const InMemoryDemoCatalogLoader(catalog));
    const draft = AssalMerchantApplicationDraft(
      displayName: 'مناحل تجريبية',
      phone: '777123456',
      experience: 'خبرة في فرز العسل وتعبئته.',
      location: 'حضرموت',
      specialties: 'سدر، سمرة',
    );

    await repository.signIn('demo@assalkom.app', 'demo123');
    final saved =
        await repository.saveMerchantApplicationDraft('demo-customer', draft);
    expect(saved, isA<AssalData<void>>());
    final restored =
        await repository.loadMerchantApplicationDraft('demo-customer');
    expect(restored, isA<AssalData<AssalMerchantApplicationDraft?>>());
    expect(
      (restored as AssalData<AssalMerchantApplicationDraft?>)
          .value
          ?.displayName,
      'مناحل تجريبية',
    );

    final submitted =
        await repository.submitMerchantApplication('demo-customer', draft);
    expect(submitted, isA<AssalData<AssalMerchantApplicationSummary>>());
    final afterSubmit =
        await repository.loadMerchantApplicationDraft('demo-customer');
    expect((afterSubmit as AssalData<AssalMerchantApplicationDraft?>).value,
        isNull);
  });

  test('DemoRepository buffers product view events without production metrics',
      () async {
    final repository =
        DemoRepository(loader: const InMemoryDemoCatalogLoader(catalog));
    final first = await repository.trackProductView('p1');
    final second = await repository.trackProductView('p1');
    final invalid = await repository.trackProductView('');

    expect(first, isA<AssalData<void>>());
    expect(second, isA<AssalData<void>>());
    expect(repository.localProductViewCount('p1'), 2);
    expect(invalid, isA<AssalError<void>>());
  });

  test('DemoRepository supports passwordless email OTP', () async {
    final repository =
        DemoRepository(loader: const InMemoryDemoCatalogLoader(catalog));
    final requested = await repository.requestEmailOtp('demo@assalkom.app');
    expect(requested, isA<AssalData<void>>());

    final wrong =
        await repository.verifyEmailOtp('demo@assalkom.app', '000000');
    expect(wrong, isA<AssalError<AssalSession>>());

    final verified =
        await repository.verifyEmailOtp('demo@assalkom.app', '123456');
    expect(verified, isA<AssalData<AssalSession>>());
    expect((await repository.getSession()).isAuthenticated, isTrue);
  });

  test('Merchant workspace opens pending and owns its product/request scope',
      () async {
    final repository =
        DemoRepository(loader: const InMemoryDemoCatalogLoader(catalog));
    await repository.signIn('demo@assalkom.app', 'demo123');
    final opened = await repository.openMerchantWorkspace(
      'demo-customer',
      const AssalMerchantWorkspaceDraft(
        businessName: 'مناحل الاختبار',
        description: 'متجر اختبار لمسار التاجر.',
      ),
    );
    expect(opened, isA<AssalData<AssalMerchantWorkspaceSummary>>());
    final workspace =
        (opened as AssalData<AssalMerchantWorkspaceSummary>).value;
    expect(workspace.canEdit, isTrue);
    expect(workspace.canPublish, isFalse);
    expect(workspace.publicStatus, 'pending');
    expect(workspace.store.status, StoreStatus.pending);
    expect(workspace.store.isVerified, isFalse);
    expect(workspace.verificationStatus, 'pending');
    final updated = await repository.updateMerchantWorkspace(
      'demo-customer',
      workspace.store.id,
      const AssalMerchantWorkspaceDraft(
        businessName: 'مناحل الاختبار بعد التعديل',
        description: 'وصف محدث لمساحة التاجر.',
      ),
    );
    expect(updated, isA<AssalData<void>>());
    final loadedWorkspace =
        await repository.loadMerchantWorkspace('demo-customer');
    expect(
      (loadedWorkspace as AssalData<AssalMerchantWorkspaceSummary?>)
          .value
          ?.store
          .nameAr,
      'مناحل الاختبار بعد التعديل',
    );
    final created = await repository.createMerchantProduct(
      'demo-customer',
      workspace.store.id,
      const AssalProductDraft(
        nameAr: 'عسل اختبار',
        metadata: {
          'price': 12500,
          'weight_label': 'نصف كيلو',
          'origin_country': 'اليمن',
          'quality_label_ar': 'سدر أصلي',
          'delivery_options': ['توصيل محلي'],
        },
      ),
    );
    expect(created, isA<AssalData<AssalProductSummary>>());
    final createdProduct = (created as AssalData<AssalProductSummary>).value;
    expect(createdProduct.price, 12500);
    expect(createdProduct.weightLabel, 'نصف كيلو');
    expect(createdProduct.qualityLabelAr, 'سدر أصلي');
    expect(createdProduct.deliveryOptions, ['توصيل محلي']);
    final products = await repository.listMerchantProducts('demo-customer');
    expect(
        (products as AssalData<List<AssalProductSummary>>).value, hasLength(1));
    final requests = await repository.listMerchantRequests('demo-customer');
    expect(
      requests,
      anyOf(
        isA<AssalData<List<AssalRequestSummary>>>(),
        isA<AssalEmpty<List<AssalRequestSummary>>>(),
      ),
    );
  });

  test('merchant product create and pending edit round-trip all core fields', () async {
    final gateway = _ProductCrudGateway();
    final repository = ProductionRepository(gateway: gateway);
    const imageUrl = 'https://cdn.example/product-1.png';
    const draft = AssalProductDraft(
      nameAr: 'عسل سدر دوعني',
      nameEn: 'Doani Sidr Honey',
      description: 'منتج مسودة للاختبار',
      taxonomyId: 'taxonomy-1',
      productType: ProductType.honey,
      gradeLevel: 4,
      metadata: {
        'price': 22000,
        'currency_code': 'YER',
        'origin_country': 'اليمن',
        'region_id': 'region-1',
        'delivery_options': ['شبوة'],
      },
      imageUrls: [imageUrl],
    );

    final created = await repository.createMerchantProduct(
      'merchant-1',
      'store-1',
      draft,
    );
    expect(created, isA<AssalData<AssalProductSummary>>());
    final createdProduct = (created as AssalData<AssalProductSummary>).value;
    expect(createdProduct.nameAr, 'عسل سدر دوعني');
    expect(createdProduct.status, ProductStatus.pending);
    expect(createdProduct.imageUrls, [imageUrl]);
    expect(gateway.productImages.single['product_id'], 'product-1');

    const editedDraft = AssalProductDraft(
      nameAr: 'عسل سدر دوعني فاخر',
      description: 'وصف معدل',
      taxonomyId: 'taxonomy-2',
      productType: ProductType.honey,
      gradeLevel: 5,
      metadata: {
        'price': 25000,
        'currency_code': 'YER',
        'region_id': 'region-2',
      },
      imageUrls: [imageUrl],
    );
    final updated = await repository.updateMerchantProduct(
      'merchant-1',
      'product-1',
      editedDraft,
    );
    expect(updated, isA<AssalData<AssalProductSummary>>());
    final updatedProduct = (updated as AssalData<AssalProductSummary>).value;
    expect(updatedProduct.nameAr, 'عسل سدر دوعني فاخر');
    expect(updatedProduct.description, 'وصف معدل');
    expect(updatedProduct.taxonomyId, 'taxonomy-2');
    expect(updatedProduct.gradeLevel, 5);
    expect(updatedProduct.price, 25000);
    expect(gateway.product['metadata'], containsPair('region_id', 'region-2'));
    expect(updatedProduct.imageUrls, [imageUrl]);

    final denied = await repository.updateMerchantProduct(
      'other-user',
      'product-1',
      editedDraft,
    );
    expect(denied, isA<AssalError<AssalProductSummary>>());
  });

  test('verification request is independent from pending store activation', () async {
    final gateway = _VerificationRequestGateway();
    final repository = ProductionRepository(gateway: gateway);
    const draft = AssalStoreVerificationDraft(
      storeId: 'store-1',
      planCode: 'pro',
    );

    final created = await repository.createStoreVerificationRequest(
      'merchant-1',
      draft,
    );
    expect(created, isA<AssalData<AssalStoreVerificationSummary>>());
    final request = (created as AssalData<AssalStoreVerificationSummary>).value;
    expect(request.id, 'verification-1');
    expect(request.storeId, 'store-1');
    expect(request.merchantId, 'merchant-1');
    expect(request.status.name, 'draft');
    expect(request.paymentStatus, VerificationPaymentStatus.notStarted);
    expect(gateway.store['status'], 'pending');
    expect(gateway.store['is_verified'], isFalse);

    final loaded = await repository.loadStoreVerification('merchant-1', 'store-1');
    expect(loaded, isA<AssalData<AssalStoreVerificationSummary?>>());
    expect(
      (loaded as AssalData<AssalStoreVerificationSummary?>).value?.id,
      'verification-1',
    );

    final duplicate = await repository.createStoreVerificationRequest(
      'merchant-1',
      draft,
    );
    expect(duplicate, isA<AssalData<AssalStoreVerificationSummary>>());
    expect(
      (duplicate as AssalData<AssalStoreVerificationSummary>).value.id,
      'verification-1',
    );
    expect(gateway.requests, hasLength(1));
  });

  test('design request requires eligible entitlement and forwards the full draft', () async {
    final blocked = await ProductionRepository(
      gateway: _DesignRequestGateway(errorCode: 'active_plan_required'),
    ).createDesignRequest(
      'merchant-1',
      'store-1',
      const AssalDesignRequestDraft(
        title: 'هوية عبوة السدر',
        description: 'تصميم ملصق وهوية بصرية للمنتج.',
        brandName: 'عسل الوادي',
        brandColors: <String>['#8B5A2B', '#F4C76B'],
        productScope: <String, Object?>{'product_ids': <String>['product-1']},
      ),
    );
    expect(blocked, isA<AssalError<AssalDesignRequest>>());

    final eligibleGateway = _DesignRequestGateway();
    final created = await ProductionRepository(gateway: eligibleGateway)
        .createDesignRequest(
      'merchant-1',
      'store-1',
      const AssalDesignRequestDraft(
        title: 'هوية عبوة السدر',
        description: 'تصميم ملصق وهوية بصرية للمنتج.',
        brandName: 'عسل الوادي',
        brandColors: <String>['#8B5A2B', '#F4C76B'],
        productScope: <String, Object?>{'product_ids': <String>['product-1']},
      ),
    );
    expect(created, isA<AssalData<AssalDesignRequest>>());
    final request = (created as AssalData<AssalDesignRequest>).value;
    expect(request.status, 'submitted');
    expect(eligibleGateway.lastFunction, 'merchant_create_design_request');
    expect(eligibleGateway.lastParams['p_store_id'], 'store-1');
    expect(eligibleGateway.lastParams['p_brand_name'], 'عسل الوادي');
    expect(eligibleGateway.lastParams['p_brand_colors'], <String>['#8B5A2B', '#F4C76B']);
    expect(
      eligibleGateway.lastParams['p_product_scope'],
      <String, Object?>{'product_ids': <String>['product-1']},
    );

    final limited = await ProductionRepository(
      gateway: _DesignRequestGateway(errorCode: 'design_request_limit_reached'),
    ).createDesignRequest(
      'merchant-1',
      'store-1',
      const AssalDesignRequestDraft(title: 'طلب ثانٍ', description: 'تفاصيل'),
    );
    expect(limited, isA<AssalError<AssalDesignRequest>>());
  });

  test('expired or inactive subscriptions hide paid workspace entitlements without deleting store', () async {
    final expiredGateway = _InactiveSubscriptionWorkspaceGateway(
      subscriptionStatus: 'active',
      endsAt: '2026-08-19T10:00:00Z',
    );
    final expiredWorkspace =
        (await ProductionRepository(gateway: expiredGateway)
                .loadMerchantWorkspace('merchant-1')
            as AssalData<AssalMerchantWorkspaceSummary?>)
            .value;
    expect(expiredWorkspace, isNotNull);
    expect(expiredWorkspace!.store.id, 'store-1');
    expect(expiredWorkspace.planCode, isNull);
    expect(expiredWorkspace.planStatus, isNull);
    expect(expiredWorkspace.storeLimit, 1);
    expect(expiredWorkspace.productLimit, 25);
    expect(expiredWorkspace.designRequestsRemaining, 0);

    final suspendedGateway = _InactiveSubscriptionWorkspaceGateway(
      subscriptionStatus: 'suspended',
      endsAt: '2026-09-20T10:00:00Z',
    );
    final suspendedWorkspace =
        (await ProductionRepository(gateway: suspendedGateway)
                .loadMerchantWorkspace('merchant-1')
            as AssalData<AssalMerchantWorkspaceSummary?>)
            .value;
    expect(suspendedWorkspace?.planCode, isNull);
    expect(suspendedWorkspace?.planStatus, isNull);
    expect(suspendedWorkspace?.storeLimit, 1);
    expect(suspendedWorkspace?.productLimit, 25);
  });

  test('active subscription synchronizes plan entitlements and workspace limits', () async {
    final gateway = _ActiveSubscriptionWorkspaceGateway();
    final repository = ProductionRepository(gateway: gateway);

    final loaded = await repository.loadMerchantWorkspace('merchant-1');
    expect(loaded, isA<AssalData<AssalMerchantWorkspaceSummary?>>());
    final workspace = (loaded as AssalData<AssalMerchantWorkspaceSummary?>).value;
    expect(workspace, isNotNull);
    expect(workspace!.planCode, 'bronze_professional');
    expect(workspace.planStatus, 'active');
    expect(workspace.storeLimit, 5);
    expect(workspace.productLimit, 300);
    expect(workspace.designRequestsRemaining, 1);

    gateway.designRequests.add(<String, Object?>{
      'id': 'design-1',
      'subscription_id': 'subscription-1',
      'status': 'completed',
    });
    final consumed = await repository.loadMerchantWorkspace('merchant-1');
    final consumedWorkspace =
        (consumed as AssalData<AssalMerchantWorkspaceSummary?>).value;
    expect(consumedWorkspace?.designRequestsRemaining, 0);
  });

  test('bank transfer proof upload and submit preserve private metadata', () async {
    final gateway = _PaymentProofGateway();
    final repository = ProductionRepository(gateway: gateway);

    final uploaded = await repository.uploadPaymentProof(
      'merchant-1',
      'payment-1',
      Uint8List.fromList(<int>[1, 2, 3]),
      'png',
    );
    expect(uploaded, isA<AssalData<String>>());
    final uploadedPath = (uploaded as AssalData<String>).value;
    expect(uploadedPath, startsWith('merchant-1/payment-proofs/payment-1-'));
    expect(uploadedPath, endsWith('.png'));
    expect(gateway.uploadedPaths, [uploadedPath]);

    final submitted = await repository.submitPaymentProof(
      'merchant-1',
      'payment-1',
      '  transfer-123  ',
      uploadedPath,
      'receipt.png',
      'image/png',
      3,
      DateTime.utc(2026, 8, 20, 13, 45),
      60.10,
      '  المحول  ',
      ' 777123456 ',
    );
    expect(submitted, isA<AssalData<AssalPaymentRequest>>());
    final payment = (submitted as AssalData<AssalPaymentRequest>).value;
    expect(payment.status, 'proof_uploaded');
    expect(gateway.lastFunction, 'merchant_submit_payment_proof');
    expect(gateway.lastParams['p_payment_reference'], 'transfer-123');
    expect(gateway.lastParams['p_proof_path'], uploadedPath);
    expect(gateway.lastParams['p_proof_mime_type'], 'image/png');
    expect(gateway.lastParams['p_proof_byte_size'], 3);
    expect(gateway.lastParams['p_transfer_date'], '2026-08-20');
    expect(gateway.lastParams['p_submitted_amount'], 60.10);
    expect(gateway.lastParams['p_sender_name'], 'المحول');
    expect(gateway.lastParams['p_sender_phone'], '777123456');
  });

  test('payment request preserves server base discount and final amounts', () async {
    final gateway = _PricingRpcGateway();
    final repository = ProductionRepository(gateway: gateway);

    final state = await repository.createSubscriptionPaymentRequest(
      'merchant-1',
      'bronze-month',
    );
    expect(state, isA<AssalData<AssalPaymentRequest>>());
    final payment = (state as AssalData<AssalPaymentRequest>).value;
    expect(gateway.lastFunction, 'merchant_create_subscription_payment_request');
    expect(gateway.lastParams, <String, Object?>{'p_plan_id': 'bronze-month'});
    expect(payment.baseAmount, closeTo(70.71, 0.001));
    expect(payment.discountPercent, closeTo(15, 0.001));
    expect(payment.finalAmount, closeTo(60.10, 0.001));
    expect(payment.currency, 'SAR');

    final failed = await ProductionRepository(
      gateway: _ThrowingRpcGateway(StateError('pricing unavailable')),
    ).createSubscriptionPaymentRequest('merchant-1', 'bronze-month');
    expect(failed, isA<AssalError<AssalPaymentRequest>>());
  });

  test('subscription plans expose eight rows and per-plan campaign discounts', () async {
    final gateway = _PlansCampaignGateway();
    final repository = ProductionRepository(gateway: gateway);

    final plansState = await repository.listSubscriptionPlans();
    expect(plansState, isA<AssalData<List<AssalSubscriptionPlan>>>());
    final plans = (plansState as AssalData<List<AssalSubscriptionPlan>>).value;
    expect(plans, hasLength(8));
    expect(
      plans.map((plan) => '${plan.code}:${plan.billingInterval}').toList(),
      <String>[
        'basic:month',
        'basic:year',
        'standard:month',
        'standard:year',
        'bronze_professional:month',
        'bronze_professional:year',
        'gold:month',
        'gold:year',
      ],
    );
    expect(
      plans.singleWhere(
        (plan) => plan.code == 'standard' && plan.billingInterval == 'month',
      ).priceAmount,
      closeTo(35, 0.001),
    );
    expect(
      plans.singleWhere(
        (plan) => plan.code == 'standard' && plan.billingInterval == 'year',
      ).priceAmount,
      closeTo(350, 0.001),
    );
    expect(
      plans.singleWhere(
        (plan) =>
            plan.code == 'bronze_professional' &&
            plan.billingInterval == 'month',
      ).entitlements['design_requests_per_cycle'],
      1,
    );
    expect(
      plans.singleWhere(
        (plan) => plan.code == 'gold' && plan.billingInterval == 'month',
      ).verificationIncluded,
      3,
    );

    final campaignState = await repository.loadSubscriptionCampaign();
    expect(campaignState, isA<AssalData<AssalSubscriptionCampaign?>>());
    final campaign =
        (campaignState as AssalData<AssalSubscriptionCampaign?>).value;
    expect(campaign, isNotNull);
    expect(campaign!.isActive, isTrue);
    expect(campaign.discountPercent, closeTo(10, 0.001));
    expect(campaign.discountByPlanCode['basic'], closeTo(0, 0.001));
    expect(campaign.discountByPlanCode['standard'], closeTo(10, 0.001));
    expect(
      campaign.discountByPlanCode['bronze_professional'],
      closeTo(15, 0.001),
    );
    expect(campaign.discountByPlanCode['gold'], closeTo(15, 0.001));
    expect(campaign.appliesTo, containsAll(<String>['subscription', 'verification']));
  });

  test('expired and revoked badges never remain approved in merchant workspace', () async {
    final gateway = _VerificationLifecycleWorkspaceGateway();
    final repository = ProductionRepository(gateway: gateway);

    final expired = await repository.loadMerchantWorkspace('merchant-1');
    expect(expired, isA<AssalData<AssalMerchantWorkspaceSummary?>>());
    final expiredWorkspace =
        (expired as AssalData<AssalMerchantWorkspaceSummary?>).value;
    expect(expiredWorkspace?.verificationStatus, 'expired');
    expect(expiredWorkspace?.store.isVerified, isFalse);

    gateway.badges[0]['status'] = 'revoked';
    gateway.badges[0]['expires_at'] = null;
    final revoked = await repository.loadMerchantWorkspace('merchant-1');
    expect(
      (revoked as AssalData<AssalMerchantWorkspaceSummary?>)
          .value
          ?.verificationStatus,
      'revoked',
    );

    gateway.badges[0]['status'] = 'active';
    gateway.badges[0]['expires_at'] =
        DateTime.now().toUtc().add(const Duration(days: 30)).toIso8601String();
    final active = await repository.loadMerchantWorkspace('merchant-1');
    expect(
      (active as AssalData<AssalMerchantWorkspaceSummary?>)
          .value
          ?.verificationStatus,
      'approved',
    );
  });

  test('verification documents stay private and preserve metadata', () async {
    final gateway = _VerificationDocumentGateway();
    final repository = ProductionRepository(gateway: gateway);

    final uploaded = await repository.uploadVerificationDocument(
      'merchant-1',
      'verification-1',
      Uint8List.fromList(<int>[1, 2, 3, 4]),
      'pdf',
    );
    expect(uploaded, isA<AssalData<String>>());
    final uploadedPath = (uploaded as AssalData<String>).value;
    expect(uploadedPath, startsWith('merchant-1/verification/verification-1/document-'));
    expect(uploadedPath, endsWith('.pdf'));
    expect(gateway.uploadedPaths, [uploadedPath]);

    final saved = await repository.addVerificationDocument(
      'merchant-1',
      'verification-1',
      AssalVerificationDocumentDraft(
        documentType: VerificationDocumentType.identity,
        filePath: uploadedPath,
        fileName: 'identity.pdf',
        mimeType: 'application/pdf',
        byteSize: 4,
      ),
    );
    expect(saved, isA<AssalData<AssalStoreVerificationSummary>>());
    final summary = (saved as AssalData<AssalStoreVerificationSummary>).value;
    expect(summary.documentCount, 1);
    expect(summary.documentTypes, contains('identity'));
    expect(gateway.documents.single['file_path'], uploadedPath);
    expect(gateway.documents.single['file_name'], 'identity.pdf');
    expect(gateway.documents.single['mime_type'], 'application/pdf');
    expect(gateway.documents.single['byte_size'], 4);

    final foreignUpload = await repository.uploadVerificationDocument(
      'other-user',
      'verification-1',
      Uint8List.fromList(<int>[9]),
      'jpg',
    );
    expect(foreignUpload, isA<AssalError<String>>());
    expect(gateway.uploadedPaths, hasLength(1));
  });

  test('verification submit requires payment and records a transition event', () async {
    final gateway = _VerificationSubmitGateway();
    final repository = ProductionRepository(gateway: gateway);

    final blocked = await repository.submitStoreVerification(
      'merchant-1',
      'verification-1',
    );
    expect(blocked, isA<AssalError<AssalStoreVerificationSummary>>());
    expect(gateway.events, isEmpty);
    expect(gateway.request['status'], 'draft');

    gateway.request['payment_status'] = 'paid';
    final submitted = await repository.submitStoreVerification(
      'merchant-1',
      'verification-1',
    );
    expect(submitted, isA<AssalData<AssalStoreVerificationSummary>>());
    expect(
      (submitted as AssalData<AssalStoreVerificationSummary>).value.status.name,
      'submitted',
    );
    expect(gateway.events, hasLength(1));
    expect(gateway.events.single['from_status'], 'draft');
    expect(gateway.events.single['to_status'], 'submitted');
    expect(gateway.events.single['actor_user_id'], 'merchant-1');
  });

  test('active product edit creates pending review without overwriting product', () async {
    final gateway = _ProductCrudGateway();
    gateway.product['status'] = 'active';
    final repository = ProductionRepository(gateway: gateway);
    const draft = AssalProductDraft(
      nameAr: 'تعديل منشور آمن',
      description: 'يحتاج مراجعة',
      taxonomyId: 'taxonomy-2',
      productType: ProductType.honey,
      gradeLevel: 5,
      metadata: {'price': 30000},
      imageUrls: [],
    );

    final result = await repository.updateMerchantProduct(
      'merchant-1',
      'product-1',
      draft,
    );
    expect(result, isA<AssalData<AssalProductSummary>>());
    expect(gateway.revisions, hasLength(1));
    expect(gateway.revisions.single['product_id'], 'product-1');
    expect(gateway.revisions.single['store_id'], 'store-1');
    expect(gateway.revisions.single['editor_user_id'], 'merchant-1');
    expect(gateway.revisions.single['status'], 'pending_review');
    expect(gateway.revisions.single['payload'], containsPair('name_ar', 'تعديل منشور آمن'));
    expect(gateway.product['name_ar'], 'قديم');
    expect(gateway.productUpdated, isFalse);

    final denied = await repository.updateMerchantProduct('other-user', 'product-1', draft);
    expect(denied, isA<AssalError<AssalProductSummary>>());
    expect(gateway.revisions, hasLength(1));
  });

  test('merchant workspace save reloads store fields and gallery across devices', () async {
    final gateway = _WorkspaceRoundTripGateway();
    final firstRepository = ProductionRepository(gateway: gateway);
    final before = await firstRepository.loadMerchantWorkspace('merchant-1');
    if (before is AssalError<AssalMerchantWorkspaceSummary?>) {
      fail('initial workspace load failed: ${before.messageAr} [${before.code}]');
    }
    expect(before, isA<AssalData<AssalMerchantWorkspaceSummary?>>());
    expect(
      (before as AssalData<AssalMerchantWorkspaceSummary?>).value!.store.nameAr,
      'متجر قبل التعديل',
    );

    final saved = await firstRepository.updateMerchantWorkspace(
      'merchant-1',
      'store-1',
      const AssalMerchantWorkspaceDraft(
        businessName: 'متجر بعد التعديل',
        description: 'وصف محفوظ بين الأجهزة',
        phone: '777111111',
        logoUrl: 'https://cdn.example/logo-new.png',
        coverUrl: 'https://cdn.example/cover-new.png',
        regionId: 'region-2',
      ),
    );
    expect(saved, isA<AssalData<void>>());

    final secondRepository = ProductionRepository(gateway: gateway);
    final reloaded = await secondRepository.loadMerchantWorkspace('merchant-1');
    expect(reloaded, isA<AssalData<AssalMerchantWorkspaceSummary?>>());
    final workspace =
        (reloaded as AssalData<AssalMerchantWorkspaceSummary?>).value!;
    expect(workspace.store.nameAr, 'متجر بعد التعديل');
    expect(workspace.store.description, 'وصف محفوظ بين الأجهزة');
    expect(workspace.store.contactPhone, '777111111');
    expect(workspace.store.regionId, 'region-2');
    expect(workspace.store.logoUrl, 'https://cdn.example/logo-new.png');
    expect(workspace.store.coverUrl, 'https://cdn.example/cover-new.png');
    expect(workspace.store.galleryUrls, ['https://cdn.example/gallery-1.png']);
  });

  test('ProductionRepository permits the owner profile update', () async {
    final gateway = _ProfileUpdateGateway();
    final repository = ProductionRepository(
      gateway: gateway,
      authGateway: _StaticAuthGateway(
        const AssalAuthIdentity(id: 'owner-user'),
      ),
    );
    final result = await repository.updateUserProfile(
      'owner-user',
      const AssalUserProfilePatch(
        nameAr: 'المالك',
        bio: 'نبذة المالك',
        phone: '777000000',
        locationLabel: 'صنعاء',
      ),
    );

    expect(result, isA<AssalData<void>>());
    expect(gateway.table, 'profiles');
    expect(gateway.onConflict, 'user_id');
    expect(gateway.values, containsPair('user_id', 'owner-user'));
    expect(gateway.values, containsPair('display_name', 'المالك'));
    expect(gateway.values, containsPair('bio', 'نبذة المالك'));
    expect(gateway.values, containsPair('phone', '777000000'));
    expect(gateway.values, containsPair('location_label', 'صنعاء'));
    expect(gateway.values.containsKey('role'), isFalse);
  });

  test('ProductionRepository rejects profile updates for another identity',
      () async {
    final repository = ProductionRepository(
      gateway: _NoopProductionGateway(),
      authGateway: _StaticAuthGateway(
        const AssalAuthIdentity(id: 'owner-user'),
      ),
    );
    final result = await repository.updateUserProfile(
      'different-user',
      const AssalUserProfilePatch(nameAr: 'محاولة غير مملوكة'),
    );
    expect(result, isA<AssalError<void>>());
    expect((result as AssalError<void>).code, 'profile_not_owned');
  });

  test('ProductionRepository classifies read failures without hiding them',
      () async {
    final repository = ProductionRepository(
      gateway: _NoopProductionGateway(),
      authGateway: _StaticAuthGateway(null),
    );
    final result = await repository.listRegions();
    expect(result, isA<AssalError<List<AssalRegion>>>());
    final error = result as AssalError<List<AssalRegion>>;
    expect(error.kind, AssalErrorKind.server);
    expect(error.retryable, isFalse);
  });

  test(
      'ProductionRepository maps message timeout to retryable failure without fake success',
      () async {
    final repository = ProductionRepository(
      gateway: _ThrowingRpcGateway(TimeoutException('message timeout')),
    );
    final result = await repository.sendMessage(
      'sender-user',
      const AssalMessageDraft(
        conversationId: 'conversation-1',
        body: 'رسالة اختبار timeout',
      ),
    );

    expect(result, isA<AssalError<AssalMessageSummary>>());
    expect(result, isNot(isA<AssalData<AssalMessageSummary>>()));
    final error = result as AssalError<AssalMessageSummary>;
    expect(error.code, 'timeout');
    expect(error.kind, AssalErrorKind.network);
    expect(error.retryable, isTrue);
    expect(error.messageAr, contains('حاول مرة أخرى'));
  });

  test(
      'ProductionRepository maps offline socket failure to retryable failure without fake success',
      () async {
    final repository = ProductionRepository(
      gateway: _ThrowingRpcGateway(
          const SocketException('connection reset by peer')),
    );
    final result = await repository.sendMessage(
      'sender-user',
      const AssalMessageDraft(
        conversationId: 'conversation-1',
        body: 'رسالة اختبار offline',
      ),
    );

    expect(result, isA<AssalError<AssalMessageSummary>>());
    expect(result, isNot(isA<AssalData<AssalMessageSummary>>()));
    final error = result as AssalError<AssalMessageSummary>;
    expect(error.kind, AssalErrorKind.network);
    expect(error.retryable, isTrue);
    expect(error.code, 'network');
    expect(error.messageAr, contains('تحقق من الاتصال'));
  });

  test('ProductionRepository keeps server failures as non-success states',
      () async {
    final repository = ProductionRepository(
      gateway: _ThrowingRpcGateway(StateError('message backend unavailable')),
    );
    final result = await repository.sendMessage(
      'sender-user',
      const AssalMessageDraft(
        conversationId: 'conversation-1',
        body: 'رسالة اختبار server failure',
      ),
    );

    expect(result, isA<AssalError<AssalMessageSummary>>());
    expect(result, isNot(isA<AssalData<AssalMessageSummary>>()));
    final error = result as AssalError<AssalMessageSummary>;
    expect(error.code, 'data_write_failed');
    expect(error.retryable, isFalse);
    expect(error.kind, AssalErrorKind.server);
  });

  test(
      'ProductionRepository follow RPC does not forward the passed user identity',
      () async {
    final gateway = _RecordingFollowGateway();
    final repository = ProductionRepository(gateway: gateway);
    final result =
        await repository.toggleFollow('wrong-or-stale-user', 'store-1');

    expect(result, isA<AssalData<bool>>());
    expect((result as AssalData<bool>).value, isTrue);
    expect(gateway.lastFunction, 'customer_toggle_store_follow');
    expect(gateway.lastParams, {'p_store_id': 'store-1'});
    expect(gateway.lastParams.containsKey('p_user_id'), isFalse);
  });

  test('Unavailable session is distinct from an intentional guest session', () {
    expect(AssalSession.guest.isUnavailable, isFalse);
    expect(AssalSession.unavailable.isUnavailable, isTrue);
    expect(AssalSession.unavailable.errorMessageAr, isNotEmpty);
  });

  test('ProductionRepository sorts newest products by production date',
      () async {
    final repository = ProductionRepository(
      gateway: _RowsProductionGateway([
        {
          'id': 'p-old',
          'store_id': 's1',
          'name_ar': 'قديم',
          'product_type': 'honey',
          'status': 'active',
          'production_date': '2025-01-01T00:00:00Z',
        },
        {
          'id': 'p-new',
          'store_id': 's1',
          'name_ar': 'جديد',
          'product_type': 'honey',
          'status': 'active',
          'production_date': '2026-01-01T00:00:00Z',
        },
      ]),
    );
    final result = await repository.listProducts(
      query: const AssalProductQuery(sort: AssalSort.newest),
    );
    final products = (result as AssalData<List<AssalProductSummary>>).value;
    expect(products.map((item) => item.id), ['p-new', 'p-old']);
  });

  test('ProductionRepository newest sort falls back to created_at', () async {
    final repository = ProductionRepository(
      gateway: _RowsProductionGateway([
        {
          'id': 'p-old-created',
          'store_id': 's1',
          'name_ar': 'أقدم إنشاءً',
          'product_type': 'honey',
          'status': 'active',
          'created_at': '2026-08-01T00:00:00Z',
        },
        {
          'id': 'p-new-created',
          'store_id': 's1',
          'name_ar': 'أحدث إنشاءً',
          'product_type': 'honey',
          'status': 'active',
          'created_at': '2026-08-20T00:00:00Z',
        },
      ]),
    );
    final result = await repository.listProducts(
      query: const AssalProductQuery(sort: AssalSort.newest),
    );
    final products = (result as AssalData<List<AssalProductSummary>>).value;
    expect(products.map((item) => item.id), ['p-new-created', 'p-old-created']);
  });

  test('ProductionRepository sorts all read-model product modes', () async {
    final repository = ProductionRepository(
      gateway: _RowsProductionGateway([
        {
          'id': 'p-featured',
          'store_id': 's1',
          'name_ar': 'مميز',
          'product_type': 'honey',
          'status': 'active',
          'is_featured': true,
          'production_date': '2026-01-01T00:00:00Z',
          'views_count': 10,
          'rating_average': 2.0,
        },
        {
          'id': 'p-newest',
          'store_id': 's1',
          'name_ar': 'أحدث',
          'product_type': 'honey',
          'status': 'active',
          'is_featured': false,
          'production_date': '2026-08-01T00:00:00Z',
          'views_count': 20,
          'rating_average': 3.0,
        },
        {
          'id': 'p-popular',
          'store_id': 's1',
          'name_ar': 'الأكثر مشاهدة',
          'product_type': 'honey',
          'status': 'active',
          'is_featured': false,
          'production_date': '2026-02-01T00:00:00Z',
          'views_count': 99,
          'rating_average': 4.0,
        },
        {
          'id': 'p-rating',
          'store_id': 's1',
          'name_ar': 'الأعلى تقييمًا',
          'product_type': 'honey',
          'status': 'active',
          'is_featured': false,
          'production_date': '2026-03-01T00:00:00Z',
          'views_count': 5,
          'rating_average': 4.9,
        },
      ]),
    );

    Future<String> firstId(AssalSort sort) async {
      final result = await repository.listProducts(
        query: AssalProductQuery(sort: sort),
      );
      expect(result, isA<AssalData<List<AssalProductSummary>>>());
      return (result as AssalData<List<AssalProductSummary>>).value.first.id;
    }

    expect(await firstId(AssalSort.featured), 'p-featured');
    expect(await firstId(AssalSort.newest), 'p-newest');
    expect(await firstId(AssalSort.popular), 'p-popular');
    expect(await firstId(AssalSort.rating), 'p-rating');
  });

  test('ProductionRepository applies read-model product filters', () async {
    final gateway = _FilterRowsProductionGateway({
      'customer_products': [
        {
          'id': 'p-match',
          'store_id': 's1',
          'name_ar': 'مطابق',
          'product_type': 'honey',
          'status': 'active',
          'category_id': 'c1',
          'subcategory_id': 't1',
          'taxonomy_id': 't1',
          'region_id': 'r1',
          'province_id': 'd1',
          'grade_level': 2,
          'price': 100,
          'rating_average': 4.5,
        },
        {
          'id': 'p-other',
          'store_id': 's2',
          'name_ar': 'غير مطابق',
          'product_type': 'wax',
          'status': 'active',
          'category_id': 'c2',
          'subcategory_id': 't2',
          'taxonomy_id': 't2',
          'region_id': 'r2',
          'province_id': 'd2',
          'grade_level': 1,
          'price': 200,
          'rating_average': 3.0,
        },
      ],
    });
    final repository = ProductionRepository(gateway: gateway);

    Future<List<AssalProductSummary>> query(AssalProductQuery value) async {
      final result = await repository.listProducts(query: value);
      expect(result, isA<AssalData<List<AssalProductSummary>>>());
      return (result as AssalData<List<AssalProductSummary>>).value;
    }

    expect(
      (await query(const AssalProductQuery(categoryId: 'c1')))
          .map((item) => item.id),
      ['p-match'],
    );
    expect(gateway.productFilters.last['category_id'], 'c1');

    expect(
      (await query(const AssalProductQuery(regionId: 'r1')))
          .map((item) => item.id),
      ['p-match'],
    );
    expect(gateway.productFilters.last['region_id'], 'r1');

    expect(
      (await query(const AssalProductQuery(subcategoryId: 't1')))
          .map((item) => item.id),
      ['p-match'],
    );
    expect(
      (await query(const AssalProductQuery(productType: ProductType.honey)))
          .map((item) => item.id),
      ['p-match'],
    );
    expect(
      (await query(const AssalProductQuery(minPrice: 90, maxPrice: 110)))
          .map((item) => item.id),
      ['p-match'],
    );
    expect(
      (await query(const AssalProductQuery(minRating: 4)))
          .map((item) => item.id),
      ['p-match'],
    );
  });

  test('ProductionRepository maps image uploads to public prefixes and DB rows', () async {
    final gateway = _UploadRecordingGateway();
    final repository = ProductionRepository(gateway: gateway);
    final bytes = Uint8List.fromList(const [1, 2, 3]);

    final profile = await repository.uploadMerchantImage(
      'u1',
      'cover',
      bytes,
      'png',
    );
    expect(profile, isA<AssalData<String>>());
    expect(gateway.publicPaths.single, startsWith('u1/merchant/cover-'));
    expect(gateway.inserts, isEmpty);

    final gallery = await repository.uploadStoreGalleryImage(
      'u1',
      's1',
      bytes,
      'png',
    );
    expect(gallery, isA<AssalData<String>>());
    expect(gateway.publicPaths[1], startsWith('u1/store/s1/gallery-'));
    expect(gateway.inserts.single['table'], 'store_gallery');
    expect(gateway.inserts.single['values'], containsPair('store_id', 's1'));

    final product = await repository.uploadProductImage(
      'u1',
      'p1',
      bytes,
      'png',
    );
    expect(product, isA<AssalData<String>>());
    expect(gateway.publicPaths[2], startsWith('u1/product/p1/image-'));
    expect(gateway.inserts[1]['table'], 'product_images');
    expect(gateway.inserts[1]['values'], containsPair('product_id', 'p1'));

    gateway.failUpload = true;
    final failed = await repository.uploadProductImage(
      'u1',
      'p1',
      bytes,
      'png',
    );
    expect(failed, isA<AssalError<String>>());
    expect(gateway.inserts, hasLength(2));
  });

  test('Factory rejects production without an explicit gateway', () {
    expect(
        () => const AssalRepositoryFactory().create(
            mode: AssalDataSourceMode.production,
            demoLoader: const InMemoryDemoCatalogLoader(catalog)),
        throwsA(isA<ProductionRepositoryNotConfigured>()));
  });
}

class _VerificationRequestGateway extends _NoopProductionGateway {
  final Map<String, Object?> store = <String, Object?>{
    'id': 'store-1',
    'merchant_id': 'merchant-1',
    'status': 'pending',
    'is_verified': false,
  };
  final List<Map<String, Object?>> requests = <Map<String, Object?>>[];

  @override
  Future<List<Map<String, Object?>>> select(
    String table, {
    Map<String, Object?> filters = const <String, Object?>{},
  }) async {
    if (table == 'stores' &&
        filters['id'] == 'store-1' &&
        filters['merchant_id'] == 'merchant-1') {
      return [Map<String, Object?>.from(store)];
    }
    if (table == 'store_verification_requests') {
      return requests
          .where((row) => filters.entries.every((entry) => row[entry.key] == entry.value))
          .map(Map<String, Object?>.from)
          .toList();
    }
    if (table == 'store_verification_documents') {
      return <Map<String, Object?>>[];
    }
    return <Map<String, Object?>>[];
  }

  @override
  Future<Map<String, Object?>> insert(
    String table,
    Map<String, Object?> values,
  ) async {
    if (table == 'store_verification_requests') {
      final row = <String, Object?>{
        'id': 'verification-1',
        'created_at': '2026-08-20T10:00:00Z',
        ...values,
      };
      requests.add(row);
      return Map<String, Object?>.from(row);
    }
    return values;
  }
}

class _DesignRequestGateway extends _NoopProductionGateway {
  _DesignRequestGateway({this.errorCode});

  final String? errorCode;
  String? lastFunction;
  Map<String, Object?> lastParams = const <String, Object?>{};

  @override
  Future<Map<String, Object?>> rpc(
    String function,
    Map<String, Object?> params,
  ) async {
    lastFunction = function;
    lastParams = Map<String, Object?>.from(params);
    if (errorCode != null) throw StateError(errorCode!);
    return <String, Object?>{
      'id': 'design-1',
      'store_id': params['p_store_id'],
      'title': params['p_title'],
      'description': params['p_description'],
      'status': 'submitted',
      'created_at': '2026-08-20T10:00:00Z',
    };
  }
}

class _InactiveSubscriptionWorkspaceGateway extends _NoopProductionGateway {
  _InactiveSubscriptionWorkspaceGateway({
    required this.subscriptionStatus,
    required this.endsAt,
  });

  final String subscriptionStatus;
  final String endsAt;

  @override
  Future<List<Map<String, Object?>>> select(
    String table, {
    Map<String, Object?> filters = const <String, Object?>{},
  }) async {
    if (table == 'stores' && filters['merchant_id'] == 'merchant-1') {
      return <Map<String, Object?>>[
        <String, Object?>{
          'id': 'store-1',
          'merchant_id': 'merchant-1',
          'name_ar': 'متجر محفوظ',
          'slug': 'kept-store',
          'status': 'active',
          'is_verified': false,
        },
      ];
    }
    if (table == 'store_badges' || table == 'store_verification_requests') {
      return <Map<String, Object?>>[];
    }
    if (table == 'merchant_subscriptions' &&
        filters['merchant_id'] == 'merchant-1' &&
        filters['status'] == 'active' &&
        subscriptionStatus == 'active') {
      return <Map<String, Object?>>[
        <String, Object?>{
          'id': 'subscription-inactive',
          'merchant_id': 'merchant-1',
          'plan_id': 'bronze-plan',
          'status': subscriptionStatus,
          'starts_at': '2026-08-01T10:00:00Z',
          'ends_at': endsAt,
        },
      ];
    }
    return <Map<String, Object?>>[];
  }
}

class _ActiveSubscriptionWorkspaceGateway extends _NoopProductionGateway {
  final List<Map<String, Object?>> designRequests = <Map<String, Object?>>[];

  @override
  Future<List<Map<String, Object?>>> select(
    String table, {
    Map<String, Object?> filters = const <String, Object?>{},
  }) async {
    if (table == 'stores' && filters['merchant_id'] == 'merchant-1') {
      return <Map<String, Object?>>[
        <String, Object?>{
          'id': 'store-1',
          'merchant_id': 'merchant-1',
          'name_ar': 'متجر الخطة',
          'slug': 'plan-store',
          'status': 'active',
          'is_verified': false,
        },
      ];
    }
    if (table == 'store_badges') return <Map<String, Object?>>[];
    if (table == 'store_verification_requests') {
      return <Map<String, Object?>>[];
    }
    if (table == 'merchant_subscriptions' &&
        filters['merchant_id'] == 'merchant-1' &&
        filters['status'] == 'active') {
      return <Map<String, Object?>>[
        <String, Object?>{
          'id': 'subscription-1',
          'merchant_id': 'merchant-1',
          'plan_id': 'bronze-plan',
          'status': 'active',
          'starts_at': '2026-08-20T10:00:00Z',
          'ends_at': '2026-09-20T10:00:00Z',
        },
      ];
    }
    if (table == 'subscription_plans' && filters['id'] == 'bronze-plan') {
      return <Map<String, Object?>>[
        <String, Object?>{
          'id': 'bronze-plan',
          'code': 'bronze_professional',
          'name_ar': 'البرونزية الاحترافية',
          'billing_interval': 'month',
          'price_amount': 70.71,
          'currency': 'SAR',
          'store_limit': 5,
          'product_limit': 300,
          'verification_included': 1,
          'entitlements': <String, Object?>{
            'design_requests_per_cycle': 1,
          },
          'is_active': true,
        },
      ];
    }
    if (table == 'design_requests' &&
        filters['subscription_id'] == 'subscription-1') {
      return designRequests.map(Map<String, Object?>.from).toList();
    }
    return <Map<String, Object?>>[];
  }
}

class _PaymentProofGateway extends _NoopProductionGateway {
  final List<String> uploadedPaths = <String>[];
  String? lastFunction;
  Map<String, Object?> lastParams = const <String, Object?>{};

  @override
  Future<String> uploadPrivateImage(
    String path,
    Uint8List bytes,
    String extension,
  ) async {
    expect(bytes, isNotEmpty);
    expect(extension, 'png');
    uploadedPaths.add(path);
    return path;
  }

  @override
  Future<Map<String, Object?>> rpc(
    String function,
    Map<String, Object?> params,
  ) async {
    lastFunction = function;
    lastParams = Map<String, Object?>.from(params);
    return <String, Object?>{
      'id': 'payment-1',
      'payment_type': 'subscription',
      'status': 'proof_uploaded',
      'base_amount': 70.71,
      'discount_percent': 15,
      'final_amount': 60.10,
      'currency': 'SAR',
      'plan_id': 'bronze-month',
      'payment_reference': 'transfer-123',
      'proof_path': params['p_proof_path'],
      'created_at': '2026-08-20T10:00:00Z',
    };
  }
}

class _PricingRpcGateway extends _NoopProductionGateway {
  String? lastFunction;
  Map<String, Object?> lastParams = const <String, Object?>{};

  @override
  Future<Map<String, Object?>> rpc(
    String function,
    Map<String, Object?> params,
  ) async {
    lastFunction = function;
    lastParams = Map<String, Object?>.from(params);
    return <String, Object?>{
      'id': 'payment-1',
      'payment_type': 'subscription',
      'status': 'not_started',
      'base_amount': 70.71,
      'discount_percent': 15,
      'final_amount': 60.10,
      'currency': 'SAR',
      'plan_id': 'bronze-month',
      'payment_reference': null,
      'proof_path': null,
      'created_at': '2026-08-20T10:00:00Z',
    };
  }
}

class _PlansCampaignGateway extends _NoopProductionGateway {
  final List<Map<String, Object?>> plans = <Map<String, Object?>>[
    _planRow('basic', 'month', 0, 1, 25, 0, 1),
    _planRow('basic', 'year', 0, 1, 25, 0, 2),
    _planRow('standard', 'month', 35, 2, 100, 0, 3),
    _planRow('standard', 'year', 350, 2, 100, 0, 4),
    _planRow('bronze_professional', 'month', 70.71, 5, 300, 1, 5),
    _planRow('bronze_professional', 'year', 707.10, 5, 300, 1, 6),
    _planRow('gold', 'month', 142.14, 10, 1000, 3, 7),
    _planRow('gold', 'year', 1421.40, 10, 1000, 3, 8),
  ];

  final List<Map<String, Object?>> campaigns = <Map<String, Object?>>[
    <String, Object?>{
      'id': 'campaign-1',
      'name_ar': 'افتتاح تطبيق عسلكم',
      'discount_percent': 10,
      'discount_by_plan_code': <String, Object?>{
        'basic': 0,
        'standard': 10,
        'bronze_professional': 15,
        'gold': 15,
        'verification': 10,
      },
      'is_active': true,
      'starts_at': null,
      'ends_at': null,
      'applies_to': <String>['subscription', 'verification'],
    },
  ];

  @override
  Future<List<Map<String, Object?>>> select(
    String table, {
    Map<String, Object?> filters = const <String, Object?>{},
  }) async {
    if (table == 'subscription_plans') {
      return plans
          .where((row) => filters['is_active'] != true || row['is_active'] == true)
          .map(Map<String, Object?>.from)
          .toList();
    }
    if (table == 'subscription_campaigns') {
      return campaigns
          .where((row) => filters['is_active'] != true || row['is_active'] == true)
          .map(Map<String, Object?>.from)
          .toList();
    }
    return <Map<String, Object?>>[];
  }

  static Map<String, Object?> _planRow(
    String code,
    String interval,
    num price,
    int storeLimit,
    int productLimit,
    int verificationIncluded,
    int sortOrder,
  ) => <String, Object?>{
    'id': '$code-$interval',
    'code': code,
    'name_ar': code,
    'billing_interval': interval,
    'price_amount': price,
    'currency': 'SAR',
    'store_limit': storeLimit,
    'product_limit': productLimit,
    'verification_included': verificationIncluded,
    'sort_order': sortOrder,
    'entitlements': <String, Object?>{
      'analytics': code == 'basic' || code == 'standard' ? 'basic' : 'advanced',
      'priority': code == 'gold' ? 'priority' : 'standard',
      'design_requests_per_cycle':
          code == 'gold' ? 3 : code == 'bronze_professional' ? 1 : 0,
    },
    'is_active': true,
  };
}

class _VerificationLifecycleWorkspaceGateway extends _NoopProductionGateway {
  final Map<String, Object?> store = <String, Object?>{
    'id': 'store-1',
    'merchant_id': 'merchant-1',
    'name_ar': 'متجر دورة التوثيق',
    'slug': 'verification-lifecycle',
    'status': 'active',
    'is_verified': false,
  };
  final List<Map<String, Object?>> badges = <Map<String, Object?>>[
    <String, Object?>{
      'store_id': 'store-1',
      'status': 'active',
      'expires_at': null,
    },
  ];

  _VerificationLifecycleWorkspaceGateway() {
    badges[0]['expires_at'] =
        DateTime.now().toUtc().subtract(const Duration(minutes: 1)).toIso8601String();
  }

  @override
  Future<List<Map<String, Object?>>> select(
    String table, {
    Map<String, Object?> filters = const <String, Object?>{},
  }) async {
    if (table == 'stores' && filters['merchant_id'] == 'merchant-1') {
      return [Map<String, Object?>.from(store)];
    }
    if (table == 'store_badges' && filters['store_id'] == 'store-1') {
      return badges.map(Map<String, Object?>.from).toList();
    }
    if (table == 'store_verification_requests' &&
        filters['store_id'] == 'store-1') {
      return <Map<String, Object?>>[
        <String, Object?>{
          'id': 'verification-1',
          'store_id': 'store-1',
          'merchant_id': 'merchant-1',
          'status': 'approved',
          'created_at': '2026-08-20T10:00:00Z',
        },
      ];
    }
    return <Map<String, Object?>>[];
  }
}

class _VerificationDocumentGateway extends _NoopProductionGateway {
  final Map<String, Object?> request = <String, Object?>{
    'id': 'verification-1',
    'store_id': 'store-1',
    'merchant_id': 'merchant-1',
    'plan_code': 'pro',
    'status': 'draft',
    'payment_status': 'not_started',
    'created_at': '2026-08-20T10:00:00Z',
  };
  final List<Map<String, Object?>> documents = <Map<String, Object?>>[];
  final List<String> uploadedPaths = <String>[];

  @override
  Future<List<Map<String, Object?>>> select(
    String table, {
    Map<String, Object?> filters = const <String, Object?>{},
  }) async {
    if (table == 'store_verification_requests' &&
        filters['id'] == request['id'] &&
        filters['merchant_id'] == request['merchant_id']) {
      return [Map<String, Object?>.from(request)];
    }
    if (table == 'store_verification_documents' &&
        filters['request_id'] == request['id']) {
      return documents.map(Map<String, Object?>.from).toList();
    }
    return <Map<String, Object?>>[];
  }

  @override
  Future<String> uploadPrivateImage(
    String path,
    Uint8List bytes,
    String extension,
  ) async {
    expect(bytes, isNotEmpty);
    expect(extension, anyOf('pdf', 'jpg', 'png', 'webp'));
    uploadedPaths.add(path);
    return path;
  }

  @override
  Future<Map<String, Object?>> insert(
    String table,
    Map<String, Object?> values,
  ) async {
    if (table == 'store_verification_documents') {
      final row = <String, Object?>{
        'id': 'document-1',
        'created_at': '2026-08-20T10:01:00Z',
        ...values,
      };
      documents.add(row);
      return Map<String, Object?>.from(row);
    }
    return values;
  }
}

class _VerificationSubmitGateway extends _NoopProductionGateway {
  final Map<String, Object?> request = <String, Object?>{
    'id': 'verification-1',
    'store_id': 'store-1',
    'merchant_id': 'merchant-1',
    'plan_code': 'pro',
    'status': 'draft',
    'payment_status': 'not_started',
    'created_at': '2026-08-20T10:00:00Z',
  };
  final List<Map<String, Object?>> events = <Map<String, Object?>>[];

  @override
  Future<List<Map<String, Object?>>> select(
    String table, {
    Map<String, Object?> filters = const <String, Object?>{},
  }) async {
    if (table == 'store_verification_requests' &&
        filters['id'] == request['id'] &&
        filters['merchant_id'] == request['merchant_id']) {
      return [Map<String, Object?>.from(request)];
    }
    if (table == 'store_verification_documents') {
      return <Map<String, Object?>>[];
    }
    return <Map<String, Object?>>[];
  }

  @override
  Future<Map<String, Object?>> update(
    String table,
    Map<String, Object?> values, {
    required String id,
  }) async {
    expect(table, 'store_verification_requests');
    expect(id, 'verification-1');
    request.addAll(values);
    return Map<String, Object?>.from(request);
  }

  @override
  Future<Map<String, Object?>> insert(
    String table,
    Map<String, Object?> values,
  ) async {
    if (table == 'store_verification_events') {
      events.add(Map<String, Object?>.from(values));
    }
    return values;
  }
}

class _ProductCrudGateway extends _NoopProductionGateway {
  final Map<String, Object?> store = const <String, Object?>{
    'id': 'store-1',
    'merchant_id': 'merchant-1',
  };
  final Map<String, Object?> product = <String, Object?>{
    'id': 'product-1',
    'store_id': 'store-1',
    'name_ar': 'قديم',
    'name_en': null,
    'description': null,
    'taxonomy_id': 'taxonomy-1',
    'product_type': 'honey',
    'grade_level': 2,
    'status': 'pending',
    'updated_at': '2026-08-20T00:00:00Z',
    'metadata': <String, Object?>{},
  };
  final List<Map<String, Object?>> productImages = <Map<String, Object?>>[];
  final List<Map<String, Object?>> revisions = <Map<String, Object?>>[];
  bool productUpdated = false;

  @override
  Future<List<Map<String, Object?>>> select(
    String table, {
    Map<String, Object?> filters = const <String, Object?>{},
  }) async {
    if (table == 'stores' &&
        filters['id'] == 'store-1' &&
        filters['merchant_id'] == 'merchant-1') {
      return [Map<String, Object?>.from(store)];
    }
    if (table == 'products' && filters['id'] == 'product-1') {
      return [Map<String, Object?>.from(product)];
    }
    if (table == 'product_images' && filters['product_id'] == 'product-1') {
      return productImages.map(Map<String, Object?>.from).toList();
    }
    return <Map<String, Object?>>[];
  }

  @override
  Future<Map<String, Object?>> insert(
    String table,
    Map<String, Object?> values,
  ) async {
    if (table == 'products') {
      product
        ..clear()
        ..addAll({'id': 'product-1', ...values});
      return Map<String, Object?>.from(product);
    }
    if (table == 'product_images') {
      productImages.add(Map<String, Object?>.from(values));
      return values;
    }
    if (table == 'product_revisions') {
      revisions.add(Map<String, Object?>.from(values));
      return values;
    }
    return values;
  }

  @override
  Future<Map<String, Object?>> update(
    String table,
    Map<String, Object?> values, {
    required String id,
  }) async {
    productUpdated = true;
    product.addAll(values);
    return Map<String, Object?>.from(product);
  }
}

class _WorkspaceRoundTripGateway extends _NoopProductionGateway {
  final Map<String, Object?> store = <String, Object?>{
    'id': 'store-1',
    'merchant_id': 'merchant-1',
    'name_ar': 'متجر قبل التعديل',
    'slug': 'store-before',
    'description': 'وصف قبل التعديل',
    'region_id': 'region-1',
    'region_name_ar': 'صنعاء',
    'logo_url': 'https://cdn.example/logo-old.png',
    'cover_url': 'https://cdn.example/cover-old.png',
    'phone': '777000000',
    'status': 'pending',
    'is_verified': false,
  };
  final gallery = <Map<String, Object?>>[
    {
      'store_id': 'store-1',
      'media_url': 'https://cdn.example/gallery-1.png',
      'sort_order': 0,
    },
  ];

  @override
  Future<List<Map<String, Object?>>> select(
    String table, {
    Map<String, Object?> filters = const <String, Object?>{},
  }) async {
    if (table == 'stores' &&
        (filters['merchant_id'] == 'merchant-1' ||
            filters['id'] == 'store-1')) {
      return [Map<String, Object?>.from(store)];
    }
    if (table == 'store_gallery' && filters['store_id'] == 'store-1') {
      return gallery.map(Map<String, Object?>.from).toList();
    }
    return <Map<String, Object?>>[];
  }

  @override
  Future<Map<String, Object?>> update(
    String table,
    Map<String, Object?> values, {
    required String id,
  }) async {
    if (table == 'stores' && id == 'store-1') {
      store.addAll(values);
    }
    return Map<String, Object?>.from(store);
  }
}

class _ProfileUpdateGateway extends _NoopProductionGateway {
  String? table;
  String? onConflict;
  Map<String, Object?> values = const <String, Object?>{};

  @override
  Future<Map<String, Object?>> upsert(
    String table,
    Map<String, Object?> values, {
    String? onConflict,
  }) async {
    this.table = table;
    this.values = Map<String, Object?>.from(values);
    this.onConflict = onConflict;
    return values;
  }
}

class _StaticAuthGateway implements AssalAuthGateway {
  _StaticAuthGateway(this.identity);

  final AssalAuthIdentity? identity;

  @override
  Future<AssalAuthIdentity?> currentIdentity() async => identity;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _NoopProductionGateway implements ProductionQueryGateway {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _ThrowingRpcGateway extends _NoopProductionGateway {
  _ThrowingRpcGateway(this.error);

  final Object error;

  @override
  Future<Map<String, Object?>> rpc(
    String function,
    Map<String, Object?> params,
  ) async {
    throw error;
  }
}

class _RecordingFollowGateway extends _NoopProductionGateway {
  String? lastFunction;
  Map<String, Object?> lastParams = const <String, Object?>{};

  @override
  Future<Map<String, Object?>> rpc(
    String function,
    Map<String, Object?> params,
  ) async {
    lastFunction = function;
    lastParams = params;
    return const <String, Object?>{
      'following': true,
      'followers_count': 1,
    };
  }
}

class _FilterRowsProductionGateway implements ProductionQueryGateway {
  _FilterRowsProductionGateway(this.tables);

  final Map<String, List<Map<String, Object?>>> tables;
  final List<Map<String, Object?>> productFilters = [];

  @override
  Future<List<Map<String, Object?>>> select(
    String table, {
    Map<String, Object?> filters = const <String, Object?>{},
  }) async {
    final rows = tables[table] ?? const <Map<String, Object?>>[];
    if (table != 'customer_products') return rows;
    productFilters.add(Map<String, Object?>.from(filters));
    return rows
        .where(
          (row) => filters.entries.every(
            (entry) => row[entry.key] == entry.value,
          ),
        )
        .toList(growable: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _UploadRecordingGateway extends _NoopProductionGateway {
  final List<String> publicPaths = <String>[];
  final List<Map<String, Object?>> inserts = <Map<String, Object?>>[];
  bool failUpload = false;

  @override
  Future<List<Map<String, Object?>>> select(
    String table, {
    Map<String, Object?> filters = const <String, Object?>{},
  }) async {
    if (table == 'stores' && filters['id'] == 's1' && filters['merchant_id'] == 'u1') {
      return const <Map<String, Object?>>[
        {'id': 's1', 'merchant_id': 'u1'},
      ];
    }
    if (table == 'products' && filters['id'] == 'p1') {
      return const <Map<String, Object?>>[
        {'id': 'p1', 'store_id': 's1'},
      ];
    }
    return const <Map<String, Object?>>[];
  }

  @override
  Future<String> uploadPublicImage(
    String path,
    Uint8List bytes,
    String extension,
  ) async {
    publicPaths.add(path);
    if (failUpload) throw StateError('upload_failed');
    return 'https://cdn.example/$path';
  }

  @override
  Future<Map<String, Object?>> insert(
    String table,
    Map<String, Object?> values,
  ) async {
    inserts.add({'table': table, 'values': values});
    return values;
  }
}

class _RowsProductionGateway implements ProductionQueryGateway {
  _RowsProductionGateway(this.rows);

  final List<Map<String, Object?>> rows;

  @override
  Future<List<Map<String, Object?>>> select(
    String table, {
    Map<String, Object?> filters = const <String, Object?>{},
  }) async =>
      rows;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
