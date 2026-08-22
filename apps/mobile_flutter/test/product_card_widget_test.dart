import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';

import 'package:assalkom/core/assal_widgets.dart';

void main() {
  testWidgets('product card uses square image frame and shows core fields',
      (tester) async {
    const product = AssalProductSummary(
      id: 'product-1',
      storeId: 'store-1',
      nameAr: 'عسل سدر يمني',
      productType: ProductType.honey,
      status: ProductStatus.active,
      categoryNameAr: 'العسل',
      subcategoryNameAr: 'سدر',
      price: 180,
      currencyCode: 'YER',
      availability: 'متاح للاستفسار',
      ratingAverage: 4.5,
      reviewCount: 8,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            child: ProductCard(product: product, onTap: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final frame = tester.widget<AspectRatio>(find.byType(AspectRatio));
    expect(frame.aspectRatio, 1);
    expect(find.text('عسل سدر يمني'), findsOneWidget);
    expect(find.text('متاح للاستفسار'), findsOneWidget);
    expect(find.text('180 ريال يمني'), findsOneWidget);
  });
}
