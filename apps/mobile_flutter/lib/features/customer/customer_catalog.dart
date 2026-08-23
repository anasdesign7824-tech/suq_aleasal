import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_design/assal_tokens.dart';
import '../../core/assal_widgets.dart';
import 'customer_core.dart';
import 'customer_account.dart';
import 'customer_social.dart';

String _productTypeLabel(ProductType type) => switch (type) {
      ProductType.honey => 'عسل',
      ProductType.wax => 'شمع',
      ProductType.mix => 'خلطة',
      ProductType.raw => 'منتج خام',
      ProductType.gift => 'هدية'
    };

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.repository,
    required this.productId,
    this.initialProduct,
    this.merchantMode = false,
    this.onEdit,
  });
  final AssalRepository repository;
  final String productId;
  final AssalProductSummary? initialProduct;
  final bool merchantMode;
  final Future<void> Function()? onEdit;
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<AssalLoadState<AssalProductSummary>> productFuture;
  final Map<String, Future<AssalLoadState<AssalStoreSummary>>> storeFutures =
      <String, Future<AssalLoadState<AssalStoreSummary>>>{};
  final Map<String, Future<AssalLoadState<List<AssalProductSummary>>>>
      similarFutures =
      <String, Future<AssalLoadState<List<AssalProductSummary>>>>{};
  late final PageController galleryController;
  bool liked = false;
  bool favorite = false;
  bool likeBusy = false;
  bool favoriteBusy = false;
  int galleryIndex = 0;
  int likeDelta = 0;
  @override
  void initState() {
    super.initState();
    productFuture = widget.initialProduct != null
        ? Future.value(AssalData(widget.initialProduct!))
        : widget.repository.getProduct(widget.productId);
    galleryController = PageController();
    _trackProductView();
    _loadInteractionState();
  }

  Future<void> _trackProductView() async {
    await widget.repository.trackProductView(widget.productId);
  }

  Future<void> _loadInteractionState() async {
    final session = await widget.repository.getSession();
    if (!session.isAuthenticated || session.user == null) return;
    final result = await widget.repository.loadProductInteractionState(
      session.user!.id,
      widget.productId,
    );
    if (!mounted || result is! AssalData<AssalProductInteractionState>) return;
    setState(() {
      liked = result.value.isLiked;
      favorite = result.value.isFavorited;
    });
  }

  @override
  void dispose() {
    galleryController.dispose();
    super.dispose();
  }

  Future<AssalLoadState<AssalStoreSummary>> _storeFuture(String storeId) =>
      storeFutures.putIfAbsent(
          storeId, () => widget.repository.getStore(storeId));

  Future<void> _toggleFavorite(AssalProductSummary product) async {
    if (favoriteBusy) return;
    final session = await requireUserSession(context, widget.repository);
    if (session == null || !mounted || session.user == null) return;
    setState(() => favoriteBusy = true);
    try {
      final result = await widget.repository.toggleFavorite(
        session.user!.id,
        product.id,
      );
      if (!mounted) return;
      if (result is AssalData<bool>) {
        setState(() => favorite = result.value);
      } else if (result is AssalError<bool>) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.messageAr)),
        );
      }
    } finally {
      if (mounted) setState(() => favoriteBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AssalAppBar(title: 'تفاصيل المنتج', actions: [
        IconButton(
            onPressed: () => _share(),
            icon: const Icon(Icons.share_outlined),
            tooltip: 'مشاركة')
      ]),
      body: FutureBuilder<AssalLoadState<AssalProductSummary>>(
          future: productFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return AssalMessageCard(
                icon: Icons.wifi_off_outlined,
                message:
                    'تعذر تحميل البيانات الآن. تحقق من الاتصال ثم أعد المحاولة.',
                onRetry: () {
                  setState(() {
                    productFuture = widget.repository.getProduct(
                      widget.productId,
                    );
                  });
                },
              );
            }
            if (!snapshot.hasData) return const AssalGlassLoading();
            return AssalStateView<AssalProductSummary>(
                state: snapshot.data!,
                onRetry: () => setState(() => productFuture =
                    widget.repository.getProduct(widget.productId)),
                builder: (product) => _content(product));
          }));

  Widget _content(AssalProductSummary product) =>
      FutureBuilder<AssalLoadState<AssalStoreSummary>>(
        future: _storeFuture(product.storeId),
        builder: (context, storeSnapshot) {
          final store = storeSnapshot.data is AssalData<AssalStoreSummary>
              ? (storeSnapshot.data! as AssalData<AssalStoreSummary>).value
              : null;
          final gallery = product.imageUrls.isEmpty
              ? <String?>[product.primaryImageUrl]
              : product.imageUrls;
          return DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: _productHero(product, gallery, store),
                ),
                SliverToBoxAdapter(
                  child: _decisionCard(product, store),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ProductTabsDelegate(),
                ),
              ],
              body: TabBarView(
                children: [
                  _productInfoTab(product, store),
                  _productInteractionTab(product),
                  _similarProductsTab(product),
                ],
              ),
            ),
          );
        },
      );

  Widget _decisionCard(AssalProductSummary product, AssalStoreSummary? store) {
    final deliveryOptions = product.deliveryOptions.isNotEmpty
        ? product.deliveryOptions
        : store?.deliveryOptions ?? const <String>[];
    final pickupLocations = product.pickupLocations.isNotEmpty
        ? product.pickupLocations
        : store?.pickupLocations ?? const <String>[];
    return Card(
      margin: const EdgeInsets.fromLTRB(
        AssalSpacing.lg,
        AssalSpacing.md,
        AssalSpacing.lg,
        AssalSpacing.sm,
      ),
      color: AssalColors.cream,
      child: Padding(
        padding: const EdgeInsets.all(AssalSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'خيارات التوفر والاستلام',
                    style: AssalTypography.title,
                  ),
                ),
                if (product.availability.isNotEmpty)
                  Chip(
                    label: Text(product.availability),
                    avatar: const Icon(Icons.circle, size: 10),
                  ),
              ],
            ),
            const SizedBox(height: AssalSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    formatAssalPrice(product.price, product.currencyCode),
                    style: AssalTypography.heading3.copyWith(
                      color: AssalColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            if (deliveryOptions.isNotEmpty || pickupLocations.isNotEmpty) ...[
              const SizedBox(height: AssalSpacing.sm),
              Text(
                [
                  if (deliveryOptions.isNotEmpty)
                    'التوصيل: ${deliveryOptions.join('، ')}',
                  if (pickupLocations.isNotEmpty)
                    'الاستلام: ${pickupLocations.join('، ')}',
                ].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AssalTypography.bodySmall.copyWith(
                  color: AssalColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AssalSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    store == null ? null : () => _request(product, store),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('اسأل عن التوفر'),
              ),
            ),
            if (widget.merchantMode && widget.onEdit != null) ...[
              const SizedBox(height: AssalSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('تعديل المنتج'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _productHero(
    AssalProductSummary product,
    List<String?> gallery,
    AssalStoreSummary? store,
  ) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(
            AssalSpacing.lg, AssalSpacing.lg, AssalSpacing.lg, 0),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AssalRadius.large),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: PageView.builder(
                      controller: galleryController,
                      itemCount: gallery.length,
                      onPageChanged: (index) =>
                          setState(() => galleryIndex = index),
                      itemBuilder: (_, index) => AssalImageTile(
                        imageUrl: gallery[index],
                        expand: true,
                        icon: index.isEven
                            ? Icons.wb_sunny_outlined
                            : Icons.hive_outlined,
                      ),
                    ),
                  ),
                  Positioned(
                    left: AssalSpacing.md,
                    bottom: AssalSpacing.md,
                    child: IconButton.filledTonal(
                      onPressed:
                          favoriteBusy ? null : () => _toggleFavorite(product),
                      tooltip: favorite ? 'إزالة الحفظ' : 'حفظ المنتج',
                      icon: Icon(
                        favorite ? Icons.favorite : Icons.favorite_border,
                      ),
                    ),
                  ),
                  if (product.categoryNameAr != null)
                    Positioned(
                      right: AssalSpacing.md,
                      top: AssalSpacing.md,
                      child: Chip(
                        label: Text(product.categoryNameAr!),
                        avatar: const Icon(Icons.local_florist_outlined),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AssalSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                gallery.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: index == galleryIndex ? 22 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == galleryIndex
                        ? AssalColors.primaryDark
                        : AssalColors.border,
                    borderRadius: BorderRadius.circular(AssalRadius.pill),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AssalSpacing.md),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                product.nameAr,
                style: AssalTypography.heading1
                    .copyWith(color: AssalColors.deepBrown),
              ),
            ),
            const SizedBox(height: AssalSpacing.xs),
            Row(
              children: [
                const Icon(Icons.star, size: 18, color: AssalColors.honey),
                const SizedBox(width: AssalSpacing.xs),
                Text(product.ratingAverage.toStringAsFixed(1)),
                const SizedBox(width: AssalSpacing.sm),
                Text('${product.reviewCount} مراجعة',
                    style: AssalTypography.caption
                        .copyWith(color: AssalColors.textMuted)),
                const SizedBox(width: AssalSpacing.sm),
                Text('${product.likesCount + likeDelta} إعجاب',
                    style: AssalTypography.caption
                        .copyWith(color: AssalColors.textMuted)),
              ],
            ),
            if (store != null) ...[
              const SizedBox(height: AssalSpacing.md),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AssalColors.honeyLight,
                    child: Icon(
                      Icons.storefront_outlined,
                      color: AssalColors.primaryDark,
                    ),
                  ),
                  title: Text(store.nameAr),
                  subtitle: Text(store.regionNameAr ?? 'الموقع غير محدد'),
                  trailing: const Icon(Icons.chevron_left),
                ),
              ),
            ],
          ],
        ),
      );

  Widget _productInfoTab(
          AssalProductSummary product, AssalStoreSummary? store) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(AssalSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AssalSpacing.sm,
              runSpacing: AssalSpacing.sm,
              children: [
                if (product.subcategoryNameAr != null)
                  InfoChip(label: product.subcategoryNameAr!),
                if (product.regionNameAr != null)
                  InfoChip(label: product.regionNameAr!),
                if (product.gradeLevel != null)
                  InfoChip(
                      label: 'الجودة: درجة ${product.gradeLevel}',
                      icon: Icons.verified_outlined),
              ],
            ),
            if (product.description != null) ...[
              const SizedBox(height: AssalSpacing.lg),
              const SectionHeader(title: 'الوصف'),
              Text(product.description!, style: AssalTypography.bodyLarge),
            ],
            if (product.tags.isNotEmpty) ...[
              const SizedBox(height: AssalSpacing.lg),
              const SectionHeader(title: 'لماذا قد يناسبك؟'),
              Wrap(
                spacing: AssalSpacing.sm,
                runSpacing: AssalSpacing.sm,
                children: product.tags
                    .map<Widget>((tag) => InfoChip(label: tag))
                    .toList(),
              ),
            ],
            const SizedBox(height: AssalSpacing.lg),
            _MetadataCard(product: product, store: store),
            if (store != null) ...[
              const SizedBox(height: AssalSpacing.lg),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AssalColors.honeyLight,
                    child: Icon(Icons.storefront_outlined,
                        color: AssalColors.primaryDark),
                  ),
                  title: Text(store.nameAr),
                  subtitle: Text(
                    'متجر على منصة عسلكم${store.regionNameAr == null ? '' : ' · ${store.regionNameAr}'}',
                  ),
                  trailing: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StoreProfileScreen(
                            repository: widget.repository, storeId: store.id),
                      ),
                    ),
                    child: const Text('فتح المتجر'),
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  Widget _productInteractionTab(AssalProductSummary product) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(AssalSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: likeBusy
                        ? null
                        : () async {
                            final session = await requireUserSession(
                                context, widget.repository);
                            if (session == null ||
                                !mounted ||
                                session.user == null) {
                              return;
                            }
                            setState(() => likeBusy = true);
                            try {
                              final result = await widget.repository
                                  .toggleLike(session.user!.id, product.id);
                              if (result is AssalData<bool>) {
                                setState(() {
                                  if (result.value != liked) {
                                    likeDelta += result.value ? 1 : -1;
                                  }
                                  liked = result.value;
                                });
                              } else if (result is AssalError<bool> &&
                                  mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result.messageAr)),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => likeBusy = false);
                            }
                          },
                    icon:
                        Icon(liked ? Icons.thumb_up : Icons.thumb_up_outlined),
                    label: Text(liked ? 'أعجبتني' : 'إعجاب'),
                  ),
                ),
                const SizedBox(width: AssalSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        favoriteBusy ? null : () => _toggleFavorite(product),
                    icon:
                        Icon(favorite ? Icons.bookmark : Icons.bookmark_border),
                    label: Text(favorite ? 'محفوظ' : 'حفظ'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AssalSpacing.lg),
            Card(
              color: AssalColors.cream,
              child: Padding(
                padding: const EdgeInsets.all(AssalSpacing.lg),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: AssalColors.honey, size: 34),
                    const SizedBox(width: AssalSpacing.md),
                    Text(
                      product.ratingAverage.toStringAsFixed(1),
                      style: AssalTypography.heading2.copyWith(
                        color: AssalColors.deepBrown,
                      ),
                    ),
                    const SizedBox(width: AssalSpacing.sm),
                    Text(
                      'من 5\n(${product.reviewCount} تقييم)',
                      style: AssalTypography.body.copyWith(
                        color: AssalColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AssalSpacing.xl),
            ReviewsSection(repository: widget.repository, product: product),
            const SizedBox(height: AssalSpacing.xl),
            CommentsSection(
                repository: widget.repository, targetId: product.id),
          ],
        ),
      );

  Widget _similarProductsTab(AssalProductSummary product) {
    if (product.taxonomyId == null) {
      return const Padding(
        padding: EdgeInsets.all(AssalSpacing.lg),
        child: AssalMessageCard(
          icon: Icons.category_outlined,
          message: 'لا تتوفر منتجات مشابهة لهذا التصنيف بعد.',
        ),
      );
    }

    final future = similarFutures.putIfAbsent(
      product.id,
      () => widget.repository.listProducts(
        query: AssalProductQuery(subcategoryId: product.taxonomyId),
      ),
    );
    void retry() {
      setState(() {
        similarFutures.remove(product.id);
      });
    }

    return Padding(
      padding: const EdgeInsets.all(AssalSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'المنتجات المشابهة'),
          const SizedBox(height: AssalSpacing.sm),
          Expanded(
            child: FutureBuilder<AssalLoadState<List<AssalProductSummary>>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return AssalMessageCard(
                    icon: Icons.wifi_off_outlined,
                    message:
                        'تعذر تحميل المنتجات المشابهة الآن. تحقق من الاتصال ثم أعد المحاولة.',
                    onRetry: retry,
                  );
                }
                if (!snapshot.hasData) return const AssalGlassLoading();
                return AssalStateView<List<AssalProductSummary>>(
                  state: snapshot.data!,
                  onRetry: retry,
                  builder: (items) {
                    final similar =
                        items.where((item) => item.id != product.id).toList();
                    if (similar.isEmpty) {
                      return AssalMessageCard(
                        icon: Icons.inventory_2_outlined,
                        message: 'لا توجد منتجات مشابهة منشورة بعد.',
                        onRetry: retry,
                      );
                    }
                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        crossAxisSpacing: AssalSpacing.md,
                        mainAxisSpacing: AssalSpacing.md,
                        childAspectRatio: .48,
                      ),
                      itemCount: similar.length,
                      itemBuilder: (_, index) {
                        final item = similar[index];
                        return ProductCard(
                          product: item,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(
                                repository: widget.repository,
                                productId: item.id,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _request(
      AssalProductSummary product, AssalStoreSummary? store) async {
    if (store == null) return;
    final session = await requireUserSession(context, widget.repository);
    if (session == null || !mounted) return;
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => RequestSheet(
            repository: widget.repository, product: product, store: store));
  }

  Future<void> _share() async {
    final text = 'منتج من سوق عسلكم\\nمعرّف المنتج: ${widget.productId}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ بطاقة المنتج للمشاركة.')),
    );
  }
}

class _ProductTabsDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.lg),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AssalColors.darkGradient,
            borderRadius: BorderRadius.circular(AssalRadius.medium),
          ),
          child: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: AssalColors.honey,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'معلومات المنتج'),
              Tab(text: 'التقييمات والتفاعل'),
              Tab(text: 'منتجات مشابهة'),
            ],
          ),
        ),
      );

  @override
  bool shouldRebuild(covariant _ProductTabsDelegate oldDelegate) => false;
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.product, this.store});
  final AssalProductSummary product;
  final AssalStoreSummary? store;

  @override
  Widget build(BuildContext context) => Card(
        color: AssalColors.cream,
        child: Padding(
          padding: const EdgeInsets.all(AssalSpacing.lg),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('بيانات المصدر والجودة',
                style: AssalTypography.heading3
                    .copyWith(color: AssalColors.deepBrown)),
            const SizedBox(height: AssalSpacing.md),
            _row('نوع المنتج', _productTypeLabel(product.productType)),
            if (product.honeyIdentity != null)
              _row('هوية العسل', product.honeyIdentity!),
            _row(
              'المنطقة',
              product.regionNameAr ?? store?.regionNameAr ?? 'غير محددة',
            ),
            if (product.provinceNameAr != null)
              _row('المحافظة', product.provinceNameAr!),
            if (product.originCountry != null)
              _row('بلد الأصل', product.originCountry!),
            _row('التصنيف', product.subcategoryNameAr ?? 'غير محدد'),
            if (product.qualityLabelAr != null)
              _row('الجودة', product.qualityLabelAr!),
            if (product.components.isNotEmpty)
              _row('المكونات', product.components.join('، ')),
            if (product.processingMethodAr != null)
              _row('المعالجة', product.processingMethodAr!),
            if (product.processingStatusAr != null)
              _row('حالة المعالجة', product.processingStatusAr!),
            if (product.packagingLabelAr != null)
              _row('التعبئة', product.packagingLabelAr!),
            if (product.productionDate != null)
              _row('تاريخ الإنتاج', _dateLabel(product.productionDate)),
            if (product.packagedDate != null)
              _row('تاريخ التعبئة', _dateLabel(product.packagedDate)),
            if (product.shelfLifeLabelAr != null)
              _row('الصلاحية', product.shelfLifeLabelAr!),
            if (product.weightLabel != null)
              _row('الوزن', product.weightLabel!),
            if (product.harvestLabel != null)
              _row('القطفة', product.harvestLabel!),
            if (product.deliveryOptions.isNotEmpty)
              _row('التسليم', product.deliveryOptions.join('، ')),
            if (product.pickupLocations.isNotEmpty)
              _row('الاستلام', product.pickupLocations.join('، ')),
          ]),
        ),
      );

  Widget _row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AssalSpacing.xs),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 96,
            child: Text(label,
                style: AssalTypography.bodySmall
                    .copyWith(color: AssalColors.textMuted))),
        Expanded(
            child: Text(value,
                style: AssalTypography.body
                    .copyWith(color: AssalColors.textPrimary)))
      ]));
}

