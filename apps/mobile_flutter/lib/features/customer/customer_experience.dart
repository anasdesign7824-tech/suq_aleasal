import 'package:flutter/material.dart';

import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_design/assal_tokens.dart';
import '../../core/assal_widgets.dart';

Future<void> openAuth(BuildContext context, AssalRepository repository) async {
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AuthScreen(repository: repository)));
}

Future<bool> requireAuth(BuildContext context, AssalRepository repository) async {
  final session = await repository.getSession();
  if (session.isAuthenticated) return true;
  final wantsLogin = await showAuthPrompt(context);
  if (wantsLogin && context.mounted) await openAuth(context, repository);
  return (await repository.getSession()).isAuthenticated;
}

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
          })),
          SliverPadding(padding: const EdgeInsets.fromLTRB(AssalSpacing.lg, AssalSpacing.xl, AssalSpacing.lg, AssalSpacing.sm), sliver: SliverToBoxAdapter(child: SectionHeader(title: 'منتجات مختارة', actionLabel: 'عرض الكل', onAction: widget.onOpenSearch))),
          SliverPadding(padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.lg), sliver: SliverToBoxAdapter(child: FutureBuilder<AssalLoadState<List<AssalProductSummary>>>(future: featuredFuture, builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
            return AssalStateView<List<AssalProductSummary>>(state: snapshot.data!, onRetry: _refresh, builder: (products) => GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: AssalSpacing.md, mainAxisSpacing: AssalSpacing.md, childAspectRatio: .68), itemCount: products.length > 6 ? 6 : products.length, itemBuilder: (_, index) => ProductCard(product: products[index], onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(repository: widget.repository, productId: products[index].id))))));
          }))),
          SliverPadding(padding: const EdgeInsets.fromLTRB(AssalSpacing.lg, AssalSpacing.xl, AssalSpacing.lg, AssalSpacing.sm), sliver: SliverToBoxAdapter(child: SectionHeader(title: 'متاجر موثوقة', actionLabel: 'عرض المتاجر', onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoresScreen(repository: widget.repository)))))),
          SliverPadding(padding: const EdgeInsets.fromLTRB(AssalSpacing.lg, 0, AssalSpacing.lg, AssalSpacing.xl), sliver: SliverToBoxAdapter(child: FutureBuilder<AssalLoadState<List<AssalStoreSummary>>>(future: storesFuture, builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            return AssalStateView<List<AssalStoreSummary>>(state: snapshot.data!, builder: (stores) => Column(children: stores.take(3).map((store) => StoreCard(store: store, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoreProfileScreen(repository: widget.repository, storeId: store.id)))).toList()));
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
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('التصنيفات')), body: FutureBuilder<AssalLoadState<List<AssalTaxonomy>>>(future: repository.listTaxonomy(), builder: (context, snapshot) { if (!snapshot.hasData) return const Center(child: CircularProgressIndicator()); return AssalStateView<List<AssalTaxonomy>>(state: snapshot.data!, builder: (items) => ListView.separated(padding: const EdgeInsets.all(AssalSpacing.lg), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: AssalSpacing.sm), itemBuilder: (_, index) => Card(child: ListTile(leading: const CircleAvatar(backgroundColor: AssalColors.honeyLight, child: Icon(Icons.category_outlined, color: AssalColors.primaryDark)), title: Text(items[index].nameAr), subtitle: Text(items[index].description ?? 'تصفح المنتجات المرتبطة بهذا التصنيف'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SearchScreen(repository: repository, initialSubcategoryId: items[index].id)))))); });
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

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.repository, required this.productId});
  final AssalRepository repository;
  final String productId;
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<AssalLoadState<AssalProductSummary>> productFuture;
  bool liked = false;
  bool favorite = false;
  @override
  void initState() { super.initState(); productFuture = widget.repository.getProduct(widget.productId); }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('تفاصيل المنتج'), actions: [IconButton(onPressed: () => _share(), icon: const Icon(Icons.share_outlined), tooltip: 'مشاركة')]), body: FutureBuilder<AssalLoadState<AssalProductSummary>>(future: productFuture, builder: (context, snapshot) { if (!snapshot.hasData) return const Center(child: CircularProgressIndicator()); return AssalStateView<AssalProductSummary>(state: snapshot.data!, onRetry: () => setState(() => productFuture = widget.repository.getProduct(widget.productId)), builder: (product) => _content(product)); }));

  Widget _content(AssalProductSummary product) => FutureBuilder<AssalLoadState<AssalStoreSummary>>(future: widget.repository.getStore(product.storeId), builder: (context, storeSnapshot) {
    final store = storeSnapshot.data is AssalData<AssalStoreSummary> ? (storeSnapshot.data! as AssalData<AssalStoreSummary>).value : null;
    return ListView(padding: const EdgeInsets.all(AssalSpacing.lg), children: [
      SizedBox(height: 260, child: PageView(children: [AssalImageTile(imageUrl: product.primaryImageUrl, height: 260), AssalImageTile(imageUrl: product.primaryImageUrl, height: 260, icon: Icons.wb_sunny_outlined), AssalImageTile(imageUrl: product.primaryImageUrl, height: 260, icon: Icons.hive_outlined)])),
      const SizedBox(height: AssalSpacing.md),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (index) => Container(width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(color: index == 0 ? AssalColors.primaryDark : AssalColors.border, shape: BoxShape.circle)))),
      const SizedBox(height: AssalSpacing.lg),
      Text(product.nameAr, style: AssalTypography.heading1.copyWith(color: AssalColors.deepBrown)),
      const SizedBox(height: AssalSpacing.sm),
      Wrap(spacing: AssalSpacing.sm, runSpacing: AssalSpacing.sm, children: [if (product.subcategoryNameAr != null) InfoChip(label: product.subcategoryNameAr!), if (product.regionNameAr != null) InfoChip(label: product.regionNameAr!), if (product.gradeLevel != null) InfoChip(label: 'الجودة: درجة ${product.gradeLevel}', icon: Icons.verified_outlined)]),
      const SizedBox(height: AssalSpacing.lg),
      if (product.description != null) Text(product.description!, style: AssalTypography.bodyLarge),
      if (product.tags.isNotEmpty) ...[const SizedBox(height: AssalSpacing.lg), Text('لماذا قد يناسبك؟', style: AssalTypography.heading3.copyWith(color: AssalColors.deepBrown)), const SizedBox(height: AssalSpacing.sm), Wrap(spacing: AssalSpacing.sm, runSpacing: AssalSpacing.sm, children: product.tags.map((tag) => InfoChip(label: tag)).toList())],
      const SizedBox(height: AssalSpacing.lg),
      _MetadataCard(product: product),
      const SizedBox(height: AssalSpacing.lg),
      if (store != null) Card(child: ListTile(leading: const CircleAvatar(backgroundColor: AssalColors.honeyLight, child: Icon(Icons.storefront_outlined, color: AssalColors.primaryDark)), title: Text(store.nameAr), subtitle: Text(store.isVerified ? 'متجر موثق · ${store.regionNameAr ?? ''}' : 'متجر على منصة عسلكم'), trailing: TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoreProfileScreen(repository: widget.repository, storeId: store.id))), child: const Text('فتح المتجر')))),
      const SizedBox(height: AssalSpacing.lg),
      Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () async { final session = await requireAuth(context, widget.repository); if (!session || !mounted) return; final result = await widget.repository.toggleLike('demo-customer', product.id); if (result is AssalData<bool>) setState(() => liked = result.value); }, icon: Icon(liked ? Icons.thumb_up : Icons.thumb_up_outlined), label: Text(liked ? 'أعجبتني' : 'إعجاب'))), const SizedBox(width: AssalSpacing.sm), Expanded(child: OutlinedButton.icon(onPressed: () async { final session = await requireAuth(context, widget.repository); if (!session || !mounted) return; final result = await widget.repository.toggleFavorite('demo-customer', product.id); if (result is AssalData<bool>) setState(() => favorite = result.value); }, icon: Icon(favorite ? Icons.bookmark : Icons.bookmark_border), label: Text(favorite ? 'محفوظ' : 'حفظ')))]),
      const SizedBox(height: AssalSpacing.md),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => _request(product, store), icon: const Icon(Icons.chat_bubble_outline), label: const Text('إرسال طلب تواصل')),
      const SizedBox(height: AssalSpacing.xl),
      _ReviewsSection(repository: widget.repository, product: product),
      const SizedBox(height: AssalSpacing.xl),
      _CommentsSection(repository: widget.repository, targetId: product.id),
      const SizedBox(height: AssalSpacing.xl),
    ]);
  });

  Future<void> _request(AssalProductSummary product, AssalStoreSummary? store) async { if (store == null) return; final session = await requireAuth(context, widget.repository); if (!session || !mounted) return; await showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => RequestSheet(repository: widget.repository, product: product, store: store)); }
  void _share() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تجهيز رابط المشاركة في Demo Mode')));
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.product});
  final AssalProductSummary product;
  @override
  Widget build(BuildContext context) => Card(color: AssalColors.cream, child: Padding(padding: const EdgeInsets.all(AssalSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('بيانات المصدر والجودة', style: AssalTypography.heading3.copyWith(color: AssalColors.deepBrown)), const SizedBox(height: AssalSpacing.md), _row('نوع المنتج', _productTypeLabel(product.productType)), _row('المنطقة', product.regionNameAr ?? 'غير محددة'), _row('التصنيف', product.subcategoryNameAr ?? 'غير محدد'), _row('التوفر', product.availability), if (product.weightLabel != null) _row('الوزن', product.weightLabel!), if (product.harvestLabel != null) _row('الإنتاج', product.harvestLabel!)])));
  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: AssalSpacing.xs), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 92, child: Text(label, style: AssalTypography.bodySmall.copyWith(color: AssalColors.textMuted))), Expanded(child: Text(value, style: AssalTypography.body.copyWith(color: AssalColors.textPrimary)))]));
}

