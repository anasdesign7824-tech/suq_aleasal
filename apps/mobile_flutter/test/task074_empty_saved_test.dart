import 'package:assalkom/features/customer/customer_favorites.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _savedUser = AssalUserProfile(
  id: 'customer-074',
  nameAr: 'عميل المحفوظات',
  role: AssalRole.customer,
);

class _EmptySavedRepository implements AssalRepository {
  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => const AssalSession(
        isAuthenticated: true,
        role: AssalRole.customer,
        user: _savedUser,
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
  Future<AssalLoadState<List<AssalStoreSummary>>> listStores({
    String? regionId,
  }) async => const AssalEmpty<List<AssalStoreSummary>>(
        'لا توجد متاجر متاحة الآن.',
      );

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({
    AssalProductQuery query = const AssalProductQuery(),
  }) async => const AssalEmpty<List<AssalProductSummary>>(
        'لا توجد منتجات مطابقة.',
      );

  @override
  Future<AssalLoadState<List<AssalTaxonomy>>> listFavoriteTaxonomies(
    String userId,
  ) async => const AssalEmpty<List<AssalTaxonomy>>(
        'لا توجد تصنيفات مرتبطة بالمحفوظات بعد.',
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  testWidgets('TASK 074 renders actionable empty saved taxonomy state',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FavoritesScreen(
          repository: _EmptySavedRepository(),
          initialTab: 2,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('المحفوظات والمتابعات'), findsOneWidget);
    expect(
      find.text(
        'لا توجد تصنيفات مرتبطة بالمحفوظات بعد. احفظ منتجًا لاقتراح تصنيفاته.',
      ),
      findsOneWidget,
    );
    expect(find.text('استكشف المنتجات'), findsOneWidget);

  });
}
