import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/demo_repository.dart';

import 'package:assalkom/features/merchant/merchant_dashboard.dart';

const _workspace = AssalMerchantWorkspaceSummary(
  store: AssalStoreSummary(
    id: 'store-1',
    merchantId: 'merchant-1',
    nameAr: 'متجر الاختبار',
    slug: 'test-store',
    description: 'متجر تجريبي',
    socialLinks: {'whatsapp': 'https://wa.me/967711111111'},
    deliveryOptions: ['شركة توصيل'],
    pickupLocations: ['نقطة قديمة'],
    contactWhatsapp: 'https://wa.me/967711111111',
  ),
  verificationStatus: 'pending',
  publicStatus: 'pending',
);

void main() {
  testWidgets('merchant editor exposes structured channel and delivery fields',
      (tester) async {
    final repository = DemoRepository(
      loader: const InMemoryDemoCatalogLoader('{}'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MerchantStoreEditorScreen(
          repository: repository,
          workspace: _workspace,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('التواصل والتسليم'),
      500,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('التواصل والتسليم'), findsOneWidget);
    expect(find.text('رابط واتساب'), findsOneWidget);
    expect(find.text('رابط تيليجرام'), findsOneWidget);
    expect(find.text('الموقع الإلكتروني'), findsOneWidget);
    expect(find.text('شركة توصيل'), findsOneWidget);
    expect(find.text('استلام من المتجر'), findsOneWidget);
    expect(find.text('نقطة استلام جديدة'), findsOneWidget);
    expect(find.text('نقطة قديمة'), findsOneWidget);
  });

  testWidgets('merchant editor rejects non-http channel URLs before save',
      (tester) async {
    final repository = DemoRepository(
      loader: const InMemoryDemoCatalogLoader('{}'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MerchantStoreEditorScreen(
          repository: repository,
          workspace: _workspace,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('merchant-whatsapp-url')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('merchant-whatsapp-url')),
      'wa.me/invalid',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('merchant-store-save')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('merchant-store-save')));
    await tester.pump();

    expect(
      find.text('رابط واتساب يجب أن يبدأ بـ http:// أو https://.'),
      findsOneWidget,
    );
  });

  test('demo repository stores structured channels without duplicating lists',
      () async {
    final repository = DemoRepository(
      loader: const InMemoryDemoCatalogLoader('{}'),
    );
    final registered = await repository.register(
      'تاجر الاختبار',
      'merchant@example.com',
      'password',
    );
    final session = (registered as AssalData<AssalSession>).value;
    final opened = await repository.openMerchantWorkspace(
      session.user!.id,
      const AssalMerchantWorkspaceDraft(businessName: 'متجر الاختبار'),
    );
    final workspace = (opened as AssalData<AssalMerchantWorkspaceSummary>).value;

    const draft = AssalStoreChannelsDraft(
      socialLinks: {
        'whatsapp': 'https://wa.me/967711111111',
        'telegram': 'https://t.me/assalkom',
      },
      deliveryCodes: ['courier', 'pickup'],
      pickupLocations: ['نقطة استلام مؤقتة'],
    );
    final first = await repository.saveMerchantStoreChannels(
      session.user!.id,
      workspace.store.id,
      draft,
    );
    final second = await repository.saveMerchantStoreChannels(
      session.user!.id,
      workspace.store.id,
      draft,
    );

    expect(first, isA<AssalData<AssalStoreSummary>>());
    expect(second, isA<AssalData<AssalStoreSummary>>());
    final saved = (second as AssalData<AssalStoreSummary>).value;
    expect(saved.socialLinks['whatsapp'], 'https://wa.me/967711111111');
    expect(saved.socialLinks['telegram'], 'https://t.me/assalkom');
    expect(saved.deliveryOptions, ['شركة توصيل', 'استلام من المتجر']);
    expect(saved.pickupLocations, ['نقطة استلام مؤقتة']);
  });
}
