/// Canonical route names and typed path helpers for the Assalkom app.
///
/// This registry is intentionally independent from feature widgets. Screens
/// can adopt it incrementally without creating an import cycle between the app
/// shell and customer/merchant features.
abstract final class AssalRoutes {
  static const home = '/';
  static const discover = '/discover';
  static const search = '/search';
  static const categories = '/categories';
  static const stores = '/stores';
  static const favorites = '/favorites';
  static const following = '/following';
  static const messages = '/messages';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const settings = '/settings';
  static const requests = '/requests';
  static const auth = '/auth';
  static const merchant = '/merchant';
  static const merchantStoreWizard = '/merchant/store/new';
  static const merchantProductWizard = '/merchant/product/new';
  static const verification = '/merchant/verification';
  static const subscriptions = '/merchant/subscriptions';
  static const admin = '/admin';

  static String product(String productId) =>
      _entityPath('/products', productId);

  static String store(String storeId) => _entityPath('/stores', storeId);

  static String request(String requestId) =>
      _entityPath('/requests', requestId);

  static String conversation(String conversationId) =>
      _entityPath('/conversations', conversationId);

  static String _entityPath(String collection, String id) =>
      '$collection/${Uri.encodeComponent(id)}';
}

/// A navigation intent that keeps entity context explicit for deep links and
/// notification routing. The intent is data-only and has no UI dependency.
final class AssalRouteIntent {
  const AssalRouteIntent({required this.route, this.entityId, this.context});

  final String route;
  final String? entityId;
  final String? context;

  @override
  bool operator ==(Object other) =>
      other is AssalRouteIntent &&
      other.route == route &&
      other.entityId == entityId &&
      other.context == context;

  @override
  int get hashCode => Object.hash(route, entityId, context);
}