class StoreProfileScreen extends StatefulWidget {
  const StoreProfileScreen({super.key, required this.repository, required this.storeId});
  final AssalRepository repository;
  final String storeId;
  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  bool following = false;
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('صفحة المتجر')), body: FutureBuilder<AssalLoadState<AssalStoreSummary>>(future: widget.repository.getStore(widget.storeId), builder: (context, snapshot) { if (!snapshot.hasData) return const Center(child: CircularProgressIndicator()); return AssalStateView<AssalStoreSummary>(state: snapshot.data!, builder: (store) => _content(store)); }));
  Widget _content(AssalStoreSummary store) => ListView(padding: const EdgeInsets.all(AssalSpacing.lg), children: [Container(height: 150, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AssalColors.secondary, AssalColors.deepBrown]), borderRadius: BorderRadius.circular(AssalRadius.extraLarge)), child: const Center(child: Icon(Icons.hive_outlined, size: 80, color: AssalColors.primaryLight))), Transform.translate(offset: const Offset(0, -28), child: CircleAvatar(radius: 36, backgroundColor: AssalColors.honeyLight, child: const Icon(Icons.storefront_outlined, size: 34, color: AssalColors.primaryDark))), Text(store.nameAr, textAlign: TextAlign.center, style: AssalTypography.heading1.copyWith(color: AssalColors.deepBrown)), const SizedBox(height: AssalSpacing.sm), Row(mainAxisAlignment: MainAxisAlignment.center, children: [if (store.isVerified) const Icon(Icons.verified, size: 18, color: AssalColors.primaryDark), const SizedBox(width: 4), Text(store.isVerified ? 'متجر موثق' : 'متجر في طور التعريف', style: AssalTypography.body.copyWith(color: AssalColors.textSecondary))]), const SizedBox(height: AssalSpacing.md), Text(store.description ?? 'متجر متخصص في المنتجات النحلية اليمنية.', textAlign: TextAlign.center, style: AssalTypography.bodyLarge.copyWith(color: AssalColors.textSecondary)), const SizedBox(height: AssalSpacing.lg), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_stat('${store.followersCount}', 'متابع'), _stat('${store.reviewCount}', 'مراجعة'), _stat('${store.yearsExperience}', 'سنوات خبرة')]), const SizedBox(height: AssalSpacing.lg), Row(children: [Expanded(child: FilledButton.icon(onPressed: () async { final allowed = await requireAuth(context, widget.repository); if (!allowed || !mounted) return; final result = await widget.repository.toggleFollow('demo-customer', store.id); if (result is AssalData<bool>) setState(() => following = result.value); }, icon: Icon(following ? Icons.check : Icons.person_add_alt_1), label: Text(following ? 'تتابعه' : 'متابعة'))), const SizedBox(width: AssalSpacing.sm), Expanded(child: OutlinedButton.icon(onPressed: () async { final allowed = await requireAuth(context, widget.repository); if (!allowed || !mounted) return; final conversation = AssalConversationSummary(id: 'demo-conversation-${store.id}', storeId: store.id, storeName: store.nameAr, lastMessage: 'ابدأ محادثة جديدة', updatedAt: DateTime.now()); Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConversationScreen(repository: widget.repository, conversation: conversation))); }, icon: const Icon(Icons.forum_outlined), label: const Text('مراسلة')))]), const SizedBox(height: AssalSpacing.xl), SectionHeader(title: 'تخصصات المتجر'), Wrap(spacing: AssalSpacing.sm, runSpacing: AssalSpacing.sm, children: (store.specialties.isEmpty ? ['عسل يمني', 'مصدر موثق'] : store.specialties).map((item) => InfoChip(label: item)).toList()), const SizedBox(height: AssalSpacing.xl), SectionHeader(title: 'منتجات المتجر'), FutureBuilder<AssalLoadState<List<AssalProductSummary>>>(future: widget.repository.listProducts(query: AssalProductQuery(storeId: store.id)), builder: (context, snapshot) { if (!snapshot.hasData) return const Center(child: CircularProgressIndicator()); return AssalStateView<List<AssalProductSummary>>(state: snapshot.data!, builder: (products) => GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: AssalSpacing.md, mainAxisSpacing: AssalSpacing.md, childAspectRatio: .68), itemCount: products.length, itemBuilder: (_, index) => ProductCard(product: products[index], onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(repository: widget.repository, productId: products[index].id))))); })]);
  Widget _stat(String value, String label) => Column(children: [Text(value, style: AssalTypography.heading3.copyWith(color: AssalColors.deepBrown)), Text(label, style: AssalTypography.caption.copyWith(color: AssalColors.textMuted))]);
}

