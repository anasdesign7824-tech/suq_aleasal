import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_account.dart';

const _user = AssalUserProfile(
  id: 'customer-1',
  nameAr: 'محمد اليمني',
  email: 'mohammed@example.com',
);

Future<void> _pumpNotifications(
  WidgetTester tester,
  _NotificationsRepository repository,
) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(home: NotificationsScreen(repository: repository)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TASK 033 renders source notifications and read action',
      (tester) async {
    await _pumpNotifications(tester, _NotificationsRepository());

    expect(find.text('الإشعارات'), findsOneWidget);
    expect(find.text('وصلت رسالة جديدة'), findsOneWidget);
    expect(find.text('تم تحديث حالة طلبك'), findsOneWidget);
    expect(find.text('تحديد الكل كمقروء'), findsOneWidget);
    expect(find.text('جديد'), findsNWidgets(2));
  });

  testWidgets('TASK 033 marks one notification and reloads the source',
      (tester) async {
    final repository = _NotificationsRepository();
    await _pumpNotifications(tester, repository);

    await tester.tap(find.text('وصلت رسالة جديدة'));
    await tester.pumpAndSettle();

    expect(repository.markedIds, ['notification-1']);
    expect(repository.listCalls, 2);
    expect(find.text('تم تعليم الإشعار كمقروء.'), findsOneWidget);
    expect(find.text('تحديد الكل كمقروء'), findsOneWidget);
  });

  testWidgets(
      'TASK 033 marks all unread notifications through existing contract',
      (tester) async {
    final repository = _NotificationsRepository();
    await _pumpNotifications(tester, repository);

    await tester.tap(find.text('تحديد الكل كمقروء'));
    await tester.pumpAndSettle();

    expect(repository.markedIds, ['notification-1', 'notification-2']);
    expect(repository.listCalls, 2);
    expect(find.text('تم تحديد الإشعارات كمقروءة.'), findsOneWidget);
    expect(find.text('تحديد الكل كمقروء'), findsNothing);
    expect(find.text('لا توجد إشعارات جديدة الآن.'), findsNothing);
  });

  testWidgets('TASK 033 keeps guest notifications behind the auth gate',
      (tester) async {
    await _pumpNotifications(
      tester,
      _NotificationsRepository(authenticated: false),
    );

    expect(find.text('تسجيل الدخول لعرض إشعاراتك'), findsOneWidget);
    expect(find.text('وصلت رسالة جديدة'), findsNothing);
  });

  testWidgets('TASK 033 retries an unavailable session source', (tester) async {
    final repository = _NotificationsRepository(unavailableOnce: true);
    await _pumpNotifications(tester, repository);

    expect(
        find.text('تعذر مزامنة جلسة الحساب. حاول مرة أخرى.'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('وصلت رسالة جديدة'), findsOneWidget);
    expect(repository.sessionCalls, 2);
  });

  testWidgets('TASK 033 records the visual contract', (tester) async {
    await _pumpNotifications(tester, _NotificationsRepository());
    tester.view.physicalSize = const Size(1440, 3120);
    tester.view.devicePixelRatio = 4;
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(NotificationsScreen),
      matchesGoldenFile(
        'visual_reference/task033_notifications_reference_360x780.png',
      ),
    );
  });
}

class _NotificationsRepository implements AssalRepository {
  _NotificationsRepository({
    this.authenticated = true,
    this.unavailableOnce = false,
  });

  final bool authenticated;
  bool unavailableOnce;
  int sessionCalls = 0;
  int listCalls = 0;
  final List<String> markedIds = <String>[];

  List<AssalNotificationSummary> items = <AssalNotificationSummary>[
    const AssalNotificationSummary(
      id: 'notification-1',
      userId: 'customer-1',
      notificationType: 'message',
      titleAr: 'وصلت رسالة جديدة',
      bodyAr: 'لديك رسالة جديدة من المتجر.',
    ),
    const AssalNotificationSummary(
      id: 'notification-2',
      userId: 'customer-1',
      notificationType: 'request',
      titleAr: 'تم تحديث حالة طلبك',
      bodyAr: 'راجع تفاصيل طلبك لمعرفة آخر تحديث.',
    ),
  ];

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
  Future<AssalLoadState<List<AssalNotificationSummary>>> listNotifications(
    String userId,
  ) async {
    listCalls++;
    return AssalData<List<AssalNotificationSummary>>(List.unmodifiable(items));
  }

  @override
  Future<AssalLoadState<bool>> markNotificationRead(
    String userId,
    String notificationId,
  ) async {
    markedIds.add(notificationId);
    final index = items.indexWhere((item) => item.id == notificationId);
    if (index >= 0) {
      final old = items[index];
      items[index] = AssalNotificationSummary(
        id: old.id,
        userId: old.userId,
        notificationType: old.notificationType,
        titleAr: old.titleAr,
        bodyAr: old.bodyAr,
        payload: old.payload,
        readAt: DateTime(2026, 8, 23),
      );
    }
    return const AssalData<bool>(true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
