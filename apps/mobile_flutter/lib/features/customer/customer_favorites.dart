import 'package:flutter/material.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_design/assal_tokens.dart';
import '../../core/assal_widgets.dart';
import 'customer_catalog.dart';
import 'customer_core.dart';
import 'customer_discovery.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.repository});
  final AssalRepository repository;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  late final TabController tabs;
  Future<AssalLoadState<List<AssalProductSummary>>>? productsFuture;
  Future<AssalLoadState<List<AssalStoreSummary>>>? storesFuture;
  Future<AssalLoadState<List<AssalTaxonomy>>>? taxonomiesFuture;
  String? _loadedUserId;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 3, vsync: this);
  }

  void _load(String userId) {
    _loadedUserId = userId;
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
        future: widget.repository.getSession(),
        builder: (context, sessionSnapshot) {
          if (sessionSnapshot.connectionState != ConnectionState.done) {
            return const Scaffold(body: AssalGlassLoading());
          }
          final session = sessionSnapshot.data ?? AssalSession.guest;
          if (!session.isAuthenticated || session.user == null) {
            return Scaffold(appBar: const AssalAppBar(title: 'المحفوظات'), body: Center(child: FilledButton(onPressed: () => openAuth(context, widget.repository), child: const Text('تسجيل الدخول لعرض محفوظاتك'))));
          }
          if (_loadedUserId != session.user!.id) _load(session.user!.id);
          return Scaffold(
            appBar: AssalAppBar(title: 'المحفوظات', bottom: TabBar(controller: tabs, tabs: const [Tab(text: 'المنتجات'), Tab(text: 'المتاجر'), Tab(text: 'التصنيفات')])) ,
            body: TabBarView(controller: tabs, children: [_products(), _stores(), _taxonomies()]),
          );
        },
      );

  Widget _products() => FutureBuilder<AssalLoadState<List<AssalProductSummary>>>(
        future: productsFuture!,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const AssalGlassLoading();
          return AssalStateView<List<AssalProductSummary>>(
            state: snapshot.data!,
            onRetry: () => setState(() => _load(_loadedUserId!)),
            builder: (items) => GridView.builder(
              padding: const EdgeInsets.all(AssalSpacing.lg),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220, crossAxisSpacing: AssalSpacing.md, mainAxisSpacing: AssalSpacing.md, childAspectRatio: .68),
              itemCount: items.length,
              itemBuilder: (_, index) => ProductCard(product: items[index], onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(repository: widget.repository, productId: items[index].id)))),
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
              separatorBuilder: (_, __) => const SizedBox(height: AssalSpacing.sm),
              itemBuilder: (_, index) => Card(child: ListTile(leading: Icon(_favoriteTaxonomyIcon(items[index].nameAr), color: AssalColors.primaryDark), title: Text(items[index].nameAr), subtitle: Text(items[index].description ?? 'تصنيف محفوظ مرتبط بمنتجاتك'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SearchScreen(repository: widget.repository, initialSubcategoryId: items[index].id))))),
            ),
          );
        },
      );

  Widget _stores() => FutureBuilder<AssalLoadState<List<AssalStoreSummary>>>(
        future: storesFuture!,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const AssalGlassLoading();
          return AssalStateView<List<AssalStoreSummary>>(
            state: snapshot.data!,
            onRetry: () => setState(() => _load(_loadedUserId!)),
            builder: (items) => ListView.separated(
              padding: const EdgeInsets.all(AssalSpacing.lg),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: AssalSpacing.sm),
              itemBuilder: (_, index) => StoreCard(store: items[index], onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoreProfileScreen(repository: widget.repository, storeId: items[index].id)))),
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