class RequestSheet extends StatefulWidget {
  const RequestSheet({super.key, required this.repository, required this.product, required this.store});
  final AssalRepository repository;
  final AssalProductSummary product;
  final AssalStoreSummary store;
  @override
  State<RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<RequestSheet> {
  final bodyController = TextEditingController(text: 'أرغب في معرفة تفاصيل المنتج والتوفر الحالي.');
  final phoneController = TextEditingController();
  int quantity = 1;
  HandoffOption option = HandoffOption.contact;
  bool saving = false;

  @override
  void dispose() {
    bodyController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: AssalSpacing.xl, right: AssalSpacing.xl, top: AssalSpacing.xl, bottom: MediaQuery.viewInsetsOf(context).bottom + AssalSpacing.xl),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('طلب تواصل مع ${widget.store.nameAr}', style: AssalTypography.heading2.copyWith(color: AssalColors.deepBrown)),
          const SizedBox(height: AssalSpacing.sm),
          Text(widget.product.nameAr, style: AssalTypography.subtitle),
          const SizedBox(height: AssalSpacing.lg),
          TextField(controller: bodyController, maxLines: 3, decoration: const InputDecoration(labelText: 'رسالتك', hintText: 'اكتب ما تريد معرفته')),
          const SizedBox(height: AssalSpacing.md),
          TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم للتواصل (اختياري)')),
          const SizedBox(height: AssalSpacing.md),
          DropdownButtonFormField<HandoffOption>(value: option, decoration: const InputDecoration(labelText: 'طريقة التسليم المفضلة'), items: HandoffOption.values.map<DropdownMenuItem<HandoffOption>>((item) => DropdownMenuItem(value: item, child: Text(item.labelAr))).toList(), onChanged: (value) { if (value != null) setState(() => option = value); }),
          const SizedBox(height: AssalSpacing.md),
          Row(children: [
            const Text('الكمية'),
            IconButton(onPressed: () => setState(() { if (quantity > 1) quantity--; }), icon: const Icon(Icons.remove_circle_outline)),
            Text('$quantity', style: AssalTypography.title),
            IconButton(onPressed: () => setState(() => quantity++), icon: const Icon(Icons.add_circle_outline)),
          ]),
          const SizedBox(height: AssalSpacing.lg),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: saving ? null : _submit, child: saving ? const CircularProgressIndicator() : const Text('حفظ وإرسال الطلب'))),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    final body = bodyController.text.trim();
    if (body.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب رسالة أوضح للتاجر.')));
      return;
    }
    setState(() => saving = true);
    final result = await widget.repository.createRequest('demo-customer', AssalRequestDraft(storeId: widget.store.id, productId: widget.product.id, subject: 'استفسار عن ${widget.product.nameAr}', body: body, quantity: quantity, phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(), handoffOption: option));
    if (!mounted) return;
    setState(() => saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result is AssalData<AssalRequestSummary> ? 'تم حفظ الطلب ويمكنك متابعته من ملفك.' : 'تعذر حفظ الطلب، حاول مرة أخرى.')));
  }
}

