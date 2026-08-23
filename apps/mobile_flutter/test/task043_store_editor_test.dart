import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/merchant/merchant_dashboard.dart';

class _StoreEditorRepository implements AssalRepository {
  _StoreEditorRepository({this.regionsErrorOnce = false});

  static const profile = AssalUserProfile(
    id: 'merchant-1',
    nameAr: 'تاجر الاختبار',
    role: AssalRole.merchant,
  );
  static const session = AssalSession(
    isAuthenticated: true,
    role: AssalRole.merchant,
    user: profile,
  );
  static const store = AssalStoreSummary(
    id: 'store-1',
    merchantId: 'merchant-1',
    nameAr: 'متجر السدر',
    slug: 'sidr-store',
    description: 'عسل يمني طبيعي.',
    regionId: 'district-1',
    regionNameAr: 'مديرية حدة',
    galleryUrls: <String>['https://example.com/gallery.jpg'],
    socialLinks: <String, String>{'whatsapp': 'https://wa.me/967700000000'},
    deliveryOptions: <String>['delivery'],
    pickupLocations: <String>['فرع حدة'],
    contactPhone: '700000000',
    yearsExperience: 8,
    specialties: <String>['عسل سدر', 'عسل سمرة'],
    status: StoreStatus.pending,
  );
  static const workspace = AssalMerchantWorkspaceSummary(
    store: store,
    verificationStatus: 'pending',
    publicStatus: 'pending',
    canEdit: true,
    canPublish: false,
  );
  static const regions = <AssalRegion>[
    AssalRegion(id: 'governorate-1', nameAr: 'أمانة العاصمة'),
    AssalRegion(
      id: 'district-1',
      nameAr: 'مديرية حدة',
      parentRegionId: 'governorate-1',
    ),
  ];

  final bool regionsErrorOnce;
  int regionCalls = 0;
  int updateCalls = 0;
  int channelsCalls = 0;
  AssalMerchantWorkspaceDraft? workspaceDraft;
  AssalStoreChannelsDraft? channelsDraft;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => session;

  @override
  Future<AssalLoadState<List<AssalRegion>>> listRegions() async {
    regionCalls++;
    if (regionsErrorOnce && regionCalls == 1) {
      return const AssalError<List<AssalRegion>>(
        'تعذر تحميل المناطق الآن',
        code: 'regions_failed',
      );
    }
    return const AssalData(regions);
  }

  @override
  Future<AssalLoadState<void>> updateMerchantWorkspace(
    String userId,
    String storeId,
    AssalMerchantWorkspaceDraft draft,
  ) async {
    updateCalls++;
    workspaceDraft = draft;
    return const AssalData<void>(null);
  }

  @override
  Future<AssalLoadState<AssalStoreSummary>> saveMerchantStoreChannels(
    String userId,
    String storeId,
    AssalStoreChannelsDraft draft,
  ) async {
    channelsCalls++;
    channelsDraft = draft;
    return const AssalData<AssalStoreSummary>(store);
  }

  @override
  Future<AssalLoadState<String>> uploadMerchantImage(
    String userId,
    String kind,
    List<int> bytes,
    String extension,
  ) async =>
      const AssalData('https://example.com/uploaded.jpg');

