import 'package:flutter/material.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_design/assal_tokens.dart';
import '../../core/assal_widgets.dart';
import 'customer_catalog.dart';
import 'customer_core.dart';
import 'customer_discovery.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({
    super.key,
    required this.repository,
    this.initialTab = 0,
  });
  final AssalRepository repository;
  final int initialTab;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  Future<AssalLoadState<List<AssalProductSummary>>>? productsFuture;
  Future<AssalLoadState<List<AssalStoreSummary>>>? storesFuture;
  Future<AssalLoadState<List<AssalTaxonomy>>>? taxonomiesFuture;
  late Future<AssalSession> sessionFuture;
  final Set<String> removingFavoriteIds = <String>{};
  final Set<String> removingFollowedStoreIds = <String>{};
  final Map<String, Future<AssalLoadState<List<AssalProductSummary>>>>
      storeProductFutures =
      <String, Future<AssalLoadState<List<AssalProductSummary>>>>{};
  String? _loadedUserId;

  @override
  void initState() {
    super.initState();
    sessionFuture = widget.repository.getSession();
    tabs = TabController(
      length: 3,
      initialIndex: widget.initialTab.clamp(0, 2),
      vsync: this,
    );
  }

  void _load(String userId) {
    _loadedUserId = userId;
    storeProductFutures.clear();
    productsFuture = widget.repository.listFavoriteProducts(userId);
    storesFuture = widget.repository.listFollowedStores(userId);
    taxonomiesFuture = widget.repository.listFavoriteTaxonomies(userId);
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AssalSession>(
        future: sessionFuture,
        builder: (context, sessionSnapshot) {
          if (sessionSnapshot.connectionState != ConnectionState.done) {
            return const Scaffold(body: AssalGlassLoading());
          }
          final session = sessionSnapshot.data ?? AssalSession.guest;
          if (session.isUnavailable) {
            return Scaffold(
              appBar: const AssalAppBar(title: 'المحفوظات'),
              body: AssalMessageCard(
                icon: Icons.sync_problem_outlined,
                message: session.errorMessageAr ?? 'تعذر مزامنة الحساب الآن.',
                onRetry: _retrySession,
              ),
            );
          }
          if (!session.isAuthenticated || session.user == null) {
            return Scaffold(
              appBar: const AssalAppBar(title: 'المحفوظات'),
              body: Center(
                child: FilledButton(
                  onPressed: _login,
                  child: const Text('تسجيل الدخول لعرض محفوظاتك'),
                ),
              ),
            );
          }
          if (_loadedUserId != session.user!.id) _load(session.user!.id);
          return Scaffold(
            appBar: AssalAppBar(
              title: 'المحفوظات والمتابعات',
              bottom: TabBar(
                controller: tabs,
                tabs: const [
                  Tab(text: 'منتجات محفوظة'),
                  Tab(text: 'متاجر متابَعة'),
                  Tab(text: 'تصنيفات مرتبطة'),
                ],
              ),
            ),
            body: TabBarView(
                controller: tabs,
                children: [_products(), _stores(), _taxonomies()]),
          );
        },
      );

  Future<void> _login() async {
    final authenticated = await openAuth(context, widget.repository);
    if (!mounted || !authenticated) return;
    setState(() {
      sessionFuture = widget.repository.getSession();
      _loadedUserId = null;
    });
  }

  void _retrySession() {
    if (!mounted) return;
    setState(() {
      sessionFuture = widget.repository.getSession();
      _loadedUserId = null;
    });
  }

  Future<void> _removeFavorite(String productId) async {
    final userId = _loadedUserId;
    if (userId == null || removingFavoriteIds.contains(productId)) return;
    setState(() => removingFavoriteIds.add(productId));
    try {
      final result = await widget.repository.toggleFavorite(userId, productId);
      if (!mounted) return;
      if (result is AssalData<bool>) {
        setState(() => _load(userId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إزالة المنتج من المحفوظات.')),
        );
      } else if (result is AssalError<bool>) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.messageAr)),
        );
      }
    } finally {
      if (mounted) setState(() => removingFavoriteIds.remove(productId));
    }
  }

  Future<void> _removeFollow(String storeId) async {
    final userId = _loadedUserId;
    if (userId == null || removingFollowedStoreIds.contains(storeId)) return;
    setState(() => removingFollowedStoreIds.add(storeId));
    try {
      final result = await widget.repository.toggleFollow(userId, storeId);
      if (!mounted) return;
      if (result is AssalData<bool>) {
        setState(() => _load(userId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إزالة المتجر من المتابعات.')),
        );
      } else if (result is AssalError<bool>) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.messageAr)),
        );
      }
    } finally {
      if (mounted) setState(() => removingFollowedStoreIds.remove(storeId));
    }
  }

  Future<void> _exploreProducts() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchScreen(repository: widget.repository),
      ),
    );
  }

  Widget _emptyState(
    String message, {
    VoidCallback? onAction,
    String actionLabel = 'استكشف المنتجات',
    IconData actionIcon = Icons.search_rounded,
  }) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(AssalSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bookmark_border_rounded,
                size: 42,
                color: AssalColors.textMuted,
              ),
              const SizedBox(height: AssalSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AssalTypography.body.copyWith(
                  color: AssalColors.textSecondary,
                ),
              ),
              if (onAction != null) ...[
                const SizedBox(height: AssalSpacing.md),
                OutlinedButton.icon(
                  onPressed: onAction,
                  icon: Icon(actionIcon),
                  label: Text(actionLabel),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _listState<T>({
    required AssalLoadState<List<T>> state,
    required Widget Function(List<T>) builder,
    required String emptyMessage,
    VoidCallback? onEmptyAction,
    String emptyActionLabel = 'استكشف المنتجات',
    IconData emptyActionIcon = Icons.search_rounded,
    required VoidCallback onRetry,
  }) {
    if (state is AssalLoading<List<T>>) {
      return const AssalGlassLoading();
    }
    if (state is AssalError<List<T>>) {
      return AssalMessageCard(
        icon: Icons.sync_problem_outlined,
        message: state.messageAr,
        onRetry: state.retryable ? onRetry : null,
      );
    }
    if (state is AssalEmpty<List<T>>) {
      return _emptyState(
        emptyMessage,
        onAction: onEmptyAction,
        actionLabel: emptyActionLabel,
        actionIcon: emptyActionIcon,
      );
    }
    if (state is AssalData<List<T>>) {
      if (state.value.isEmpty) {
        return _emptyState(
          emptyMessage,
          onAction: onEmptyAction,
          actionLabel: emptyActionLabel,
          actionIcon: emptyActionIcon,
        );
      }
      return builder(state.value);
    }
    return const AssalGlassLoading();
  }

  Widget _products() =>
      FutureBuilder<AssalLoadState<List<AssalProductSummary>>>(
        future: productsFuture!,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const AssalGlassLoading();
          return _listState<AssalProductSummary>(
            state: snapshot.data!,
            onRetry: () => setState(() => _load(_loadedUserId!)),
            emptyMessage: 'لم تحفظ شيئًا بعد.',
            onEmptyAction: _exploreProducts,
            builder: (items) => GridView.builder(
              padding: const EdgeInsets.all(AssalSpacing.lg),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 360,
                  crossAxisSpacing: AssalSpacing.md,
                  mainAxisSpacing: AssalSpacing.md,
                  childAspectRatio: .58),
              itemCount: items.length,
              itemBuilder: (_, index) => ProductCard(
                product: items[index],
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(
                    repository: widget.repository,
                    productId: items[index].id,
                  ),
                )),
                onFavorite: () => _removeFavorite(items[index].id),
                favorite: true,
              ),
            ),
          );
        },
      );

  Widget _taxonomies() => FutureBuilder<AssalLoadState<List<AssalTaxonomy>>>(
        future: taxonomiesFuture!,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const AssalGlassLoading();
          return AssalStateView<List<AssalTaxonomy>>(
            state: snapshot.data!,
            onRetry: () => setState(() => _load(_loadedUserId!)),
            builder: (items) => ListView.separated(
              padding: const EdgeInsets.all(AssalSpacing.lg),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AssalSpacing.sm),
              itemBuilder: (_, index) => AssalActionTile(
                icon: _favoriteTaxonomyIcon(items[index].nameAr),
                title: items[index].nameAr,
                subtitle:
                    items[index].description ?? 'تصنيف مرتبط بمنتجاتك المحفوظة',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SearchScreen(
                    repository: widget.repository,
                    initialSubcategoryId: items[index].id,
                  ),
                )),
              ),
            ),
          );
        },
      );

  Future<void> _discoverStores() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoresScreen(repository: widget.repository),
      ),
    );
  }

  Future<AssalLoadState<List<AssalProductSummary>>> _productsForStore(
    String storeId,
  ) =>
      storeProductFutures.putIfAbsent(
        storeId,
        () => widget.repository.listProducts(
          query: AssalProductQuery(storeId: storeId),
        ),
      );

  Widget _stores() => FutureBuilder<AssalLoadState<List<AssalStoreSummary>>>(
        future: storesFuture!,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const AssalGlassLoading();
          return _listState<AssalStoreSummary>(
            state: snapshot.data!,
            onRetry: () => setState(() => _load(_loadedUserId!)),
            emptyMessage: 'لا تتابع متاجر بعد.',
            onEmptyAction: _discoverStores,
            emptyActionLabel: 'اكتشف المتاجر',
            emptyActionIcon: Icons.storefront_outlined,
            builder: (items) => ListView.separated(
              padding: const EdgeInsets.all(AssalSpacing.lg),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AssalSpacing.sm),
              itemBuilder: (_, index) =>
                  FutureBuilder<AssalLoadState<List<AssalProductSummary>>>(
                future: _productsForStore(items[index].id),
                builder: (context, productSnapshot) {
                  final productState = productSnapshot.data;
                  final productCount =
                      productState is AssalData<List<AssalProductSummary>>
                          ? productState.value.length
                          : null;
                  return StoreCard(
                    store: items[index],
                    productCount: productCount,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => StoreProfileScreen(
                        repository: widget.repository,
                        storeId: items[index].id,
                      ),
                    )),
                    onAction: () => _removeFollow(items[index].id),
                  );
                },
              ),
            ),
          );
        },
      );
}

IconData _favoriteTaxonomyIcon(String name) {
  if (name.contains('شمع')) return Icons.hexagon_outlined;
  if (name.contains('سدر')) return Icons.water_drop_outlined;
  if (name.contains('سمر') || name.contains('طلح')) return Icons.eco_outlined;
  if (name.contains('خلط') || name.contains('مزيج')) {
    return Icons.local_florist_outlined;
  }
  if (name.contains('هد')) return Icons.card_giftcard_outlined;
  return Icons.hive_outlined;
}