class _ReviewsSection extends StatefulWidget {
  const _ReviewsSection({required this.repository, required this.product});
  final AssalRepository repository;
  final AssalProductSummary product;
  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}
class _ReviewsSectionState extends State<_ReviewsSection> {
  late Future<AssalLoadState<List<AssalReviewSummary>>> future;

  @override
  void initState() {
    super.initState();
    future = widget.repository.listReviews(widget.product.id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'المراجعات'),
      FutureBuilder<AssalLoadState<List<AssalReviewSummary>>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return AssalStateView<List<AssalReviewSummary>>(
            state: snapshot.data!,
            builder: (reviews) => Column(
              children: reviews.map<Widget>((review) => Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                  title: Row(children: [Text(review.authorName ?? 'عميل'), const SizedBox(width: AssalSpacing.sm), RatingStars(rating: review.rating.toDouble())]),
                  subtitle: Text(review.body ?? 'تجربة موثقة'),
                ),
              )).toList(),
            ),
          );
        },
      ),
      const SizedBox(height: AssalSpacing.sm),
      OutlinedButton.icon(onPressed: _writeReview, icon: const Icon(Icons.rate_review_outlined), label: const Text('أضف مراجعتك')),
    ]);
  }

  Future<void> _writeReview() async {
    final allowed = await requireAuth(context, widget.repository);
    if (!allowed || !mounted) return;
    final body = TextEditingController();
    var rating = 5;
    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setModal) => AlertDialog(
        title: const Text('مراجعتك'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<int>(initialValue: rating, items: [1, 2, 3, 4, 5].map<DropdownMenuItem<int>>((item) => DropdownMenuItem(value: item, child: Text('$item نجوم'))).toList(), onChanged: (value) => setModal(() => rating = value ?? 5)),
          TextField(controller: body, maxLines: 3, decoration: const InputDecoration(hintText: 'شارك ما يفيد الآخرين')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('نشر')),
        ],
      )),
    );
    if (submit == true && body.text.trim().isNotEmpty) {
      await widget.repository.createReview('demo-customer', AssalReviewDraft(productId: widget.product.id, storeId: widget.product.storeId, rating: rating, body: body.text.trim()));
      if (mounted) setState(() => future = widget.repository.listReviews(widget.product.id));
    }
    body.dispose();
  }
}

