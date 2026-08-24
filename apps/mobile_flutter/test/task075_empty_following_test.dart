import 'package:assalkom/features/customer/customer_favorites.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _followingUser = AssalUserProfile(
  id: 'customer-075',
  nameAr: 'عميل المتابعات',
  role: AssalRole.customer,
);

class _EmptyFollowingRepository implements AssalRepository {
  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => const AssalSession(
        isAuthenticated: true,
        role: AssalRole.customer,
        user: _followingUser,
      );

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
  testWidgets('TASK 075 renders empty following state with discover action',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FavoritesScreen(
          repository: _EmptyFollowingRepository(),
          initialTab: 1,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('المحفوظات والمتابعات'), findsOneWidget);
    expect(find.text('متاجر متابَعة'), findsOneWidget);
    expect(find.text('لا تتابع متاجر بعد.'), findsOneWidget);
    expect(find.text('اكتشف المتاجر'), findsOneWidget);
    expect(find.text('تسجيل الدخول لعرض محفوظاتك'), findsNothing);
  });
}
