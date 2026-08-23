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

Future<void> _pumpSupport(
  WidgetTester tester,
  _SupportRepository repository,
) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(home: SupportCenterScreen(repository: repository)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 035 renders support form and previous-requests boundary',
      (tester) async {
    await _pumpSupport(tester, _SupportRepository());

    expect(find.text('الدعم الفني'), findsOneWidget);
    expect(find.text('مركز المساعدة'), findsOneWidget);
    expect(find.text('موضوع الطلب'), findsOneWidget);
    expect(find.text('تفاصيل المشكلة'), findsOneWidget);
    expect(find.text('إرفاق صورة أو مستند'), findsOneWidget);
    expect(find.text('إرسال طلب الدعم'), findsNWidgets(2));
    expect(find.text('طلبات الدعم السابقة'), findsOneWidget);
    expect(
        find.text('لا يمكن عرض طلبات الدعم السابقة قبل توفر عقد خدمة الدعم.'),
        findsOneWidget);
  });

  testWidgets('TASK 035 validates support subject and details', (tester) async {
    await _pumpSupport(tester, _SupportRepository());

    await tester.tap(find.widgetWithText(FilledButton, 'إرسال طلب الدعم'));
    await tester.pump();
    expect(find.text('أدخل موضوع الطلب'), findsOneWidget);
    expect(find.text('اكتب تفاصيل لا تقل عن عشرة أحرف'), findsOneWidget);
  });

  testWidgets('TASK 035 reports the missing support-ticket contract honestly',
      (tester) async {
    await _pumpSupport(tester, _SupportRepository());

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'مشكلة في المزامنة');
    await tester.enterText(
      fields.at(1),
      'تظهر رسالة خطأ عند محاولة تحديث بيانات الحساب.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'إرسال طلب الدعم'));
    await tester.pump();
    expect(
      find.textContaining('إرسال تذكرة الدعم ورفع المرفقات غير متاحين بعد'),
      findsOneWidget,
    );

    await tester.tap(find.text('إرفاق صورة أو مستند'));
    await tester.pump();
    expect(
      find.textContaining('إرسال تذكرة الدعم ورفع المرفقات غير متاحين بعد'),
      findsOneWidget,
    );
  });

  testWidgets('TASK 035 keeps guest support behind the session gate',
      (tester) async {
    await _pumpSupport(tester, _SupportRepository(authenticated: false));

    expect(find.text('تسجيل الدخول للتواصل مع الدعم'), findsOneWidget);
    expect(find.text('موضوع الطلب'), findsNothing);
  });

  testWidgets('TASK 035 retries an unavailable session source', (tester) async {
    final repository = _SupportRepository(unavailableOnce: true);
    await _pumpSupport(tester, repository);

    expect(
        find.text('تعذر مزامنة جلسة الحساب. حاول مرة أخرى.'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('موضوع الطلب'), findsOneWidget);
    expect(repository.sessionCalls, 2);
  });

  testWidgets('TASK 035 records the visual contract', (tester) async {
    await _pumpSupport(tester, _SupportRepository());
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(SupportCenterScreen),
      matchesGoldenFile(
        'visual_reference/task035_support_reference_360x780.png',
      ),
    );
  });
}

class _SupportRepository implements AssalRepository {
  _SupportRepository({
    this.authenticated = true,
    this.unavailableOnce = false,
  });

  final bool authenticated;
  bool unavailableOnce;
  int sessionCalls = 0;

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
            role: AssalRole.customer,
            user: _user,
          )
        : AssalSession.guest;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
