import 'package:assalkom/features/customer/customer_account.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _notificationUser = AssalUserProfile(
  id: 'customer-073',
  nameAr: 'عميل الإشعارات',
  role: AssalRole.customer,
);

class _EmptyNotificationsRepository implements AssalRepository {
  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => const AssalSession(
        isAuthenticated: true,
        role: AssalRole.customer,
        user: _notificationUser,
      );

  @override
  Future<AssalLoadState<List<AssalNotificationSummary>>> listNotifications(
    String userId,
  ) async =>
      const AssalEmpty<List<AssalNotificationSummary>>(
        'لا توجد إشعارات جديدة الآن.',
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  testWidgets('TASK 073 renders actionable empty notifications', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(repository: _EmptyNotificationsRepository()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('الإشعارات'), findsOneWidget);
    expect(find.text('لا توجد إشعارات جديدة الآن.'), findsOneWidget);
    expect(find.text('استكشف السوق'), findsOneWidget);
    expect(find.text('تسجيل الدخول لعرض إشعاراتك'), findsNothing);
  });
}
