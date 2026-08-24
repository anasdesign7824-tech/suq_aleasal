import 'package:assalkom/features/customer/customer_favorites.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sessionUser = AssalUserProfile(
  id: 'customer-077',
  nameAr: 'عميل الجلسة',
  role: AssalRole.customer,
);

class _RecoveringSessionRepository implements AssalRepository {
  int sessionCalls = 0;

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async {
    sessionCalls += 1;
    return sessionCalls == 1
        ? AssalSession.unavailable
        : const AssalSession(
            isAuthenticated: true,
            role: AssalRole.customer,
            user: _sessionUser,
          );
  }

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listFavoriteProducts(
    String userId,
  ) async => const AssalEmpty<List<AssalProductSummary>>('لم تحفظ شيئًا بعد.');

  @override
  Future<AssalLoadState<List<AssalStoreSummary>>> listFollowedStores(
    String userId,
  ) async => const AssalEmpty<List<AssalStoreSummary>>('لا تتابع متاجر بعد.');

  @override
  Future<AssalLoadState<List<AssalTaxonomy>>> listFavoriteTaxonomies(
    String userId,
  ) async => const AssalEmpty<List<AssalTaxonomy>>('لا توجد تصنيفات مرتبطة.');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  testWidgets('TASK 077 keeps unavailable session distinct and retryable',
      (tester) async {
    final repository = _RecoveringSessionRepository();
    await tester.pumpWidget(
      MaterialApp(home: FavoritesScreen(repository: repository)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.text('تعذر مزامنة جلسة الحساب. حاول مرة أخرى.'),
      findsOneWidget,
    );
    expect(find.text('تسجيل الدخول لعرض محفوظاتك'), findsNothing);
    expect(find.text('إعادة المحاولة'), findsOneWidget);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(repository.sessionCalls, 2);
    expect(find.text('لم تحفظ شيئًا بعد.'), findsOneWidget);
    expect(find.text('تسجيل الدخول لعرض محفوظاتك'), findsNothing);
  });
}
