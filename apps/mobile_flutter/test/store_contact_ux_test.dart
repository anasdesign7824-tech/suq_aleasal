import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';

import 'package:assalkom/features/customer/customer_catalog.dart';

void main() {
  testWidgets('store contact action reports conversation failure',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: StoreProfileScreen(
          repository: _FailingConversationRepository(),
          storeId: 'store-1',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('التواصل'));
    await tester.tap(find.text('التواصل'));
    await tester.pumpAndSettle();
    final action = find.text('مراسلة التاجر');
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.text('فشل فتح المحادثة من الخادم'), findsOneWidget);
    expect(find.text('مراسلة التاجر'), findsOneWidget);
  });
}

class _FailingConversationRepository implements AssalRepository {
  const _FailingConversationRepository();

  static const _store = AssalStoreSummary(
    id: 'store-1',
    merchantId: 'merchant-1',
    nameAr: 'متجر العسل',
    slug: 'honey-store',
    status: StoreStatus.active,
  );

  @override
  AssalDataSourceMode get mode => AssalDataSourceMode.demo;

  @override
  Future<AssalSession> getSession() async => const AssalSession(
        isAuthenticated: true,
        role: AssalRole.customer,
        user: AssalUserProfile(
          id: 'customer-1',
          nameAr: 'عميل عسلكم',
          role: AssalRole.customer,
        ),
      );

  @override
  Future<AssalLoadState<AssalStoreSummary>> getStore(String storeId) async =>
      const AssalData(_store);

  @override
  Future<AssalLoadState<List<AssalStoreSummary>>> listFollowedStores(
    String userId,
  ) async => const AssalData(<AssalStoreSummary>[]);

  @override
  Future<AssalLoadState<List<AssalProductSummary>>> listProducts({
    AssalProductQuery query = const AssalProductQuery(),
  }) async => const AssalData(<AssalProductSummary>[]);

  @override
  Future<AssalLoadState<AssalConversationSummary>> createConversation(
    String userId,
    String storeId,
  ) async => const AssalError<AssalConversationSummary>(
        'فشل فتح المحادثة من الخادم',
        code: 'conversation_failed',
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