class _CommentsSection extends StatefulWidget {
  const _CommentsSection({required this.repository, required this.targetId});
  final AssalRepository repository;
  final String targetId;
  @override
  State<_CommentsSection> createState() => _CommentsSectionState();
}
class _CommentsSectionState extends State<_CommentsSection> {
  late Future<AssalLoadState<List<AssalCommentSummary>>> future;
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    future = widget.repository.listComments(widget.targetId);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'التعليقات'),
      FutureBuilder<AssalLoadState<List<AssalCommentSummary>>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return AssalStateView<List<AssalCommentSummary>>(
            state: snapshot.data!,
            builder: (comments) => Column(
              children: comments.map<Widget>((comment) => Card(child: ListTile(title: Text(comment.authorName), subtitle: Text(comment.body)))).toList(),
            ),
          );
        },
      ),
      const SizedBox(height: AssalSpacing.sm),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: TextField(controller: controller, maxLines: 2, decoration: const InputDecoration(hintText: 'اكتب تعليقًا مفيدًا'))),
        IconButton(onPressed: _add, icon: const Icon(Icons.send_rounded), tooltip: 'إرسال التعليق'),
      ]),
    ]);
  }

  Future<void> _add() async {
    final body = controller.text.trim();
    if (body.isEmpty) return;
    final allowed = await requireAuth(context, widget.repository);
    if (!allowed || !mounted) return;
    await widget.repository.createComment('demo-customer', 'عميل عسلكم', widget.targetId, body);
    controller.clear();
    setState(() => future = widget.repository.listComments(widget.targetId));
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.repository});
  final AssalRepository repository;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}