String _dateLabel(DateTime? date) => date == null
    ? 'غير محدد'
    : '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

class StoreProfileScreen extends StatefulWidget {
  const StoreProfileScreen(
      {super.key, required this.repository, required this.storeId});
  final AssalRepository repository;
  final String storeId;
  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  late Future<AssalLoadState<AssalStoreSummary>> storeFuture;
  late Future<AssalLoadState<List<AssalProductSummary>>> productsFuture;
  bool following = false;
  int followerDelta = 0;
  bool followBusy = false;
  bool followersBusy = false;
  bool contactBusy = false;
  final Set<String> favoriteProductIds = <String>{};
  final Set<String> favoriteProductBusyIds = <String>{};

  @override
  void initState() {
    super.initState();
    storeFuture = widget.repository.getStore(widget.storeId);
    productsFuture = widget.repository
        .listProducts(query: AssalProductQuery(storeId: widget.storeId));
    _loadFollowState();
  }

  Future<void> _loadFollowState() async {
    final session = await widget.repository.getSession();
    if (!session.isAuthenticated || session.user == null) return;
    final result = await widget.repository.listFollowedStores(session.user!.id);
    if (!mounted || result is! AssalData<List<AssalStoreSummary>>) return;
    setState(() {
      following = result.value.any((store) => store.id == widget.storeId);
    });
  }

