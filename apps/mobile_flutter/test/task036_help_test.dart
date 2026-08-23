import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_support.dart';
import 'package:assalkom/core/assal_widgets.dart';

const _user = AssalUserProfile(
  id: 'customer-1',
  nameAr: 'محمد اليمني',
  email: 'mohammed@example.com',
);

Future<void> _pumpHelp(
  WidgetTester tester,
  _HelpRepository repository,
) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(home: HelpScreen(repository: repository)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 036 renders help categories and support route',
      (tester) async {
    await _pumpHelp(tester, _HelpRepository());

    expect(find.text('المساعدة'), findsOneWidget);
    expect(find.text('البحث في الأسئلة'), findsOneWidget);
    expect(find.text('الحساب والدخول'), findsOneWidget);
    expect(find.text('المتاجر والمنتجات'), findsOneWidget);
    expect(find.text('الطلبات والمراسلات'), findsOneWidget);
    expect(find.text('الصور والرفع'), findsOneWidget);
    expect(find.text('الخصوصية'), findsOneWidget);
    expect(find.text('التواصل مع الدعم'), findsNWidgets(2));
  });

  testWidgets('TASK 036 filters questions locally without a new data contract',
      (tester) async {
    await _pumpHelp(tester, _HelpRepository());

    await tester.enterText(find.byType(TextField), 'الطلبات');
    await tester.pump();
    expect(find.text('كيف أرسل طلبًا أو أتواصل مع التاجر؟'), findsOneWidget);
    expect(find.text('كيف أتابع المتجر أو أحفظ المنتج؟'), findsNothing);
  });

  testWidgets('TASK 036 expands a question with Arabic guidance',
      (tester) async {
    await _pumpHelp(tester, _HelpRepository());

    await tester.tap(find.text('كيف أرفع صورة للمتجر أو الملف الشخصي؟'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('اضغط زر الصورة الصغير داخل بطاقة الصورة'),
      findsOneWidget,
    );
  });

  testWidgets('TASK 036 opens the existing support route', (tester) async {
    await _pumpHelp(tester, _HelpRepository());

    await tester.tap(find.widgetWithText(AssalActionTile, 'التواصل مع الدعم'));
    await tester.pumpAndSettle();
    expect(find.byType(SupportCenterScreen), findsOneWidget);
  });

  testWidgets('TASK 036 retries an unavailable session source', (tester) async {
    final repository = _HelpRepository(unavailableOnce: true);
    await _pumpHelp(tester, repository);

    expect(
        find.text('تعذر مزامنة جلسة الحساب. حاول مرة أخرى.'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('البحث في الأسئلة'), findsOneWidget);
    expect(repository.sessionCalls, 2);
  });

  testWidgets('TASK 036 records the visual contract', (tester) async {
    await _pumpHelp(tester, _HelpRepository());
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(HelpScreen),
      matchesGoldenFile('visual_reference/task036_help_reference_360x780.png'),
    );
  });
}

class _HelpRepository implements AssalRepository {
  _HelpRepository({this.unavailableOnce = false});

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
    return const AssalSession(
      isAuthenticated: true,
      role: AssalRole.customer,
      user: _user,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
