import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';

import 'package:assalkom/core/assal_widgets.dart';

const _product = AssalProductSummary(
  id: 'product-008',
  storeId: 'store-008',
  nameAr: 'عسل السدر الجبلي الفاخر',
  productType: ProductType.honey,
  status: ProductStatus.active,
  subcategoryNameAr: 'عسل السدر',
  price: 15000,
  currencyCode: 'YER',
  ratingAverage: 4.8,
  reviewCount: 128,
  availability: 'متوفر',
  weightLabel: '500 جم',
);

const _store = AssalStoreSummary(
  id: 'store-008',
  merchantId: 'merchant-008',
  nameAr: 'مناحل جبال اليمن',
  slug: 'yemen-mountains-apiary',
  regionNameAr: 'إب، اليمن',
  isVerified: true,
);

void main() {
  testWidgets('TASK 008 renders the unified product card contract',
      (tester) async {
    var saved = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 360,
              child: ProductCard(
                product: _product,
                store: _store,
                onTap: () {},
                onFavorite: () => saved++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final frame = tester.widget<AspectRatio>(find.byType(AspectRatio).first);
    expect(frame.aspectRatio, 1);
    expect(find.text('عسل السدر الجبلي الفاخر'), findsOneWidget);
    expect(find.text('عسل السدر'), findsOneWidget);
    expect(find.text('15,000 ريال يمني'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('128 تقييم'), findsOneWidget);
    expect(find.text('متوفر'), findsOneWidget);
    expect(find.text('500 جم'), findsOneWidget);
    expect(find.text('مناحل جبال اليمن'), findsOneWidget);
    expect(find.text('إب، اليمن'), findsOneWidget);
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    expect(find.byTooltip('حفظ المنتج'), findsOneWidget);

    await tester.tap(find.byTooltip('حفظ المنتج'));
    expect(saved, 1);
  });

  testWidgets('TASK 008 keeps the card usable at rail width without overflow',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 168,
              child: ProductCard(
                product: _product,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(AspectRatio), findsOneWidget);
  });

  testWidgets('TASK 008 records the square product-card visual contract',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1440);
    tester.view.devicePixelRatio = 4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProductCard(
              product: _product,
              store: _store,
              onTap: () {},
              onFavorite: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(ProductCard),
      matchesGoldenFile(
        'visual_reference/task008_product_card_reference_360x360.png',
      ),
    );
  });
}