  void _reloadStore() {
    setState(() {
      storeFuture = widget.repository.getStore(widget.storeId);
    });
  }

  void _reloadProducts() {
    setState(() {
      productsFuture = widget.repository.listProducts(
        query: AssalProductQuery(storeId: widget.storeId),
      );
    });
  }

  Future<void> _toggleProductFavorite(AssalProductSummary product) async {
    if (favoriteProductBusyIds.contains(product.id)) return;
    final session = await requireUserSession(context, widget.repository);
    if (session == null || !mounted || session.user == null) return;
    setState(() {
      favoriteProductBusyIds.add(product.id);
    });
    try {
      final result = await widget.repository.toggleFavorite(
        session.user!.id,
        product.id,
      );
      if (!mounted) return;
      if (result is AssalData<bool>) {
        setState(() {
          if (result.value) {
            favoriteProductIds.add(product.id);
          } else {
            favoriteProductIds.remove(product.id);
          }
        });
      } else if (result is AssalError<bool>) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.messageAr)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          favoriteProductBusyIds.remove(product.id);
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (followBusy) return;
    final session = await requireUserSession(context, widget.repository);
    if (session == null || !mounted || session.user == null) return;
    setState(() => followBusy = true);
    try {
      final result = await widget.repository.toggleFollow(
        session.user!.id,
        widget.storeId,
      );
      if (!mounted) return;
      if (result is AssalData<bool>) {
        setState(() {
          if (result.value != following) {
            followerDelta += result.value ? 1 : -1;
          }
          following = result.value;
        });
      } else if (result is AssalError<bool>) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.messageAr)),
        );
      }
    } finally {
      if (mounted) setState(() => followBusy = false);
    }
  }

  Future<void> _showFollowers(AssalStoreSummary store) async {
    if (followersBusy) return;
    setState(() => followersBusy = true);
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _StoreFollowersSheet(
          loadPage: () => widget.repository.listStoreFollowers(widget.storeId),
          totalFallback: store.followersCount,
        ),
      );
    } finally {
      if (mounted) setState(() => followersBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AssalAppBar(title: 'صفحة المتجر'),
      body: FutureBuilder<AssalLoadState<AssalStoreSummary>>(
        future: storeFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AssalMessageCard(
              icon: Icons.wifi_off_outlined,
              message:
                  'تعذر تحميل البيانات الآن. تحقق من الاتصال ثم أعد المحاولة.',
              onRetry: _reloadStore,
            );
          }
          if (!snapshot.hasData) return const AssalGlassLoading();
          return AssalStateView<AssalStoreSummary>(
            state: snapshot.data!,
            onRetry: _reloadStore,
            builder: _content,
          );
        },
      ),
    );
  }

  Widget _content(AssalStoreSummary store) => DefaultTabController(
        length: 3,
        child: Column(
          children: [
            _storeHeader(store),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AssalSpacing.lg),
              decoration: BoxDecoration(
                gradient: AssalColors.darkGradient,
                borderRadius: BorderRadius.circular(AssalRadius.medium),
              ),
              child: const TabBar(
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: AssalColors.honey,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'المنتجات'),
                  Tab(text: 'معلومات المتجر'),
                  Tab(text: 'التواصل'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _productsTab(store),
                  _storeInfoTab(store),
                  _contactTab(store),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _storeHeader(AssalStoreSummary store) {
    final displayedFollowers = store.followersCount + followerDelta;
    return AssalStoreHeaderCard(
      store: store,
      isFollowing: following,
      followBusy: followBusy,
      onFollow: _toggleFollow,
      onFollowersTap: followersBusy ? null : () => _showFollowers(store),
      followersCountOverride: displayedFollowers < 0 ? 0 : displayedFollowers,
    );
  }

  Widget _productsTab(AssalStoreSummary store) =>
      FutureBuilder<AssalLoadState<List<AssalProductSummary>>>(
        future: productsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return SingleChildScrollView(
              child: AssalMessageCard(
                icon: Icons.wifi_off_outlined,
                message:
                    'تعذر تحميل البيانات الآن. تحقق من الاتصال ثم أعد المحاولة.',
                onRetry: _reloadProducts,
              ),
            );
          }
          if (!snapshot.hasData) return const AssalGlassLoading();
          final state = snapshot.data!;
          if (state is AssalData<List<AssalProductSummary>> &&
              state.value.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(AssalSpacing.lg),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    AssalMessageCard(
                      icon: Icons.inventory_2_outlined,
                      message: 'لا توجد منتجات منشورة في هذا المتجر بعد.',
                      onRetry: _reloadProducts,
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('العودة إلى المتاجر'),
                    ),
                  ],
                ),
              ),
            );
          }
          final hasProducts = state is AssalData<List<AssalProductSummary>> &&
              state.value.isNotEmpty;
          final stateView = AssalStateView<List<AssalProductSummary>>(
            state: state,
            onRetry: _reloadProducts,
            builder: (products) => GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                crossAxisSpacing: AssalSpacing.md,
                mainAxisSpacing: AssalSpacing.md,
                mainAxisExtent: 400,
              ),
              itemCount: products.length,
              itemBuilder: (_, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  onFavorite: favoriteProductBusyIds.contains(product.id)
                      ? null
                      : () => _toggleProductFavorite(product),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(
                        repository: widget.repository,
                        productId: product.id,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
          return Padding(
            padding: const EdgeInsets.all(AssalSpacing.lg),
            child: hasProducts
                ? stateView
                : SingleChildScrollView(child: stateView),
          );
        },
      );

  Widget _storeInfoTab(AssalStoreSummary store) => SingleChildScrollView(
        padding: const EdgeInsets.all(AssalSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (store.galleryUrls.isNotEmpty) ...[
              const SectionHeader(title: 'من المتجر'),
              SizedBox(
                height: 106,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: store.galleryUrls.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AssalSpacing.sm),
                  itemBuilder: (_, index) => SizedBox(
                    width: 132,
                    child: AssalImageTile(
                      imageUrl: store.galleryUrls[index],
                      height: 106,
                      icon: index.isEven
                          ? Icons.hive_outlined
                          : Icons.storefront_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AssalSpacing.xl),
            ],
            const SectionHeader(title: 'عن المتجر'),
            Text(
              store.bio ??
                  store.description ??
                  'لم يضف المتجر نبذة تعريفية بعد.',
              style: AssalTypography.bodyLarge,
            ),
            const SizedBox(height: AssalSpacing.xl),
            const SectionHeader(title: 'الموقع والتخصصات'),
            if (store.regionNameAr != null)
              _storeInfoRow(
                  Icons.location_on_outlined, 'المنطقة', store.regionNameAr!),
            if (store.yearsExperience > 0)
              _storeInfoRow(
                Icons.workspace_premium_outlined,
                'سنوات الخبرة',
                '${store.yearsExperience} سنة',
              ),
            if (store.specialties.isEmpty)
              const AssalMessageCard(
                icon: Icons.info_outline,
                message: 'لم يضف المتجر تخصصاته بعد.',
              )
            else
              Wrap(
                spacing: AssalSpacing.sm,
                runSpacing: AssalSpacing.sm,
                children: store.specialties
                    .map<Widget>((item) => InfoChip(label: item))
                    .toList(),
              ),
            if (store.certifications.isNotEmpty) ...[
              const SizedBox(height: AssalSpacing.lg),
              const SectionHeader(title: 'التوثيقات'),
              Wrap(
                spacing: AssalSpacing.sm,
                runSpacing: AssalSpacing.sm,
                children: store.certifications
                    .map<Widget>((item) => InfoChip(
                          label: item,
                          icon: Icons.verified_outlined,
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: AssalSpacing.lg),
            const SectionHeader(title: 'طرق التوصيل'),
            if (store.deliveryOptions.isEmpty)
              const AssalMessageCard(
                icon: Icons.local_shipping_outlined,
                message: 'لم يحدد المتجر طرق التوصيل بعد.',
              )
            else
              ...store.deliveryOptions.map(
                (item) => _storeInfoRow(
                  Icons.local_shipping_outlined,
                  'التوصيل',
                  item,
                ),
              ),
            const SizedBox(height: AssalSpacing.lg),
            const SectionHeader(title: 'نقاط الاستلام'),
            if (store.pickupLocations.isEmpty)
              const AssalMessageCard(
                icon: Icons.location_on_outlined,
                message: 'لم يحدد المتجر نقاط الاستلام بعد.',
              )
            else
              ...store.pickupLocations.map(
                (item) => _storeInfoRow(
                  Icons.location_on_outlined,
                  'نقطة الاستلام',
                  item,
                ),
              ),
          ],
        ),
      );

  Widget _contactTab(AssalStoreSummary store) {
    final socialLinks = _publicSocialLinks(store);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AssalSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'قنوات التواصل'),
          if (socialLinks.isEmpty &&
              (store.contactPhone == null ||
                  store.contactPhone!.trim().isEmpty))
            const AssalMessageCard(
              icon: Icons.forum_outlined,
              message: 'لم يضف المتجر قنوات تواصل بعد.',
            )
          else
            Wrap(
              spacing: AssalSpacing.sm,
              runSpacing: AssalSpacing.sm,
              children: [
                if (store.contactPhone != null &&
                    store.contactPhone!.trim().isNotEmpty)
                  ActionChip(
                    avatar: const Icon(Icons.phone_outlined, size: 16),
                    label: const Text('الهاتف'),
                    onPressed: () => _openContact('phone', store.contactPhone!),
                  ),
                ...socialLinks.entries.map(
                  (entry) => ActionChip(
                    avatar: Icon(_socialIcon(entry.key), size: 16),
                    label: Text(_socialLabel(entry.key)),
                    onPressed: () => _openContact(entry.key, entry.value),
                  ),
                ),
              ],
            ),
          const SizedBox(height: AssalSpacing.lg),
          const SectionHeader(title: 'التسليم والاستلام'),
          if (store.deliveryOptions.isEmpty && store.pickupLocations.isEmpty)
            const AssalMessageCard(
              icon: Icons.local_shipping_outlined,
              message: 'لم يحدد المتجر خيارات التسليم أو الاستلام بعد.',
            )
          else ...[
            if (store.deliveryOptions.isNotEmpty)
              _storeInfoRow(Icons.local_shipping_outlined, 'التوصيل',
                  store.deliveryOptions.join('، ')),
            if (store.pickupLocations.isNotEmpty)
              _storeInfoRow(Icons.location_on_outlined, 'الاستلام',
                  store.pickupLocations.join('، ')),
          ],
          const SizedBox(height: AssalSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: contactBusy ? null : () => _openConversation(store),
              icon: contactBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.forum_outlined),
              label:
                  Text(contactBusy ? 'جارٍ فتح المراسلة...' : 'مراسلة التاجر'),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _publicSocialLinks(AssalStoreSummary store) {
    final links = <String, String>{...store.socialLinks};
    if (store.contactWhatsapp != null &&
        store.contactWhatsapp!.trim().isNotEmpty) {
      links['whatsapp'] = store.contactWhatsapp!;
    }
    if (store.contactTelegram != null &&
        store.contactTelegram!.trim().isNotEmpty) {
      links['telegram'] = store.contactTelegram!;
    }
    return links;
  }

  IconData _socialIcon(String key) => switch (key) {
        'whatsapp' => Icons.chat_outlined,
        'telegram' => Icons.send_outlined,
        'facebook' => Icons.facebook_outlined,
        'instagram' => Icons.camera_alt_outlined,
        'website' => Icons.language_outlined,
        _ => Icons.link,
      };

  Future<void> _openConversation(AssalStoreSummary store) async {
    if (contactBusy) return;
    final session = await requireUserSession(context, widget.repository);
    if (session == null || !mounted || session.user == null) return;
    final firstMessage = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => NewConversationSheet(store: store),
    );
    if (!mounted || firstMessage == null || firstMessage.trim().isEmpty) return;
    setState(() => contactBusy = true);
    try {
      final result = await widget.repository
          .createConversation(session.user!.id, store.id);
      if (!mounted) return;
      if (result is AssalData<AssalConversationSummary>) {
        final sent = await widget.repository.sendMessage(
          session.user!.id,
          AssalMessageDraft(
            conversationId: result.value.id,
            body: firstMessage.trim(),
          ),
        );
        if (!mounted) return;
        if (sent is AssalError<AssalMessageSummary>) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(sent.messageAr)),
          );
        }
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ConversationScreen(
            repository: widget.repository,
            conversation: result.value,
          ),
        ));
      } else if (result is AssalError<AssalConversationSummary>) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.messageAr)),
        );
      }
    } finally {
      if (mounted) setState(() => contactBusy = false);
    }
  }

  Future<void> _openContact(String channel, String value) async {
    final uri = _contactUri(channel, value);
    final opened = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened || !mounted) return;
    await _showContactFallback(channel, value);
  }

  Uri? _contactUri(String channel, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (channel == 'phone') {
      final phone = trimmed.replaceAll(RegExp(r'[\s()-]'), '');
      return phone.isEmpty ? null : Uri(scheme: 'tel', path: phone);
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !{'http', 'https'}.contains(uri.scheme.toLowerCase())) {
      return null;
    }
    return uri;
  }

  Future<void> _showContactFallback(String channel, String value) =>
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('بيانات ${_socialLabel(channel)}'),
          content: SelectableText(value),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );

  Widget _storeInfoRow(IconData icon, String label, String value) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AssalColors.primaryDark),
      title: Text(label),
      subtitle: Text(value));
}