class _AuthScreenState extends State<AuthScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController(text: 'demo@assalkom.app');
  final passwordController = TextEditingController(text: 'demo123');
  bool registerMode = false;
  bool loading = false;
  @override
  void dispose() { nameController.dispose(); emailController.dispose(); passwordController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(registerMode ? 'إنشاء حساب' : 'تسجيل الدخول')), body: ListView(padding: const EdgeInsets.all(AssalSpacing.xl), children: [const AssalBrandMark(size: 66), const SizedBox(height: AssalSpacing.xl), Text(registerMode ? 'أنشئ حسابك في عسلكم' : 'أهلًا بك في عسلكم', style: AssalTypography.heading1.copyWith(color: AssalColors.deepBrown)), const SizedBox(height: AssalSpacing.sm), Text('يمكنك التصفح كزائر، والحساب يفتح لك الحفظ والمتابعة والطلبات والمراسلة.', style: AssalTypography.bodyLarge.copyWith(color: AssalColors.textSecondary)), const SizedBox(height: AssalSpacing.xl), if (registerMode) ...[TextField(controller: nameController, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'الاسم')) , const SizedBox(height: AssalSpacing.md)], TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')), const SizedBox(height: AssalSpacing.md), TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور')), const SizedBox(height: AssalSpacing.lg), SizedBox(width: double.infinity, child: FilledButton(onPressed: loading ? null : _submit, child: loading ? const CircularProgressIndicator() : Text(registerMode ? 'إنشاء الحساب' : 'تسجيل الدخول'))), TextButton(onPressed: () => setState(() => registerMode = !registerMode), child: Text(registerMode ? 'لديك حساب؟ تسجيل الدخول' : 'ليس لديك حساب؟ إنشاء حساب')), TextButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سنرسل رابط الاستعادة عند ربط مزود المصادقة الإنتاجي.'))), child: const Text('نسيت كلمة المرور؟'))]));
  Future<void> _submit() async { setState(() => loading = true); final result = registerMode ? await widget.repository.register(nameController.text, emailController.text, passwordController.text) : await widget.repository.signIn(emailController.text, passwordController.text); if (!mounted) return; setState(() => loading = false); if (result is AssalData<AssalSession>) { Navigator.pop(context); } else if (result is AssalError<AssalSession>) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.messageAr))); } }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.repository});
  final AssalRepository repository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AssalSession>(
      future: repository.getSession(),
      builder: (context, snapshot) {
        final session = snapshot.data ?? AssalSession.guest;
        return ListView(padding: const EdgeInsets.all(AssalSpacing.lg), children: [
          const AssalBrandMark(),
          const SizedBox(height: AssalSpacing.xl),
          session.isAuthenticated ? _authenticated(context, session) : _guest(context),
          const SizedBox(height: AssalSpacing.lg),
          Card(child: Column(children: [
            ListTile(leading: const Icon(Icons.notifications_outlined), title: const Text('الإشعارات'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NotificationsScreen(repository: repository)))),
            ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('الإعدادات'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()))),
            ListTile(leading: const Icon(Icons.help_outline), title: const Text('الدعم والتعريف بعسلكم'), trailing: const Icon(Icons.chevron_left), onTap: () => showAboutDialog(context: context, applicationName: 'عسلكم', applicationVersion: 'Demo', children: [const Text('منصة اكتشاف وتواصل للعسل اليمني من مصدره.')]))
          ])),
        ]);
      },
    );
  }

  Widget _guest(BuildContext context) {
    return Card(
      color: AssalColors.cream,
      child: Padding(
        padding: const EdgeInsets.all(AssalSpacing.xl),
        child: Column(children: [
          const CircleAvatar(radius: 34, backgroundColor: AssalColors.honeyLight, child: Icon(Icons.person_outline, size: 36, color: AssalColors.primaryDark)),
          const SizedBox(height: AssalSpacing.md),
          Text('تصفح كزائر', style: AssalTypography.heading2.copyWith(color: AssalColors.deepBrown)),
          const SizedBox(height: AssalSpacing.sm),
          const Text('احفظ ما يعجبك وأرسل طلباتك عند إنشاء حساب مجاني.'),
          const SizedBox(height: AssalSpacing.lg),
          FilledButton(onPressed: () => openAuth(context, repository), child: const Text('تسجيل الدخول أو إنشاء حساب')),
        ]),
      ),
    );
  }

  Widget _authenticated(BuildContext context, AssalSession session) => Column(children: [
    CircleAvatar(radius: 38, backgroundColor: AssalColors.honeyLight, child: Text((session.user?.nameAr ?? 'ع').substring(0, 1), style: AssalTypography.heading1.copyWith(color: AssalColors.primaryDark))),
    const SizedBox(height: AssalSpacing.md),
    Text(session.user?.nameAr ?? 'عميل عسلكم', style: AssalTypography.heading2.copyWith(color: AssalColors.deepBrown)),
    Text(session.user?.email ?? '', style: AssalTypography.body.copyWith(color: AssalColors.textSecondary)),
    const SizedBox(height: AssalSpacing.lg),
    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_metric('0', 'المتابعات'), _metric('0', 'المحفوظات'), _metric('0', 'الطلبات')]),
    const SizedBox(height: AssalSpacing.lg),
    Row(children: [
      Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RequestsScreen(repository: repository))), icon: const Icon(Icons.assignment_outlined), label: const Text('طلباتي'))),
      const SizedBox(width: AssalSpacing.sm),
      Expanded(child: FilledButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BecomeMerchantScreen())), icon: const Icon(Icons.storefront_outlined), label: const Text('كن تاجرًا'))),
    ]),
    const SizedBox(height: AssalSpacing.sm),
    OutlinedButton.icon(onPressed: () async { await repository.signOut(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الخروج من Demo Mode'))); }, icon: const Icon(Icons.logout), label: const Text('تسجيل الخروج')),
  ]);

  Widget _metric(String value, String label) => Column(children: [Text(value, style: AssalTypography.heading3.copyWith(color: AssalColors.deepBrown)), Text(label, style: AssalTypography.caption.copyWith(color: AssalColors.textMuted))]);
}

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key, required this.repository});
  final AssalRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلباتي')),
      body: FutureBuilder<AssalSession>(
        future: repository.getSession(),
        builder: (context, sessionSnapshot) {
          final session = sessionSnapshot.data ?? AssalSession.guest;
          if (!session.isAuthenticated) {
            return Center(child: FilledButton(onPressed: () => openAuth(context, repository), child: const Text('تسجيل الدخول لمتابعة الطلبات')));
          }
          return FutureBuilder<AssalLoadState<List<AssalRequestSummary>>>(
            future: repository.listRequests(session.user!.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return AssalStateView<List<AssalRequestSummary>>(
                state: snapshot.data!,
                builder: (requests) => ListView.separated(
                  padding: const EdgeInsets.all(AssalSpacing.lg),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AssalSpacing.sm),
                  itemBuilder: (_, index) {
                    final request = requests[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: AssalColors.honeyLight, child: Icon(Icons.assignment_outlined, color: AssalColors.primaryDark)),
                        title: Text(request.subject),
                        subtitle: Text('${request.storeName ?? request.storeId} · ${request.preferredHandoffOption ?? 'تواصل مباشر'}'),
                        trailing: Chip(label: Text(request.status.labelAr)),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.repository});
  final AssalRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: FutureBuilder<AssalSession>(
        future: repository.getSession(),
        builder: (context, sessionSnapshot) {
          final session = sessionSnapshot.data ?? AssalSession.guest;
          if (!session.isAuthenticated) {
            return Center(child: FilledButton(onPressed: () => openAuth(context, repository), child: const Text('تسجيل الدخول لعرض إشعاراتك')));
          }
          return FutureBuilder<AssalLoadState<List<AssalNotificationSummary>>>(
            future: repository.listNotifications(session.user!.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return AssalStateView<List<AssalNotificationSummary>>(
                state: snapshot.data!,
                builder: (items) => ListView.separated(
                  padding: const EdgeInsets.all(AssalSpacing.lg),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, index) => ListTile(
                    leading: const CircleAvatar(backgroundColor: AssalColors.honeyLight, child: Icon(Icons.notifications_none, color: AssalColors.primaryDark)),
                    title: Text(items[index].titleAr),
                    subtitle: Text(items[index].bodyAr ?? ''),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, required this.repository, required this.conversation});
  final AssalRepository repository;
  final AssalConversationSummary conversation;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final controller = TextEditingController();
  late Future<AssalLoadState<List<AssalMessageSummary>>> future;

  @override
  void initState() {
    super.initState();
    future = widget.repository.listMessages(widget.conversation.id);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.conversation.storeName)),
      body: Column(children: [
        Expanded(
          child: FutureBuilder<AssalLoadState<List<AssalMessageSummary>>>(
            future: future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return AssalStateView<List<AssalMessageSummary>>(
                state: snapshot.data!,
                builder: (messages) => ListView(
                  padding: const EdgeInsets.all(AssalSpacing.lg),
                  children: messages.map<Widget>((message) {
                    return Align(
                      alignment: message.isMine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
                      child: Card(
                        color: message.isMine ? AssalColors.honeyLight : AssalColors.surfaceVariant,
                        child: Padding(padding: const EdgeInsets.all(AssalSpacing.md), child: Text(message.body)),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AssalSpacing.sm),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: TextField(controller: controller, maxLines: 3, minLines: 1, decoration: const InputDecoration(hintText: 'اكتب رسالتك'))),
              IconButton(onPressed: _send, icon: const Icon(Icons.send_rounded), tooltip: 'إرسال'),
            ]),
          ),
        ),
      ]),
    );
  }

  Future<void> _send() async {
    final body = controller.text.trim();
    if (body.isEmpty) return;
    await widget.repository.sendMessage('demo-customer', AssalMessageDraft(conversationId: widget.conversation.id, body: body));
    controller.clear();
    setState(() => future = widget.repository.listMessages(widget.conversation.id));
  }
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key, required this.repository});
  final AssalRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المراسلات')),
      body: FutureBuilder<AssalSession>(
        future: repository.getSession(),
        builder: (context, sessionSnapshot) {
          final session = sessionSnapshot.data ?? AssalSession.guest;
          if (!session.isAuthenticated) return Center(child: FilledButton(onPressed: () => openAuth(context, repository), child: const Text('تسجيل الدخول لعرض المراسلات')));
          return FutureBuilder<AssalLoadState<List<AssalConversationSummary>>>(
            future: repository.listConversations(session.user!.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return AssalStateView<List<AssalConversationSummary>>(
                state: snapshot.data!,
                builder: (items) => ListView.separated(
                  padding: const EdgeInsets.all(AssalSpacing.lg),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AssalSpacing.sm),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: AssalColors.honeyLight, child: Icon(Icons.storefront_outlined, color: AssalColors.primaryDark)),
                        title: Text(item.storeName),
                        subtitle: Text(item.lastMessage),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConversationScreen(repository: repository, conversation: item))),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(padding: const EdgeInsets.all(AssalSpacing.lg), children: [
        Card(child: Column(children: [
          SwitchListTile(value: true, onChanged: (value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value ? 'تم تفعيل الإشعارات في Demo Mode' : 'تم إيقاف الإشعارات في Demo Mode'))), title: const Text('الإشعارات'), secondary: const Icon(Icons.notifications_outlined)),
          const ListTile(leading: Icon(Icons.language), title: Text('اللغة'), subtitle: Text('العربية — RTL')),
          const ListTile(leading: Icon(Icons.palette_outlined), title: Text('المظهر'), subtitle: Text('هوية عسلكم الفاتحة')),
          const ListTile(leading: Icon(Icons.lock_outline), title: Text('الخصوصية والأمان'), subtitle: Text('إعدادات الحساب والصلاحيات')),
          const ListTile(leading: Icon(Icons.info_outline), title: Text('عن عسلكم'), subtitle: Text('منصة اكتشاف وتواصل للعسل اليمني')),
        ])),
      ]),
    );
  }
}

class BecomeMerchantScreen extends StatelessWidget {
  const BecomeMerchantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const steps = ['التعريف بنشاطك وخبرتك', 'إضافة بيانات المتجر وموقعه', 'إرفاق الشهادات ومعلومات المصدر', 'مراجعة التحقق ثم فتح لوحة التاجر'];
    return Scaffold(
      appBar: AppBar(title: const Text('كن تاجرًا')),
      body: ListView(padding: const EdgeInsets.all(AssalSpacing.xl), children: [
        const AssalImageTile(height: 180, icon: Icons.storefront_outlined),
        const SizedBox(height: AssalSpacing.xl),
        Text('حوّل خبرتك إلى متجر موثوق', style: AssalTypography.heading1.copyWith(color: AssalColors.deepBrown)),
        const SizedBox(height: AssalSpacing.sm),
        Text('مسار واضح من التعريف بك إلى إنشاء المتجر ثم التحقق، دون خلطه بتجربة التصفح.', style: AssalTypography.bodyLarge.copyWith(color: AssalColors.textSecondary)),
        const SizedBox(height: AssalSpacing.xl),
        ...steps.asMap().entries.map<Widget>((entry) => ListTile(leading: CircleAvatar(backgroundColor: AssalColors.honeyLight, child: Text('${entry.key + 1}')), title: Text(entry.value), subtitle: const Text('خطوة محفوظة في Demo Mode'))),
        const SizedBox(height: AssalSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('تم بدء مسار التاجر'),
                content: const Text('في Demo Mode تم حفظ الخطوات. في Production ستنتقل البيانات إلى مراجعة التحقق.'),
                actions: [FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('حسنًا'))],
              ),
            ),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('ابدأ طلب التحول إلى تاجر'),
          ),
        ),
      ]),
    );
  }
}
