import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom/features/customer/customer_account.dart';

void main() {
  testWidgets('profile guest state exposes login and support actions',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileScreen(repository: _ProfileRepository(AssalSession.guest)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تصفح كزائر'), findsOneWidget);
    expect(find.text('تسجيل الدخول أو إنشاء حساب'), findsOneWidget);
    expect(find.text('المساعدة والدعم'), findsOneWidget);
  });

  testWidgets('profile unavailable state is explicit and does not fake auth',
      (tester) async {
    const unavailable = AssalSession(
      isAuthenticated: false,
      role: AssalRole.guest,
      isUnavailable: true,
      errorMessageAr: 'تعذر مزامنة الحساب الآن.',
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileScreen(repository: _ProfileRepository(unavailable)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تعذر مزامنة الحساب الآن.'), findsOneWidget);
    expect(find.text('تصفح كزائر'), findsNothing);
    expect(find.text('تسجيل الدخول أو إنشاء حساب'), findsNothing);
  });

  testWidgets('authenticated profile renders header stats and role actions',
      (tester) async {
    const profile = AssalUserProfile(
      id: 'u1',
      nameAr: 'مستخدم عسلكم',
      email: 'user@example.com',
      bio: 'نبذة اختبارية',
      location: 'صنعاء',
      role: AssalRole.customer,
    );
    const session = AssalSession(
      isAuthenticated: true,
      role: AssalRole.customer,
      user: profile,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileScreen(repository: _ProfileRepository(session)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('نشاطك'),
      500,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('مستخدم عسلكم'), findsOneWidget);
    expect(find.text('نبذة اختبارية'), findsOneWidget);
    expect(find.text('صنعاء'), findsOneWidget);
    expect(find.text('نشاطك'), findsOneWidget);
    expect(find.text('الحساب والمساعدة'), findsOneWidget);
    expect(find.text('المتابعات'), findsOneWidget);
    expect(find.text('المحفوظات'), findsOneWidget);
    expect(find.text('الطلبات'), findsOneWidget);
    expect(find.text('طلباتي'), findsOneWidget);
    expect(find.text('مساحة المتجر'), findsOneWidget);
    expect(find.text('تسجيل الخروج'), findsOneWidget);
  });
}

class _ProfileRepository implements AssalRepository {
  const _ProfileRepository(this.session);

  final AssalSession session;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => session;

  @override
  Future<AssalLoadState<List<AssalStoreSummary>>> listFollowedStores(
    String userId,
  ) async => const AssalEmpty<List<AssalStoreSummary>>('لا توجد متابعات');

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listFavoriteProducts(
    String userId,
  ) async => const AssalEmpty<List<AssalProductSummary>>('لا توجد محفوظات');

  @override
  Future<AssalLoadState<List<AssalRequestSummary>>> listRequests(
    String requesterId,
  ) async => const AssalEmpty<List<AssalRequestSummary>>('لا توجد طلبات');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
