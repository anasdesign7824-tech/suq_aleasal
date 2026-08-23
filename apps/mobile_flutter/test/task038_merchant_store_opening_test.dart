import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_account.dart';
import 'package:assalkom/features/merchant/merchant_dashboard.dart';

const _user = AssalUserProfile(
  id: 'merchant-1',
  nameAr: 'تاجر عسلكم',
  email: 'merchant@example.com',
);

const _store = AssalStoreSummary(
  id: 'store-1',
  merchantId: 'merchant-1',
  nameAr: 'متجر العسل',
  slug: 'honey-store',
);

const _workspace = AssalMerchantWorkspaceSummary(
  store: _store,
  verificationStatus: 'pending',
  publicStatus: 'pending',
  canEdit: true,
  canPublish: false,
);

Future<void> _pumpOpening(
  WidgetTester tester,
  _MerchantOpeningRepository repository,
) async {
  tester.view.physicalSize = const Size(900, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: MerchantWorkspaceSetupScreen(repository: repository),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 038 renders merchant setup fields and pending policy',
      (tester) async {
    await _pumpOpening(tester, _MerchantOpeningRepository());

    expect(find.text('فتح مساحة المتجر'), findsOneWidget);
    expect(find.text('اسم النشاط أو المتجر'), findsOneWidget);
    expect(find.text('الخبرة (اختياري)'), findsOneWidget);
    expect(find.text('التخصصات (اختياري)'), findsOneWidget);
    expect(find.text('الموقع (اختياري)'), findsOneWidget);
    expect(find.textContaining('الحالة بعد الفتح: معلّق حتى تفعيل الإدارة.'),
        findsOneWidget);

    expect(find.text('حفظ البيانات مؤقتًا'), findsOneWidget);
    expect(find.text('فتح مساحة المتجر الآن'), findsOneWidget);
  });

  testWidgets('TASK 038 validates store name before opening', (tester) async {
    final repository = _MerchantOpeningRepository();
    await _pumpOpening(tester, repository);

    await tester.tap(find.text('فتح مساحة المتجر الآن'));
    await tester.pump();
    expect(find.text('اكتب اسم المتجر.'), findsOneWidget);
    expect(repository.openCalls, 0);
  });

  testWidgets('TASK 038 saves all supported application draft fields',
      (tester) async {
    final repository = _MerchantOpeningRepository();
    await _pumpOpening(tester, repository);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'متجر السدر');
    await tester.enterText(fields.at(3), 'خبرة طويلة في تجارة العسل');
    await tester.enterText(fields.at(4), 'سدر، سمرة');
    await tester.enterText(fields.at(5), 'متجر متخصص في العسل اليمني الأصلي.');
    await tester.tap(find.text('حفظ البيانات مؤقتًا'));
    await tester.pumpAndSettle();

    expect(repository.saveCalls, 1);
    expect(repository.lastDraft?.displayName, 'متجر السدر');
    expect(repository.lastDraft?.experience, 'خبرة طويلة في تجارة العسل');
    expect(repository.lastDraft?.specialties, 'سدر، سمرة');
    expect(repository.lastDraft?.storeDescription,
        'متجر متخصص في العسل اليمني الأصلي.');
  });

  testWidgets('TASK 038 opens the real merchant dashboard after source success',
      (tester) async {
    final repository = _MerchantOpeningRepository();
    await _pumpOpening(tester, repository);

    await tester.enterText(find.byType(TextFormField).first, 'متجر السدر');
    await tester.tap(find.text('فتح مساحة المتجر الآن'));
    await tester.pumpAndSettle();

    expect(repository.openCalls, 1);
    expect(find.byType(MerchantDashboard), findsOneWidget);
  });

  testWidgets('TASK 038 retries an unavailable initial session',
      (tester) async {
    final repository = _MerchantOpeningRepository(unavailableOnce: true);
    await _pumpOpening(tester, repository);

    expect(
        find.text('تعذر مزامنة جلسة الحساب. حاول مرة أخرى.'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('فتح مساحة المتجر الآن'), findsOneWidget);
    expect(repository.sessionCalls, 2);
  });

  testWidgets('TASK 038 keeps a guest behind the merchant auth gate',
      (tester) async {
    await _pumpOpening(
      tester,
      _MerchantOpeningRepository(authenticated: false),
    );

    expect(find.text('تسجيل الدخول لفتح متجرك'), findsOneWidget);
    expect(find.text('فتح مساحة المتجر الآن'), findsNothing);
  });

  testWidgets('TASK 038 records the visual contract', (tester) async {
    await _pumpOpening(tester, _MerchantOpeningRepository());
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MerchantWorkspaceSetupScreen),
      matchesGoldenFile(
        'visual_reference/task038_merchant_store_opening_reference_360x780.png',
      ),
    );
  });
}

class _MerchantOpeningRepository implements AssalRepository {
  _MerchantOpeningRepository({
    this.authenticated = true,
    this.unavailableOnce = false,
  });

  final bool authenticated;
  bool unavailableOnce;
  int sessionCalls = 0;
  int saveCalls = 0;
  int openCalls = 0;
  AssalMerchantApplicationDraft? lastDraft;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async {
    sessionCalls++;
    if (unavailableOnce) {
      unavailableOnce = false;
      return AssalSession.unavailable;
    }
    return authenticated
        ? const AssalSession(
            isAuthenticated: true,
            role: AssalRole.merchant,
            user: _user,
          )
        : AssalSession.guest;
  }

  @override
  Future<AssalLoadState<AssalMerchantApplicationDraft?>>
      loadMerchantApplicationDraft(String userId) async =>
          const AssalData<AssalMerchantApplicationDraft?>(null);

  @override
  Future<AssalLoadState<void>> saveMerchantApplicationDraft(
    String userId,
    AssalMerchantApplicationDraft draft,
  ) async {
    saveCalls++;
    lastDraft = draft;
    return const AssalData<void>(null);
  }

  @override
  Future<AssalLoadState<AssalMerchantWorkspaceSummary>> openMerchantWorkspace(
    String userId,
    AssalMerchantWorkspaceDraft draft,
  ) async {
    openCalls++;
    return const AssalData<AssalMerchantWorkspaceSummary>(_workspace);
  }

  @override
  Future<AssalLoadState<AssalMerchantWorkspaceSummary?>> loadMerchantWorkspace(
          String userId) async =>
      const AssalData<AssalMerchantWorkspaceSummary?>(_workspace);

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listMerchantProducts(
    String userId,
  ) async =>
      const AssalData(<AssalProductSummary>[]);

  @override
  Future<AssalLoadState<List<AssalRequestSummary>>> listMerchantRequests(
    String userId,
  ) async =>
      const AssalData(<AssalRequestSummary>[]);

  @override
  Future<AssalLoadState<List<AssalCommentSummary>>> listComments(
    String productId,
  ) async =>
      const AssalData(<AssalCommentSummary>[]);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