  @override
  Future<AssalLoadState<String>> uploadStoreGalleryImage(
    String userId,
    String storeId,
    List<int> bytes,
    String extension,
  ) async =>
      const AssalData('https://example.com/gallery-new.jpg');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

Future<void> _pumpEditor(
  WidgetTester tester,
  _StoreEditorRepository repository, {
  bool canEdit = true,
}) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final workspace = canEdit
      ? _StoreEditorRepository.workspace
      : const AssalMerchantWorkspaceSummary(
          store: _StoreEditorRepository.store,
          verificationStatus: 'pending',
          publicStatus: 'pending',
          canEdit: false,
        );
  await tester.pumpWidget(
    MaterialApp(
      home: MerchantStoreEditorScreen(
        repository: repository,
        workspace: workspace,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 043 renders store fields, channels and source details',
      (tester) async {
    await _pumpEditor(tester, _StoreEditorRepository());

    expect(find.text('تعديل مساحة المتجر'), findsOneWidget);
    expect(find.text('اسم المتجر'), findsOneWidget);
    expect(find.text('وصف المتجر'), findsOneWidget);
    expect(find.text('محافظة المتجر'), findsOneWidget);
    expect(find.text('مديرية المتجر'), findsOneWidget);
    expect(find.text('التواصل والتسليم'), findsOneWidget);
    expect(find.text('طرق التسليم المتاحة'), findsOneWidget);
    expect(find.text('الخبرة والتخصصات'), findsOneWidget);
    expect(find.textContaining('8 سنوات خبرة'), findsOneWidget);
    expect(find.textContaining('عسل سدر'), findsOneWidget);
    expect(find.text('صور المعرض'), findsOneWidget);
    expect(find.textContaining('حذف صورة محفوظة يحتاج عقد حذف مستقل'),
        findsOneWidget);
  });

  testWidgets('TASK 043 validates channel URLs before saving', (tester) async {
    final repository = _StoreEditorRepository();
    await _pumpEditor(tester, repository);
    await tester.enterText(
      find.byKey(const ValueKey('merchant-whatsapp-url')),
      'wa.me/not-a-url',
    );
    await tester.tap(find.byKey(const ValueKey('merchant-store-save')));
    await tester.pump();

    expect(find.textContaining('يجب أن يبدأ بـ http:// أو https://'),
        findsOneWidget);
    expect(repository.updateCalls, 0);
    expect(repository.channelsCalls, 0);
  });

  testWidgets('TASK 043 saves workspace and channels through real contracts',
      (tester) async {
    final repository = _StoreEditorRepository();
    await _pumpEditor(tester, repository);
    await tester.enterText(
      find.byKey(const ValueKey('merchant-whatsapp-url')),
      'https://wa.me/967700000000',
    );
    await tester.tap(find.text('توصيل التاجر'));
    await tester.enterText(find.byType(TextField).last, 'فرع التحرير');
    await tester.tap(find.byTooltip('إضافة نقطة الاستلام'));
    await tester.tap(find.byKey(const ValueKey('merchant-store-save')));
    await tester.pumpAndSettle();

    expect(repository.updateCalls, 1);
    expect(repository.channelsCalls, 1);
    expect(repository.workspaceDraft?.businessName, 'متجر السدر');
    expect(repository.channelsDraft?.socialLinks['whatsapp'],
        'https://wa.me/967700000000');
    expect(
        repository.channelsDraft?.deliveryCodes, contains('merchant_delivery'));
    expect(repository.channelsDraft?.pickupLocations, contains('فرع التحرير'));
  });

  testWidgets('TASK 043 retries region source errors', (tester) async {
    final repository = _StoreEditorRepository(regionsErrorOnce: true);
    await _pumpEditor(tester, repository);

    expect(find.text('تعذر تحميل المناطق الآن'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('محافظة المتجر'), findsOneWidget);
    expect(repository.regionCalls, greaterThanOrEqualTo(2));
  });

  testWidgets('TASK 043 disables editing when workspace permission is absent',
      (tester) async {
    final repository = _StoreEditorRepository();
    await _pumpEditor(tester, repository, canEdit: false);

    final saveButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('merchant-store-save')),
    );
    expect(saveButton.onPressed, isNull);
    expect(find.text('هذه المساحة للعرض فقط؛ لا تملك صلاحية تعديلها.'),
        findsOneWidget);
    expect(repository.updateCalls, 0);
  });

  testWidgets('TASK 043 records the visual contract', (tester) async {
    await _pumpEditor(tester, _StoreEditorRepository());
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MerchantStoreEditorScreen),
      matchesGoldenFile(
          'visual_reference/task043_store_editor_reference_360x780.png'),
    );
  });
}
