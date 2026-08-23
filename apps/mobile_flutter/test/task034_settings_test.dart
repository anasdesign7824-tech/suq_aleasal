import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_account.dart';

const _user = AssalUserProfile(
  id: 'customer-1',
  nameAr: 'محمد اليمني',
  email: 'mohammed@example.com',
  phone: '+967700000000',
);

Future<void> _pumpSettings(
  WidgetTester tester,
  _SettingsRepository repository,
) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(home: SettingsScreen(repository: repository)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'TASK 034 renders account, privacy, notification and security groups',
      (tester) async {
    await _pumpSettings(tester, _SettingsRepository());

    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('محمد اليمني'), findsOneWidget);
    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('+967700000000'), findsOneWidget);
    expect(find.text('الخصوصية'), findsOneWidget);
    expect(find.text('إظهار الاسم العام'), findsOneWidget);
    expect(find.text('إظهار الصورة العامة'), findsOneWidget);
    expect(find.text('إعدادات المتابعين'), findsOneWidget);
    expect(find.text('إشعارات الطلبات'), findsOneWidget);
    expect(find.text('إشعارات الرسائل'), findsOneWidget);
    expect(find.text('إشعارات التفاعل'), findsOneWidget);
    expect(find.text('الأمان'), findsNWidgets(2));
    expect(find.text('تسجيل الخروج'), findsOneWidget);
    expect(find.text('حذف الحساب'), findsOneWidget);
    expect(find.text('حفظ الإعدادات'), findsOneWidget);
  });

  testWidgets('TASK 034 updates local preferences and reports truthful scope',
      (tester) async {
    await _pumpSettings(tester, _SettingsRepository());

    final switches = find.byType(SwitchListTile);
    expect(switches, findsNWidgets(6));
    await tester.tap(switches.first);
    await tester.tap(find.text('حفظ الإعدادات'));
    await tester.pump();

    expect(find.textContaining('تم حفظ تفضيلات هذه الجلسة'), findsOneWidget);
    expect(find.textContaining('لا يوجد عقد مزامنة دائم'), findsOneWidget);
  });

  testWidgets('TASK 034 opens the existing notifications route',
      (tester) async {
    await _pumpSettings(tester, _SettingsRepository());

    await tester.tap(find.widgetWithText(ListTile, 'الإشعارات'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(find.text('لا توجد إشعارات جديدة الآن.'), findsOneWidget);
  });

  testWidgets('TASK 034 keeps guest settings behind the auth gate',
      (tester) async {
    await _pumpSettings(
      tester,
      _SettingsRepository(authenticated: false),
    );

    expect(find.text('تسجيل الدخول لإدارة الإعدادات'), findsOneWidget);
    expect(find.text('إظهار الاسم العام'), findsNothing);
  });

  testWidgets('TASK 034 retries an unavailable session source', (tester) async {
    final repository = _SettingsRepository(unavailableOnce: true);
    await _pumpSettings(tester, repository);

    expect(
        find.text('تعذر مزامنة جلسة الحساب. حاول مرة أخرى.'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('محمد اليمني'), findsOneWidget);
    expect(repository.sessionCalls, 2);
  });

  testWidgets('TASK 034 records the visual contract', (tester) async {
    await _pumpSettings(tester, _SettingsRepository());
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile(
        'visual_reference/task034_settings_reference_360x780.png',
      ),
    );
  });
}

class _SettingsRepository implements AssalRepository {
  _SettingsRepository({
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
  Future<AssalLoadState<void>> signOut() async => const AssalData<void>(null);

  @override
  Future<AssalLoadState<void>> deleteAccount() async =>
      const AssalData<void>(null);

  @override
  Future<AssalLoadState<List<AssalNotificationSummary>>> listNotifications(
    String userId,
  ) async =>
      const AssalData(<AssalNotificationSummary>[]);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
