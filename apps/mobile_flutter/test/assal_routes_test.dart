import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom/app/assal_routes.dart';

void main() {
  test('exposes canonical top-level destinations', () {
    expect(AssalRoutes.home, '/');
    expect(AssalRoutes.search, '/search');
    expect(AssalRoutes.notifications, '/notifications');
    expect(AssalRoutes.merchant, '/merchant');
  });

  test('encodes entity ids in canonical paths', () {
    expect(AssalRoutes.product('product/1'), '/products/product%2F1');
    expect(AssalRoutes.store('store 1'), '/stores/store%201');
    expect(AssalRoutes.request('request#1'), '/requests/request%231');
  });

  test('keeps route entity context value-based', () {
    const first = AssalRouteIntent(
      route: AssalRoutes.product('/product-1'),
      entityId: 'product-1',
      context: 'store-1',
    );
    const second = AssalRouteIntent(
      route: AssalRoutes.product('/product-1'),
      entityId: 'product-1',
      context: 'store-1',
    );
    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });
}
