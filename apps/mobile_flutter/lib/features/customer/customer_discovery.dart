import 'package:flutter/material.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_design/assal_tokens.dart';
import '../../core/assal_widgets.dart';
import 'customer_core.dart';
import 'customer_catalog.dart';
import 'customer_account.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository, required this.onOpenSearch, required this.onOpenNotifications});
  final AssalRepository repository;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenNotifications;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<AssalLoadState<List<AssalProductSummary>>> featuredFuture;
  late Future<AssalLoadState<List<AssalTaxonomy>>> taxonomyFuture;
  late Future<AssalLoadState<List<AssalStoreSummary>>> storesFuture;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _load() {
    featuredFuture = widget.repository.listProducts(query: const AssalProductQuery(featuredOnly: true));
    taxonomyFuture = widget.repository.listTaxonomy();
    storesFuture = widget.repository.listStores();
  }

  void _refresh() => setState(_load);

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: CustomScrollView(slivers: [
          SliverPadding(padding: const EdgeInsets.fromLTRB(AssalSpacing.lg, AssalSpacing.md, AssalSpacing.lg, 0), sliver: SliverToBoxAdapter(child: _Header(onOpenNotifications: widget.onOpenNotifications))),
          SliverPadding(padding: const EdgeInsets.fromLTRB(AssalSpacing.lg, AssalSpacing.lg, AssalSpacing.lg, AssalSpacing.md), sliver: SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('اكتشف العسل من مصدره', style: AssalTypography.heading1.copyWith(color: AssalColors.deepBrown)),
            const SizedBox(height: AssalSpacing.sm),
            Text('تصفح المتاجر والمنتجات اليمنية الموثوقة، ثم تواصل مع التاجر بالطريقة المناسبة لك.', style: AssalTypography.bodyLarge.copyWith(color: AssalColors.textSecondary)),
            const SizedBox(height: AssalSpacing.lg),
            TextField(controller: searchController, readOnly: true, onTap: widget.onOpenSearch, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث عن سدر، سمر، شمع أو هدية', suffixIcon: Icon(Icons.tune_rounded))),
          ]))),
          SliverPadding(padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.lg), sliver: SliverToBoxAdapter(child: _HeroBanner(onExplore: widget.onOpenSearch))),
          SliverPadding(padding: const EdgeInsets.fromLTRB(AssalSpacing.lg, AssalSpacing.xl, AssalSpacing.lg, AssalSpacing.sm), sliver: SliverToBoxAdapter(child: SectionHeader(title: 'استكشف حسب التصنيف', actionLabel: 'كل التصنيفات', onAction: widget.onOpenSearch))),
          SliverToBoxAdapter(child: SizedBox(height: 92, child: FutureBuilder<AssalLoadState<List<AssalTaxonomy>>>(future: taxonomyFuture, builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            return AssalStateView<List<AssalTaxonomy>>(state: snapshot.data!, builder: (items) => ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.lg), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(width: AssalSpacing.sm), itemBuilder: (_, index) => _CategoryTile(item: items[index], onTap: widget.onOpenSearch)));
          }))),
          SliverPadding(padding: const EdgeInsets.fromLTRB(AssalSpacing.lg, AssalSpacing.xl, AssalSpacing.lg, AssalSpacing.sm), sliver: SliverToBoxAdapter(child: SectionHeader(title: 'منتجات مختارة', actionLabel: 'عرض الكل', onAction: widget.onOpenSearch))),
          SliverPadding(padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.lg), sliver: SliverToBoxAdapter(child: FutureBuilder<AssalLoadState<List<AssalProductSummary>>>(future: featuredFuture, builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
            return AssalStateView<List<AssalProductSummary>>(state: snapshot.data!, onRetry: _refresh, builder: (products) => GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: AssalSpacing.md, mainAxisSpacing: AssalSpacing.md, childAspectRatio: .68), itemCount: products.length > 6 ? 6 : products.length, itemBuilder: (_, index) => ProductCard(product: products[index], onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(repository: widget.repository, productId: products[index].id))))));
          }))),
          SliverPadding(padding: const EdgeInsets.fromLTRB(AssalSpacing.lg, AssalSpacing.xl, AssalSpacing.lg, AssalSpacing.sm), sliver: SliverToBoxAdapter(child: SectionHeader(title: 'متاجر موثوقة', actionLabel: 'عرض المتاجر', onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoresScreen(repository: widget.repository)))))),
          SliverPadding(padding: const EdgeInsets.fromLTRB(AssalSpacing.lg, 0, AssalSpacing.lg, AssalSpacing.xl), sliver: SliverToBoxAdapter(child: FutureBuilder<AssalLoadState<List<AssalStoreSummary>>>(future: storesFuture, builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            return AssalStateView<List<AssalStoreSummary>>(
              state: snapshot.data!,
              builder: (stores) => Column(
                children: stores.take(3).map<Widget>((store) {
                  return StoreCard(
                    store: store,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoreProfileScreen(repository: widget.repository, storeId: store.id))),
                  );
                }).toList(),
              ),
            );
          }))),
          const SliverToBoxAdapter(child: SizedBox(height: AssalSpacing.xl)),
        ]),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.onOpenNotifications});
  final VoidCallback onOpenNotifications;
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const AssalBrandMark(), Row(children: [IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())), icon: const Icon(Icons.settings_outlined), tooltip: 'الإعدادات'), IconButton(onPressed: onOpenNotifications, icon: const Icon(Icons.notifications_none_rounded), tooltip: 'الإشعارات')])]);
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onExplore});
  final VoidCallback onExplore;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(AssalSpacing.xl), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AssalColors.deepBrown, AssalColors.secondary]), borderRadius: BorderRadius.circular(AssalRadius.extraLarge)), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('الثقة تبدأ من المصدر', style: AssalTypography.heading2.copyWith(color: AssalColors.cream)), const SizedBox(height: AssalSpacing.sm), Text('اعرف النوع والمنطقة والتوثيق قبل أن تتواصل.', style: AssalTypography.body.copyWith(color: AssalColors.cream)), const SizedBox(height: AssalSpacing.md), FilledButton.tonal(onPressed: onExplore, child: const Text('ابدأ الاكتشاف'))])), const Icon(Icons.local_florist_rounded, size: 74, color: AssalColors.primaryLight)]));
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.item, required this.onTap});
  final AssalTaxonomy item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AssalRadius.large), child: Container(width: 122, padding: const EdgeInsets.all(AssalSpacing.sm), decoration: BoxDecoration(color: AssalColors.surface, border: Border.all(color: AssalColors.border), borderRadius: BorderRadius.circular(AssalRadius.large)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.category_outlined, color: AssalColors.primaryDark), const SizedBox(height: AssalSpacing.xs), Text(item.nameAr, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: AssalTypography.caption.copyWith(color: AssalColors.deepBrown))])));
}

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key, required this.repository});
  final AssalRepository repository;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التصنيفات')),
      body: FutureBuilder<AssalLoadState<List<AssalTaxonomy>>>(
        future: repository.listTaxonomy(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return AssalStateView<List<AssalTaxonomy>>(
            state: snapshot.data!,
            builder: (items) => ListView.separated(
              padding: const EdgeInsets.all(AssalSpacing.lg),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: AssalSpacing.sm),
              itemBuilder: (_, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: AssalColors.honeyLight, child: Icon(Icons.category_outlined, color: AssalColors.primaryDark)),
                    title: Text(item.nameAr),
                    subtitle: Text(item.description ?? 'تصفح المنتجات المرتبطة بهذا التصنيف'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SearchScreen(repository: repository, initialSubcategoryId: item.id))),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.repository, this.initialQuery, this.initialSubcategoryId});
  final AssalRepository repository;
  final String? initialQuery;
  final String? initialSubcategoryId;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController controller = TextEditingController(text: widget.initialQuery);
  String? subcategoryId;
  int? gradeLevel;
  ProductType? productType;
  bool verifiedOnly = false;
  AssalSort sort = AssalSort.featured;
  late Future<AssalLoadState<List<AssalProductSummary>>> productsFuture;
  late Future<AssalLoadState<List<AssalStoreSummary>>> storesFuture;

  @override
  void initState() {
    super.initState();
    subcategoryId = widget.initialSubcategoryId;
    _search();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _search() {
    final query = AssalProductQuery(search: controller.text, subcategoryId: subcategoryId, gradeLevel: gradeLevel, productType: productType, verifiedStoresOnly: verifiedOnly, sort: sort);
    productsFuture = widget.repository.listProducts(query: query);
    storesFuture = widget.repository.listStores();
  }

  void _applySearch() => setState(_search);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('البحث')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AssalSpacing.lg, AssalSpacing.md, AssalSpacing.lg, 0),
          child: TextField(
            controller: controller,
            autofocus: true,
            onSubmitted: (_) => _applySearch(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'اكتب اسم المنتج أو المنطقة',
              suffixIcon: IconButton(onPressed: () { controller.clear(); _applySearch(); }, icon: const Icon(Icons.clear), tooltip: 'مسح'),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.lg, vertical: AssalSpacing.sm),
          child: Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: _showFilters, icon: const Icon(Icons.tune_rounded), label: const Text('الفلاتر'))),
            const SizedBox(width: AssalSpacing.sm),
            PopupMenuButton<AssalSort>(
              initialValue: sort,
              onSelected: (value) => setState(() { sort = value; _search(); }),
              itemBuilder: (_) => const [
                PopupMenuItem(value: AssalSort.featured, child: Text('المميزة أولًا')),
                PopupMenuItem(value: AssalSort.newest, child: Text('الأحدث')),
                PopupMenuItem(value: AssalSort.popular, child: Text('الأكثر شعبية')),
                PopupMenuItem(value: AssalSort.rating, child: Text('الأعلى تقييمًا')),
              ],
              child: const Chip(avatar: Icon(Icons.sort, size: 18), label: Text('ترتيب')),
            ),
          ]),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _applySearch(),
            child: ListView(padding: const EdgeInsets.fromLTRB(AssalSpacing.lg, 0, AssalSpacing.lg, AssalSpacing.xl), children: [
              const SectionHeader(title: 'المنتجات'),
              FutureBuilder<AssalLoadState<List<AssalProductSummary>>>(
                future: productsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
                  return AssalStateView<List<AssalProductSummary>>(
                    state: snapshot.data!,
                    onRetry: _applySearch,
                    builder: (products) => GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: AssalSpacing.md, mainAxisSpacing: AssalSpacing.md, childAspectRatio: .68),
                      itemCount: products.length,
                      itemBuilder: (_, index) {
                        final product = products[index];
                        return ProductCard(
                          product: product,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(repository: widget.repository, productId: product.id))),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: AssalSpacing.xl),
              const SectionHeader(title: 'المتاجر'),
              FutureBuilder<AssalLoadState<List<AssalStoreSummary>>>(
                future: storesFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
                  return AssalStateView<List<AssalStoreSummary>>(
                    state: snapshot.data!,
                    builder: (stores) => Column(
                      children: stores.map<Widget>((store) {
                        return StoreCard(
                          store: store,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoreProfileScreen(repository: widget.repository, storeId: store.id))),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Future<void> _showFilters() async {
    var draftGrade = gradeLevel;
    var draftType = productType;
    var draftVerified = verifiedOnly;
    final typeItems = <DropdownMenuItem<ProductType?>>[
      const DropdownMenuItem<ProductType?>(value: null, child: Text('كل الأنواع')),
      ...ProductType.values.map<DropdownMenuItem<ProductType?>>((type) => DropdownMenuItem<ProductType?>(value: type, child: Text(_productTypeLabel(type)))),
    ];
    final gradeItems = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(value: null, child: Text('كل الدرجات')),
      ...[1, 2, 3, 4].map<DropdownMenuItem<int?>>((grade) => DropdownMenuItem<int?>(value: grade, child: Text('درجة $grade'))),
    ];
    final apply = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, setModalState) => Padding(
        padding: const EdgeInsets.all(AssalSpacing.xl),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('تصفية النتائج', style: AssalTypography.heading2.copyWith(color: AssalColors.deepBrown)),
          const SizedBox(height: AssalSpacing.md),
          DropdownButtonFormField<ProductType?>(initialValue: draftType, decoration: const InputDecoration(labelText: 'نوع المنتج'), items: typeItems, onChanged: (value) => setModalState(() => draftType = value)),
          DropdownButtonFormField<int?>(initialValue: draftGrade, decoration: const InputDecoration(labelText: 'درجة الجودة'), items: gradeItems, onChanged: (value) => setModalState(() => draftGrade = value)),
          SwitchListTile(value: draftVerified, onChanged: (value) => setModalState(() => draftVerified = value), title: const Text('المتاجر الموثقة فقط')),
          const SizedBox(height: AssalSpacing.md),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () { gradeLevel = draftGrade; productType = draftType; verifiedOnly = draftVerified; Navigator.pop(sheetContext, true); }, child: const Text('تطبيق الفلاتر'))),
        ]),
      )),
    );
    if (apply == true) _applySearch();
  }
}

String _productTypeLabel(ProductType type) => switch (type) { ProductType.honey => 'عسل', ProductType.wax => 'شمع', ProductType.mix => 'خلطة', ProductType.raw => 'منتج خام', ProductType.gift => 'هدية' };

class StoresScreen extends StatelessWidget {
  const StoresScreen({super.key, required this.repository});
  final AssalRepository repository;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المتاجر')),
      body: FutureBuilder<AssalLoadState<List<AssalStoreSummary>>>(
        future: repository.listStores(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return AssalStateView<List<AssalStoreSummary>>(
            state: snapshot.data!,
            builder: (stores) => ListView(
              padding: const EdgeInsets.all(AssalSpacing.lg),
              children: stores.map<Widget>((store) {
                return StoreCard(
                  store: store,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoreProfileScreen(repository: repository, storeId: store.id))),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