class _StoreFollowersSheet extends StatefulWidget {
  const _StoreFollowersSheet({
    required this.loadPage,
    required this.totalFallback,
  });

  final Future<AssalLoadState<AssalStoreFollowersPage>> Function() loadPage;
  final int totalFallback;

  @override
  State<_StoreFollowersSheet> createState() => _StoreFollowersSheetState();
}

class _StoreFollowersSheetState extends State<_StoreFollowersSheet> {
  late Future<AssalLoadState<AssalStoreFollowersPage>> pageFuture;

  @override
  void initState() {
    super.initState();
    pageFuture = widget.loadPage();
  }

  void _retry() {
    setState(() {
      pageFuture = widget.loadPage();
    });
  }

  @override
  Widget build(BuildContext context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .86,
        ),
        decoration: const BoxDecoration(
          color: AssalColors.cream,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AssalRadius.large),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AssalSpacing.sm),
            Container(
              width: 56,
              height: 5,
              decoration: BoxDecoration(
                color: AssalColors.textMuted.withValues(alpha: .3),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AssalSpacing.lg,
                AssalSpacing.md,
                AssalSpacing.sm,
                AssalSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child:
                        FutureBuilder<AssalLoadState<AssalStoreFollowersPage>>(
                      future: pageFuture,
                      builder: (context, snapshot) {
                        final total =
                            snapshot.data is AssalData<AssalStoreFollowersPage>
                                ? (snapshot.data!
                                        as AssalData<AssalStoreFollowersPage>)
                                    .value
                                    .total
                                : widget.totalFallback;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'متابعو المتجر',
                              style: AssalTypography.heading2,
                            ),
                            Text(
                              'إجمالي المتابعين: ${_formatCompactCount(total)}',
                              style: AssalTypography.body.copyWith(
                                color: AssalColors.textSecondary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'إغلاق',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: FutureBuilder<AssalLoadState<AssalStoreFollowersPage>>(
                future: pageFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return SingleChildScrollView(
                      child: AssalMessageCard(
                        icon: Icons.wifi_off_outlined,
                        message:
                            'تعذر تحميل المتابعين الآن. تحقق من الاتصال ثم أعد المحاولة.',
                        onRetry: _retry,
                      ),
                    );
                  }
                  if (!snapshot.hasData) return const AssalGlassLoading();
                  return AssalStateView<AssalStoreFollowersPage>(
                    state: snapshot.data!,
                    onRetry: _retry,
                    emptyMessageAr: 'لا يوجد متابعون ظاهرون بعد.',
                    builder: (page) => page.items.isEmpty
                        ? AssalMessageCard(
                            icon: Icons.people_outline,
                            message: 'لا يوجد متابعون ظاهرون بعد.',
                            onRetry: _retry,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AssalSpacing.lg),
                            itemCount: page.items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AssalSpacing.sm),
                            itemBuilder: (_, index) {
                              final follower = page.items[index];
                              final avatar = follower.avatarUrl;
                              return Card(
                                margin: EdgeInsets.zero,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AssalSpacing.md,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundImage: avatar != null &&
                                            avatar.startsWith('http')
                                        ? NetworkImage(avatar)
                                        : null,
                                    child: avatar == null ||
                                            !avatar.startsWith('http')
                                        ? const Icon(Icons.person_outline)
                                        : null,
                                  ),
                                  title: Text(follower.displayName),
                                  subtitle: Text(
                                    follower.followedAt == null
                                        ? 'تاريخ المتابعة غير متاح'
                                        : 'تاريخ المتابعة: ${_formatFollowerDate(follower.followedAt!)}',
                                  ),
                                ),
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      );
}

String _formatCompactCount(int count) {
  if (count < 1000) return '$count';
  final value = count / 1000;
  return '${value.toStringAsFixed(value >= 10 ? 0 : 1)}K';
}

String _formatFollowerDate(DateTime date) {
  const months = <String>[
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _socialLabel(String key) => switch (key) {
      'whatsapp' => 'واتساب',
      'instagram' => 'إنستغرام',
      'telegram' => 'تلغرام',
      'facebook' => 'فيسبوك',
      'website' => 'الموقع الإلكتروني',
      _ => key
    };

class RequestSheet extends StatefulWidget {
  const RequestSheet(
      {super.key,
      required this.repository,
      required this.product,
      required this.store});
  final AssalRepository repository;
  final AssalProductSummary product;
  final AssalStoreSummary store;
  @override
  State<RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<RequestSheet> {
  final bodyController = TextEditingController(
      text: 'أرغب في معرفة تفاصيل المنتج والتوفر الحالي.');
  final phoneController = TextEditingController();
  final priceNoteController = TextEditingController();
  final deliveryNoteController = TextEditingController();
  int quantity = 1;
  HandoffOption option = HandoffOption.contact;
  String contactChannel = 'in_app';
  String? selectedDeliveryOption;
  String? selectedPickupLocation;
  bool saving = false;

  @override
  void dispose() {
    bodyController.dispose();
    phoneController.dispose();
    priceNoteController.dispose();
    deliveryNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: AssalSpacing.xl,
          right: AssalSpacing.xl,
          top: AssalSpacing.xl,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AssalSpacing.xl),
      child: SingleChildScrollView(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اسأل عن التوفر',
                style: AssalTypography.heading2
                    .copyWith(color: AssalColors.deepBrown),
              ),
              const SizedBox(height: AssalSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: AssalImageTile(
                      imageUrl: widget.product.primaryImageUrl ??
                          (widget.product.imageUrls.isNotEmpty
                              ? widget.product.imageUrls.first
                              : null),
                      height: 76,
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                  const SizedBox(width: AssalSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.nameAr,
                          style: AssalTypography.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AssalSpacing.xs),
                        Text(widget.store.nameAr),
                        if (widget.store.regionNameAr != null)
                          Text(
                            widget.store.regionNameAr!,
                            style: AssalTypography.bodySmall.copyWith(
                              color: AssalColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AssalSpacing.lg),
              TextField(
                  controller: bodyController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'رسالتك', hintText: 'اكتب ما تريد معرفته')),
              const SizedBox(height: AssalSpacing.md),
              TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'رقم للتواصل (اختياري)')),
              const SizedBox(height: AssalSpacing.md),
              TextField(
                  controller: priceNoteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'السعر أو ملاحظة السعر (اختياري)',
                      hintText: 'مثال: هل يتوفر سعر الجملة؟')),
              const SizedBox(height: AssalSpacing.md),
              TextField(
                  controller: deliveryNoteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'ملاحظات التوصيل (اختياري)',
                      hintText: 'مثال: التواصل قبل الوصول')),
              const SizedBox(height: AssalSpacing.md),
              DropdownButtonFormField<HandoffOption>(
                  isExpanded: true,
                  initialValue: option,
                  decoration:
                      const InputDecoration(labelText: 'طريقة التسليم المفضلة'),
                  items: HandoffOption.values
                      .map<DropdownMenuItem<HandoffOption>>((item) =>
                          DropdownMenuItem(
                              value: item, child: Text(item.labelAr)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => option = value);
                  }),
              if (widget.store.deliveryOptions.isNotEmpty) ...[
                const SizedBox(height: AssalSpacing.md),
                DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedDeliveryOption,
                    decoration: const InputDecoration(
                        labelText: 'خيار التوصيل من هذا المتجر'),
                    items: widget.store.deliveryOptions
                        .map((value) => DropdownMenuItem<String>(
                            value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedDeliveryOption = value)),
              ],
              if (widget.store.pickupLocations.isNotEmpty) ...[
                const SizedBox(height: AssalSpacing.md),
                DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedPickupLocation,
                    decoration: const InputDecoration(
                        labelText: 'نقطة الاستلام من هذا المتجر'),
                    items: widget.store.pickupLocations
                        .map((value) => DropdownMenuItem<String>(
                            value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedPickupLocation = value)),
              ],
              const SizedBox(height: AssalSpacing.md),
              const Text(
                'طريقة التواصل المفضلة',
                style: AssalTypography.subtitle,
              ),
              const SizedBox(height: AssalSpacing.sm),
              Wrap(
                spacing: AssalSpacing.sm,
                runSpacing: AssalSpacing.sm,
                children: _contactChannels()
                    .entries
                    .map(
                      (entry) => ChoiceChip(
                        selected: contactChannel == entry.key,
                        label: Text(entry.value),
                        avatar: Icon(_contactChannelIcon(entry.key), size: 16),
                        onSelected: saving
                            ? null
                            : (_) => setState(
                                  () => contactChannel = entry.key,
                                ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AssalSpacing.md),
              Row(children: [
                const Text('الكمية'),
                IconButton(
                    onPressed: () => setState(() {
                          if (quantity > 1) quantity--;
                        }),
                    icon: const Icon(Icons.remove_circle_outline)),
                Text('$quantity', style: AssalTypography.title),
                IconButton(
                    onPressed: () => setState(() => quantity++),
                    icon: const Icon(Icons.add_circle_outline)),
              ]),
              const SizedBox(height: AssalSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          saving ? null : () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: AssalSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: saving ? null : _submit,
                      child: saving
                          ? const AssalGlassLoading(
                              height: 44, label: 'جارٍ الإرسال...')
                          : const Text('إرسال الطلب'),
                    ),
                  ),
                ],
              ),
            ]),
      ),
    );
  }

  Map<String, String> _contactChannels() {
    final channels = <String, String>{'in_app': 'داخل عسلكم'};
    if (widget.store.contactPhone?.trim().isNotEmpty ?? false) {
      channels['phone'] = 'الهاتف';
    }
    if (widget.store.contactWhatsapp?.trim().isNotEmpty ?? false) {
      channels['whatsapp'] = 'واتساب';
    }
    if (widget.store.contactTelegram?.trim().isNotEmpty ?? false) {
      channels['telegram'] = 'تلغرام';
    }
    if (widget.store.socialLinks['website']?.trim().isNotEmpty ?? false) {
      channels['website'] = 'الموقع';
    }
    return channels;
  }

  IconData _contactChannelIcon(String channel) => switch (channel) {
        'phone' => Icons.phone_outlined,
        'whatsapp' => Icons.chat_outlined,
        'telegram' => Icons.send_outlined,
        'website' => Icons.location_on_outlined,
        _ => Icons.hive_outlined,
      };

  Future<void> _submit() async {
    final body = bodyController.text.trim();
    if (body.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اكتب رسالة أوضح للتاجر.')));
      return;
    }
    setState(() => saving = true);
    final session = await widget.repository.getSession();
    if (!session.isAuthenticated || session.user == null) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('سجّل الدخول أولًا لإرسال الطلب.')),
        );
      }
      return;
    }
    final selectedHandoffOption = selectedDeliveryOption != null
        ? HandoffOption.delivery
        : selectedPickupLocation != null
            ? HandoffOption.pickup
            : option;
    final handoffDetails = <String, Object?>{
      'quantity_label': '$quantity',
      'source': 'customer_request',
      if (selectedDeliveryOption != null)
        'delivery_option_label': selectedDeliveryOption,
      if (selectedPickupLocation != null)
        'pickup_location_label': selectedPickupLocation,
    };
    final result = await widget.repository.createRequest(
        session.user!.id,
        AssalRequestDraft(
            storeId: widget.store.id,
            productId: widget.product.id,
            subject: 'استفسار عن ${widget.product.nameAr}',
            body: body,
            quantity: quantity,
            phone: phoneController.text.trim().isEmpty
                ? null
                : phoneController.text.trim(),
            handoffOption: selectedHandoffOption,
            deliveryNote: deliveryNoteController.text.trim().isEmpty
                ? null
                : deliveryNoteController.text.trim(),
            contactChannel: contactChannel,
            priceNote: priceNoteController.text.trim().isEmpty
                ? null
                : priceNoteController.text.trim(),
            handoffDetails: {
              ...handoffDetails,
              'contact_channel': contactChannel,
            }));
    if (!mounted) return;
    setState(() => saving = false);
    if (result is AssalData<AssalRequestSummary>) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.pop(context);
      messenger?.showSnackBar(
        const SnackBar(content: Text('تم حفظ الطلب ويمكنك متابعته من ملفك.')),
      );
    } else if (result is AssalError<AssalRequestSummary>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.messageAr)),
      );
    }
  }
}
