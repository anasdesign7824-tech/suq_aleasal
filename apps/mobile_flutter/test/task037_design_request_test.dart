import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_support.dart';

const _user = AssalUserProfile(
  id: 'customer-1',
  nameAr: 'محمد اليمني',
  email: 'mohammed@example.com',
);

Future<void> _pumpRequest(
  WidgetTester tester,
  _DesignRepository repository,
) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: DesignRequestScreen(
        repository: repository,
        storeId: 'store-1',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 037 renders all contract fields and truthful boundaries',
      (tester) async {
    await _pumpRequest(tester, _DesignRepository());

    expect(find.text('طلب تصميم إضافي'), findsOneWidget);
    expect(find.text('عنوان الطلب'), findsOneWidget);
    expect(find.text('وصف المطلوب'), findsOneWidget);
    expect(find.text('اسم العلامة التجارية (اختياري)'), findsOneWidget);
    expect(find.text('الألوان المفضلة (اختياري)'), findsOneWidget);
    expect(find.text('نطاق التصميم (اختياري)'), findsOneWidget);
    expect(find.text('رفع مرجع أو ملف'), findsOneWidget);
    expect(find.text('إرسال طلب التصميم'), findsOneWidget);
    expect(
      find.text('الطلبات السابقة ستظهر عند توفر عقد قراءة سجل طلبات التصميم.'),
      findsOneWidget,
    );
  });

  testWidgets('TASK 037 validates title and description before save',
      (tester) async {
    final repository = _DesignRepository();
    await _pumpRequest(tester, repository);

    await tester.tap(find.widgetWithText(FilledButton, 'إرسال طلب التصميم'));
    await tester.pump();
    expect(find.text('أدخل عنوانًا واضحًا للطلب'), findsOneWidget);
    expect(find.text('اكتب وصفًا لا يقل عن عشرة أحرف'), findsOneWidget);
    expect(repository.createCalls, 0);
  });

  testWidgets('TASK 037 sends the supported draft including product scope',
      (tester) async {
    final repository = _DesignRepository();
    await _pumpRequest(tester, repository);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'هوية متجر جديدة');
    await tester.enterText(
      fields.at(1),
      'تصميم شعار وعبوة بلمسة عسلية واضحة للمتجر.',
    );
    await tester.enterText(fields.at(2), 'ذهبي، كريمي');
    await tester.enterText(fields.at(3), 'شعار وعبوة');
    await tester.tap(find.widgetWithText(FilledButton, 'إرسال طلب التصميم'));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(repository.lastDraft?.title, 'هوية متجر جديدة');
    expect(repository.lastDraft?.productScope['scope'], 'شعار وعبوة');
    expect(find.text('تم إرسال طلب التصميم، وسيظهر لك بعد مراجعته.'),
        findsNothing);
  });

  testWidgets('TASK 037 reports reference-upload contract boundary',
      (tester) async {
    await _pumpRequest(tester, _DesignRepository());

    await tester.tap(find.text('رفع مرجع أو ملف'));
    await tester.pump();
    expect(
      find.text('رفع مرجع أو ملف غير متاح حاليًا ضمن عقد التطبيق.'),
      findsOneWidget,
    );
  });

  testWidgets('TASK 037 keeps unavailable session explicit on submit',
      (tester) async {
    final repository = _DesignRepository(unavailable: true);
    await _pumpRequest(tester, repository);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'هوية متجر جديدة');
    await tester.enterText(
      fields.at(1),
      'تصميم شعار وعبوة بلمسة عسلية واضحة للمتجر.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'إرسال طلب التصميم'));
    await tester.pumpAndSettle();
    expect(
        find.text('تعذر مزامنة جلسة الحساب. حاول مرة أخرى.'), findsOneWidget);
    expect(repository.createCalls, 0);
  });

  testWidgets('TASK 037 records the visual contract', (tester) async {
    await _pumpRequest(tester, _DesignRepository());
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(DesignRequestScreen),
      matchesGoldenFile(
        'visual_reference/task037_design_request_reference_360x780.png',
      ),
    );
  });
}

class _DesignRepository implements AssalRepository {
  _DesignRepository({this.unavailable = false});

  final bool unavailable;
  int createCalls = 0;
  AssalDesignRequestDraft? lastDraft;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => unavailable
      ? AssalSession.unavailable
      : const AssalSession(
          isAuthenticated: true,
          role: AssalRole.customer,
          user: _user,
        );

  @override
  Future<AssalLoadState<AssalDesignRequest>> createDesignRequest(
    String userId,
    String storeId,
    AssalDesignRequestDraft draft,
  ) async {
    createCalls++;
    lastDraft = draft;
    return const AssalData<AssalDesignRequest>(
      AssalDesignRequest(
        id: 'design-1',
        storeId: 'store-1',
        title: 'هوية متجر جديدة',
        description: 'تصميم شعار وعبوة بلمسة عسلية واضحة للمتجر.',
        status: 'submitted',
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
