import 'dart:async';
import 'package:flutter/material.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_design/assal_tokens.dart';
import '../../core/assal_widgets.dart';
import '../../core/yemen_location_reference.dart';
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
  Future<AssalLoadState<List<AssalStoreSummary>>>? storesFuture;
  late Future<AssalLoadState<List<AssalBannerSummary>>> bannersFuture;
  Future<AssalLoadState<List<AssalProductSummary>>>? popularFuture;
  Future<AssalLoadState<List<AssalProductSummary>>>? newProductsFuture;
  Future<AssalLoadState<List<AssalProductSummary>>>? verifiedProductsFuture;
  Future<AssalLoadState<List<AssalProductSummary>>>? personalizedFuture;
  late Future<AssalLoadState<List<AssalNotificationSummary>>> notificationsFuture;
  late Future<bool> initialContentFuture;
  final searchController = TextEditingController();
  late final ScrollController scrollController;
  bool deferredDataStarted = false;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController()..addListener(_maybeLoadDeferredData);
    _load();
  }

  @override
  void dispose() {
    scrollController
      ..removeListener(_maybeLoadDeferredData)
      ..dispose();
    searchController.dispose();
    super.dispose();
  }

  void _load() {
    deferredDataStarted = false;
    storesFuture = null;
    popularFuture = null;
    newProductsFuture = null;
    verifiedProductsFuture = null;
    personalizedFuture = null;
    featuredFuture = widget.repository.listProducts(query: const AssalProductQuery(featuredOnly: true));
    taxonomyFuture = widget.repository.listTaxonomy();
    bannersFuture = widget.repository.listBanners();
    notificationsFuture = _loadNotifications();
    initialContentFuture = Future.wait<Object?>(<Future<Object?>>[
      featuredFuture,
      taxonomyFuture,
      bannersFuture,
    ]).then<bool>((_) => true);
  }

  void _refresh() => setState(_load);

  void _openStores() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoresScreen(repository: widget.repository),
      ),
    );
  }

  void _maybeLoadDeferredData() {
    if (deferredDataStarted || !scrollController.hasClients) return;
    if (scrollController.position.pixels < 180) return;
    _startDeferredData();
  }

  void _startDeferredData() {
    if (deferredDataStarted) return;
    setState(() {
      deferredDataStarted = true;
      storesFuture = widget.repository.listStores();
      popularFuture = widget.repository.listProducts(
          query: const AssalProductQuery(sort: AssalSort.popular));
      newProductsFuture = widget.repository.listProducts(
          query: const AssalProductQuery(sort: AssalSort.newest));
      verifiedProductsFuture = widget.repository.listProducts(
          query: const AssalProductQuery(
              verifiedStoresOnly: true, sort: AssalSort.rating));
      personalizedFuture = _buildPersonalizedFeed();
    });
  }

  Future<AssalLoadState<List<AssalProductSummary>>> _buildPersonalizedFeed() async {
    final session = await widget.repository.getSession();
    final user = session.user;
    if (!session.isAuthenticated || user == null || user.id.isEmpty) {
      return const AssalEmpty('سجّل الدخول لتصلك اقتراحات مناسبة لك');
    }

    final favoriteState = await widget.repository.listFavoriteProducts(user.id);
    final followedState = await widget.repository.listFollowedStores(user.id);
    final catalogState = await widget.repository.listProducts(
      query: const AssalProductQuery(sort: AssalSort.featured),
    );
    if (catalogState is! AssalData<List<AssalProductSummary>>) {
      return catalogState;
    }

    final favoriteProducts = favoriteState is AssalData<List<AssalProductSummary>>
        ? favoriteState.value
        : const <AssalProductSummary>[];
    final followedStores = followedState is AssalData<List<AssalStoreSummary>>
        ? followedState.value
        : const <AssalStoreSummary>[];
    final favoriteIds = favoriteProducts.map((item) => item.id).toSet();
    final followedStoreIds = followedStores.map((item) => item.id).toSet();
    final viewedIds = _preferenceStrings(user.preferences['viewed_product_ids']);
    final preferredTypes = _preferenceStrings(
      user.preferences['preferred_product_types'],
    );
    final location = (user.location ?? '').trim().toLowerCase();

    int score(AssalProductSummary product) {
      var value = 0;
      if (favoriteIds.contains(product.id)) value += 100;
      if (followedStoreIds.contains(product.storeId)) value += 70;
      if (viewedIds.contains(product.id.toLowerCase())) value += 35;
      if (preferredTypes.contains(product.productType.name.toLowerCase())) value += 30;
      final productLocations = <String?>[
        product.regionNameAr,
        product.provinceNameAr,
        product.originCountry,
      ];
      if (location.isNotEmpty && productLocations.any(
        (item) => item != null && item.toLowerCase().contains(location),
      )) {
        value += 35;
      }
      if (product.isFeatured) value += 10;
      return value + (product.ratingAverage * 2).round();
    }

    final ranked = [...catalogState.value]
      ..sort((left, right) => score(right).compareTo(score(left)));
    final selected = <AssalProductSummary>[];
    for (final product in [...favoriteProducts, ...ranked]) {
      if (selected.every((item) => item.id != product.id)) {
        selected.add(product);
      }
      if (selected.length == 8) break;
    }
    return selected.isEmpty
        ? const AssalEmpty('لا توجد اقتراحات كافية بعد')
        : AssalData(selected);
  }

  Set<String> _preferenceStrings(Object? raw) {
    if (raw is String) {
      return raw
          .split(',')
          .map((item) => item.trim().toLowerCase())
          .where((item) => item.isNotEmpty)
          .toSet();
    }
    if (raw is Iterable) {
      return raw
          .map((item) => item.toString().trim().toLowerCase())
          .where((item) => item.isNotEmpty)
          .toSet();
    }
    return <String>{};
  }

  Future<AssalLoadState<List<AssalNotificationSummary>>> _loadNotifications() async {
    final session = await widget.repository.getSession();
    final userId = session.user?.id;
    if (userId == null || userId.isEmpty) return const AssalEmpty('سجّل الدخول لرؤية إشعاراتك');
    return widget.repository.listNotifications(userId);
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<bool>(
          future: initialContentFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) return const CustomScrollView(slivers: [SliverFillRemaining(hasScrollBody: false, child: AssalMessageCard(icon: Icons.wifi_off_outlined, message: 'تعذر تجهيز الصفحة الآن. تحقق من الاتصال ثم أعد المحاولة.'))]);
            if (snapshot.data != true) return _loadingBody();
            return CustomScrollView(controller: scrollController, slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedHeaderDelegate(
              child: _Header(
                repository: widget.repository,
                notificationsFuture: notificationsFuture,
                onOpenNotifications: widget.onOpenNotifications,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AssalSpacing.lg,
              AssalSpacing.lg,
              AssalSpacing.lg,
              AssalSpacing.md,
            ),
            sliver: SliverToBoxAdapter(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(AssalSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: AssalColors.honeyLight.withValues(alpha: .45),
                              borderRadius: BorderRadius.circular(AssalRadius.large),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(AssalSpacing.md),
                              child: Icon(Icons.hive_outlined,
                                  color: AssalColors.primaryDark, size: 30),
                            ),
                          ),
                          const SizedBox(width: AssalSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'اكتشف العسل من مصدره',
                                  style: AssalTypography.heading1
                                      .copyWith(color: AssalColors.deepBrown),
                                ),
                                const SizedBox(height: AssalSpacing.xs),
                                Text(
                                  'تصفح المتاجر والمنتجات اليمنية الموثوقة، ثم تواصل مع التاجر بالطريقة المناسبة لك.',
                                  style: AssalTypography.bodyLarge
                                      .copyWith(color: AssalColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AssalSpacing.lg),
                      TextField(
                        controller: searchController,
                        readOnly: true,
                        onTap: widget.onOpenSearch,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'ابحث عن سدر، سمر، شمع أو هدية',
                          suffixIcon: Icon(Icons.tune_rounded),
                        ),
                      ),
                      const SizedBox(height: AssalSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _openStores,
                          icon: const Icon(Icons.storefront_outlined),
                          label: const Text('استكشف المتاجر'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.lg), sliver: SliverToBoxAdapter(child: FutureBuilder<AssalLoadState<List<AssalBannerSummary>>>(future: bannersFuture, builder: (context, snapshot) {
            if (snapshot.hasError) return AssalMessageCard(icon: Icons.wifi_off_outlined, message: 'تعذر تحميل هذه البيانات الآن. تحقق من الاتصال ثم أعد المحاولة.', onRetry: _refresh); if (!snapshot.hasData) return const AssalGlassLoading(height: 210);
            return AssalStateView<List<AssalBannerSummary>>(state: snapshot.data!, onRetry: _refresh, builder: (banners) => _BannersCarousel(banners: banners, onExplore: widget.onOpenSearch));
          }))),
          SliverPadding(padding: const EdgeInsets.fromLTRB(AssalSpacing.lg, AssalSpacing.xl, AssalSpacing.lg, AssalSpacing.sm), sliver: SliverToBoxAdapter(child: SectionHeader(title: 'استكشف حسب التصنيف', actionLabel: 'كل التصنيفات', onAction: widget.onOpenSearch))),
          SliverToBoxAdapter(child: SizedBox(height: 92, child: FutureBuilder<AssalLoadState<List<AssalTaxonomy>>>(future: taxonomyFuture, builder: (context, snapshot) {
            if (snapshot.hasError) return AssalMessageCard(icon: Icons.wifi_off_outlined, message: 'تعذر تحميل هذه البيانات الآن. تحقق من الاتصال ثم أعد المحاولة.', onRetry: _refresh); if (!snapshot.hasData) return const AssalGlassLoading(height: 92);
            return AssalStateView<List<AssalTaxonomy>>(state: snapshot.data!, builder: (items) => ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.lg), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(width: AssalSpacing.sm), itemBuilder: (_, index) => _CategoryTile(item: items[index], onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SearchScreen(repository: widget.repository, initialSubcategoryId: items[index].id))))));
          }))),
          SliverPadding(padding: const EdgeInsets.fromLTRB(AssalSpacing.lg, AssalSpacing.xl, AssalSpacing.lg, AssalSpacing.sm), sliver: SliverToBoxAdapter(child: SectionHeader(title: 'منتجات مختارة', actionLabel: 'عرض الكل', onAction: widget.onOpenSearch))),
          SliverPadding(padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.lg), sliver: SliverToBoxAdapter(child: FutureBuilder<AssalLoadState<List<AssalProductSummary>>>(future: featuredFuture, builder: (context, snapshot) {
            if (snapshot.hasError) return AssalMessageCard(icon: Icons.wifi_off_outlined, message: 'تعذر تحميل هذه البيانات الآن. تحقق من الاتصال ثم أعد المحاولة.', onRetry: _refresh); if (!snapshot.hasData) return const AssalGlassLoading(height: 300);
            return AssalStateView<List<AssalProductSummary>>(state: snapshot.data!, onRetry: _refresh, builder: (products) => GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220, crossAxisSpacing: AssalSpacing.md, mainAxisSpacing: AssalSpacing.md, childAspectRatio: .68), itemCount: products.length > 6 ? 6 : products.length, itemBuilder: (_, index) => ProductCard(product: products[index], onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(repository: widget.repository, productId: products[index].id))))));
          }))),
          if (deferredDataStarted) ...[
            SliverPadding(padding: const EdgeInsets.fromLTRB(AssalSpacing.lg, AssalSpacing.xl, AssalSpacing.lg, AssalSpacing.sm), sliver: SliverToBoxAdapter(child: _ProductRail(repository: widget.repository, title: 'الأكثر مشاهدة', future: popularFuture!, onRetry: _refresh))),
            SliverPadding(padding: const EdgeInsets.fromLTRB(AssalSpacing.lg, AssalSpacing.xl, AssalSpacing.lg, AssalSpacing.sm), sliver: SliverToBoxAdapter(child: _ProductRail(repository: widget.repository, title: 'وصل حديثًا', future: newProductsFuture!, onRetry: _refresh))),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AssalSpacing.lg,
                AssalSpacing.xl,
                AssalSpacing.lg,
                AssalSpacing.sm,
              ),
              sliver: SliverToBoxAdapter(
                child: _ProductRail(
                  repository: widget.repository,
                  title: 'المنتجات اليمنية الموثوقة',
                  future: verifiedProductsFuture!,
                  verifiedOnly: true,
                  onRetry: _refresh,
                ),
              ),
            ),
            if (personalizedFuture != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AssalSpacing.lg,
                  AssalSpacing.xl,
                  AssalSpacing.lg,
                  AssalSpacing.sm,
                ),
                sliver: SliverToBoxAdapter(
                  child: _ProductRail(
                    repository: widget.repository,
                    title: 'مقترحات مخصصة لك',
                    future: personalizedFuture!,
                    onRetry: _refresh,
                  ),
                ),
              ),
            SliverPadding(padding: const EdgeInsets.fromLTRB(AssalSpacing.lg, AssalSpacing.xl, AssalSpacing.lg, AssalSpacing.sm), sliver: SliverToBoxAdapter(child: SectionHeader(title: 'متاجر موثوقة', actionLabel: 'عرض المتاجر', onAction: _openStores))) ,
            SliverPadding(padding: const EdgeInsets.fromLTRB(AssalSpacing.lg, 0, AssalSpacing.lg, AssalSpacing.xl), sliver: SliverToBoxAdapter(child: FutureBuilder<AssalLoadState<List<AssalStoreSummary>>>(future: storesFuture!, builder: (context, snapshot) {
              if (snapshot.hasError) return AssalMessageCard(icon: Icons.wifi_off_outlined, message: 'تعذر تحميل هذه البيانات الآن. تحقق من الاتصال ثم أعد المحاولة.', onRetry: _refresh); if (!snapshot.hasData) return const AssalGlassLoading(height: 100);
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
          ] else
            const SliverToBoxAdapter(child: SizedBox.shrink()),
          const SliverToBoxAdapter(child: SizedBox(height: AssalSpacing.xl)),
            ]);
          },
        ),
      );

  Widget _loadingBody() => CustomScrollView(slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedHeaderDelegate(
            child: _Header(
              repository: widget.repository,
              notificationsFuture: notificationsFuture,
              onOpenNotifications: widget.onOpenNotifications,
            ),
          ),
        ),
        const SliverFillRemaining(hasScrollBody: false, child: Padding(padding: EdgeInsets.all(AssalSpacing.lg), child: AssalGlassLoading(height: 520, label: 'جارٍ تحميل الصفحة والمنتجات...'))),
      ]);
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedHeaderDelegate({required this.child});
  final Widget child;

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        elevation: overlapsContent ? 2 : 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AssalSpacing.lg,
            AssalSpacing.sm,
            AssalSpacing.lg,
            AssalSpacing.sm,
          ),
          child: child,
        ),
      );

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) => true;
}

class _Header extends StatelessWidget {
  const _Header({required this.repository, required this.notificationsFuture, required this.onOpenNotifications});
  final AssalRepository repository;
  final Future<AssalLoadState<List<AssalNotificationSummary>>> notificationsFuture;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const AssalBrandMark(showName: false), Row(children: [IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())), icon: const Icon(Icons.settings_outlined), tooltip: 'الإعدادات'), FutureBuilder<AssalLoadState<List<AssalNotificationSummary>>>(future: notificationsFuture, builder: (context, snapshot) { final state = snapshot.data; final unread = state is AssalData<List<AssalNotificationSummary>> ? state.value.where((item) => item.readAt == null).length : 0; return Stack(clipBehavior: Clip.none, children: [IconButton(onPressed: onOpenNotifications, icon: const Icon(Icons.notifications_none_rounded), tooltip: 'الإشعارات'), if (unread > 0) Positioned(top: 5, right: 5, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: AssalColors.error, borderRadius: BorderRadius.circular(AssalRadius.pill)), child: Text('$unread', style: AssalTypography.caption.copyWith(color: AssalColors.cream))))]); })])]);
}

class _BannersCarousel extends StatefulWidget {
  const _BannersCarousel({required this.banners, required this.onExplore});
  final List<AssalBannerSummary> banners;
  final VoidCallback onExplore;

  @override
  State<_BannersCarousel> createState() => _BannersCarouselState();
}

class _BannersCarouselState extends State<_BannersCarousel> {
  late final PageController controller;
  Timer? timer;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    controller = PageController();
    if (widget.banners.length > 1) {
      timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || !controller.hasClients) return;
        final next = (currentIndex + 1) % widget.banners.length;
        controller.animateToPage(next, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return _HeroBanner(onExplore: widget.onExplore);
    return Column(children: [
      SizedBox(
        height: 210,
        child: PageView.builder(
          controller: controller,
          itemCount: widget.banners.length,
          onPageChanged: (index) => setState(() => currentIndex = index),
          itemBuilder: (_, index) => _BannerCard(item: widget.banners[index], onExplore: widget.onExplore),
        ),
      ),
      const SizedBox(height: AssalSpacing.sm),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(widget.banners.length, (index) => AnimatedContainer(duration: const Duration(milliseconds: 220), width: index == currentIndex ? 22 : 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(color: index == currentIndex ? AssalColors.primaryDark : AssalColors.border, borderRadius: BorderRadius.circular(AssalRadius.pill))))),
    ]);
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.item, required this.onExplore});
  final AssalBannerSummary item;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AssalSpacing.xl),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [AssalColors.deepBrown, AssalColors.secondary]), borderRadius: BorderRadius.circular(AssalRadius.extraLarge)),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(item.titleAr, maxLines: 2, overflow: TextOverflow.ellipsis, style: AssalTypography.heading2.copyWith(color: AssalColors.cream)),
            const SizedBox(height: AssalSpacing.sm),
            Text(item.descriptionAr, maxLines: 2, overflow: TextOverflow.ellipsis, style: AssalTypography.body.copyWith(color: AssalColors.cream)),
            const SizedBox(height: AssalSpacing.md),
            FilledButton.tonal(onPressed: onExplore, child: Text(item.ctaLabelAr)),
          ])),
          const SizedBox(width: AssalSpacing.md),
          const Icon(Icons.local_florist_rounded, size: 68, color: AssalColors.primaryLight),
        ]),
      );
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

class _ProductRail extends StatelessWidget {
  const _ProductRail({
    required this.repository,
    required this.title,
    required this.future,
    this.verifiedOnly = false,
    this.onRetry,
  });
  final AssalRepository repository;
  final String title;
  final Future<AssalLoadState<List<AssalProductSummary>>> future;
  final bool verifiedOnly;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(
          title: title,
          actionLabel: 'عرض الكل',
          onAction: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SearchScreen(
                repository: repository,
                verifiedOnly: verifiedOnly,
              ),
            ),
          ),
        ),
        const SizedBox(height: AssalSpacing.sm),
        SizedBox(
          height: 340,
          child: FutureBuilder<AssalLoadState<List<AssalProductSummary>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.hasError) return AssalMessageCard(icon: Icons.wifi_off_outlined, message: 'تعذر تحميل هذه البيانات الآن. تحقق من الاتصال ثم أعد المحاولة.', onRetry: onRetry); if (!snapshot.hasData) return const AssalGlassLoading();
              return AssalStateView<List<AssalProductSummary>>(
                state: snapshot.data!,
                builder: (products) => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.xs),
                  itemCount: products.length > 8 ? 8 : products.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AssalSpacing.md),
                  itemBuilder: (_, index) => SizedBox(
                    width: 168,
                    child: ProductCard(
                      product: products[index],
                      showVerifiedBadge: verifiedOnly,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                            repository: repository,
                            productId: products[index].id,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ]);
}

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key, required this.repository});
  final AssalRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التصنيفات')),
      body: FutureBuilder<AssalLoadState<List<AssalCategorySummary>>>(
        future: repository.listCategories(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const AssalMessageCard(
              icon: Icons.wifi_off_outlined,
              message: 'تعذر تحميل الأقسام الآن.',
            );
          }
          if (!snapshot.hasData) return const AssalGlassLoading();
          return AssalStateView<List<AssalCategorySummary>>(
            state: snapshot.data!,
            builder: (categories) => ListView.separated(
              padding: const EdgeInsets.all(AssalSpacing.lg),
              itemCount: categories.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AssalSpacing.sm),
              itemBuilder: (_, index) {
                final category = categories[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AssalColors.honeyLight,
                      child: Icon(_categoryIcon(category.productType),
                          color: AssalColors.primaryDark),
                    ),
                    title: Text(category.nameAr),
                    subtitle: Text(
                      '${category.description ?? 'قسم مرجعي من Honey Master Database'}\n${category.productCount} منتج متاح',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SearchScreen(
                          repository: repository,
                          initialCategoryId: category.id,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _categoryIcon(ProductType type) => switch (type) {
        ProductType.honey => Icons.water_drop_outlined,
        ProductType.wax => Icons.hexagon_outlined,
        ProductType.mix => Icons.local_florist_outlined,
        ProductType.raw => Icons.hive_outlined,
        ProductType.gift => Icons.card_giftcard_outlined,
      };
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.repository,
    this.initialQuery,
    this.initialCategoryId,
    this.initialSubcategoryId,
    this.verifiedOnly = false,
  });
  final AssalRepository repository;
  final String? initialQuery;
  final String? initialCategoryId;
  final String? initialSubcategoryId;
  final bool verifiedOnly;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController controller = TextEditingController(text: widget.initialQuery);
  String? categoryId;
  String? subcategoryId;
  String? regionId;
  String? provinceId;
  int? gradeLevel;
  ProductType? productType;
  bool verifiedOnly = false;
  String? originCountry;
  String? processingMethod;
  String? packaging;
  String? availability;
  double? minRating;
  double? minPrice;
  double? maxPrice;
  AssalSort sort = AssalSort.featured;
  late Future<AssalLoadState<List<AssalProductSummary>>> productsFuture;
  final Set<String> originOptions = <String>{};
  final Set<String> processingOptions = <String>{};
  final Set<String> packagingOptions = <String>{};
  final Set<String> availabilityOptions = <String>{};
  double? dataMinPrice;
  double? dataMaxPrice;
  double dataMaxRating = 5;
  YemenLocationReference? locationReference;
  late Future<AssalLoadState<List<AssalStoreSummary>>> storesFuture;
  late Future<AssalLoadState<List<String>>> popularSearchesFuture;

  @override
  void initState() {
    super.initState();
    categoryId = widget.initialCategoryId;
    subcategoryId = widget.initialSubcategoryId;
    verifiedOnly = widget.verifiedOnly;
    _search();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _search() {
    final query = AssalProductQuery(categoryId: categoryId, search: controller.text, subcategoryId: subcategoryId, regionId: regionId, provinceId: provinceId, gradeLevel: gradeLevel, productType: productType, verifiedStoresOnly: verifiedOnly, originCountry: originCountry, processingMethod: processingMethod, packaging: packaging, availability: availability, minRating: minRating, minPrice: minPrice, maxPrice: maxPrice, sort: sort);
    productsFuture = widget.repository.listProducts(query: query);
    storesFuture = widget.repository.listStores();
    popularSearchesFuture = widget.repository.listPopularSearches();
  }

  void _captureFilterOptions(List<AssalProductSummary> products) {
    for (final product in products) {
      if (product.originCountry != null) originOptions.add(product.originCountry!);
      if (product.processingMethodAr != null) processingOptions.add(product.processingMethodAr!);
      if (product.packagingLabelAr != null) packagingOptions.add(product.packagingLabelAr!);
      if (product.availability.isNotEmpty) availabilityOptions.add(product.availability);
      if (product.price != null) {
        dataMinPrice = dataMinPrice == null || product.price! < dataMinPrice! ? product.price : dataMinPrice;
        dataMaxPrice = dataMaxPrice == null || product.price! > dataMaxPrice! ? product.price : dataMaxPrice;
      }
      if (product.ratingAverage > dataMaxRating) dataMaxRating = product.ratingAverage;
    }
  }

  List<DropdownMenuItem<String>> _stringOptions(Set<String> options) {
    final values = options.toList()..sort();
    return [
      const DropdownMenuItem<String>(value: '', child: Text('الكل')),
      ...values.map(
        (value) => DropdownMenuItem<String>(value: value, child: Text(value)),
      ),
    ];
  }

  void _applySearch() => setState(_search);

  int get _activeFilterCount {
    var count = 0;
    if (categoryId != null) count++;
    if (subcategoryId != null) count++;
    if (regionId != null) count++;
    if (provinceId != null) count++;
    if (gradeLevel != null) count++;
    if (productType != null) count++;
    if (verifiedOnly) count++;
    if (originCountry != null) count++;
    if (processingMethod != null) count++;
    if (packaging != null) count++;
    if (availability != null) count++;
    if (minRating != null || minPrice != null || maxPrice != null) count++;
    if (sort != AssalSort.featured) count++;
    return count;
  }

  List<Widget> _activeFilterChips() => [
        if (categoryId != null)
          InputChip(label: Text('القسم: $categoryId'), onDeleted: () => setState(() { categoryId = null; _search(); })),
        if (subcategoryId != null)
          InputChip(label: Text('التصنيف: $subcategoryId'), onDeleted: () => setState(() { subcategoryId = null; _search(); })),
        if (regionId != null)
          InputChip(label: Text('المحافظة: $regionId'), onDeleted: () => setState(() { regionId = null; provinceId = null; _search(); })),
        if (provinceId != null)
          InputChip(label: Text('المديرية: $provinceId'), onDeleted: () => setState(() { provinceId = null; _search(); })),
        if (productType != null)
          InputChip(label: Text(_productTypeLabel(productType!)), onDeleted: () => setState(() { productType = null; _search(); })),
        if (gradeLevel != null)
          InputChip(label: Text('الدرجة $gradeLevel'), onDeleted: () => setState(() { gradeLevel = null; _search(); })),
        if (verifiedOnly)
          InputChip(label: const Text('متاجر موثقة'), onDeleted: () => setState(() { verifiedOnly = false; _search(); })),
        if (originCountry != null)
          InputChip(label: Text('الأصل: $originCountry'), onDeleted: () => setState(() { originCountry = null; _search(); })),
        if (processingMethod != null)
          InputChip(label: Text('المعالجة: $processingMethod'), onDeleted: () => setState(() { processingMethod = null; _search(); })),
        if (packaging != null)
          InputChip(label: Text('التعبئة: $packaging'), onDeleted: () => setState(() { packaging = null; _search(); })),
        if (availability != null)
          InputChip(label: Text('التوفر: $availability'), onDeleted: () => setState(() { availability = null; _search(); })),
      ];

  void _clearFilters() {
    controller.clear();
    categoryId = null;
    subcategoryId = null;
    regionId = null;
    provinceId = null;
    gradeLevel = null;
    productType = null;
    verifiedOnly = false;
    originCountry = null;
    processingMethod = null;
    packaging = null;
    availability = null;
    minRating = null;
    minPrice = null;
    maxPrice = null;
    sort = AssalSort.featured;
    _applySearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AssalAppBar(title: 'البحث'),
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
        FutureBuilder<AssalLoadState<List<String>>>(
          future: popularSearchesFuture,
          builder: (context, snapshot) {
            if (snapshot.data is! AssalData<List<String>>) return const SizedBox.shrink();
            final terms = (snapshot.data! as AssalData<List<String>>).value;
            return SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.lg),
                scrollDirection: Axis.horizontal,
                itemCount: terms.length,
                separatorBuilder: (_, __) => const SizedBox(width: AssalSpacing.sm),
                itemBuilder: (_, index) => ActionChip(label: Text(terms[index]), onPressed: () { controller.text = terms[index]; _applySearch(); }),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.lg, vertical: AssalSpacing.sm),
          child: Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: _showFilters, icon: const Icon(Icons.tune_rounded), label: Text(_activeFilterCount == 0 ? 'الفلاتر' : 'الفلاتر ($_activeFilterCount)'))),
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
        if (_activeFilterCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(AssalSpacing.lg, 0, AssalSpacing.lg, AssalSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Wrap(spacing: AssalSpacing.xs, runSpacing: AssalSpacing.xs, children: _activeFilterChips())),
                TextButton(onPressed: _clearFilters, child: const Text('مسح الكل')),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _applySearch(),
            child: ListView(padding: const EdgeInsets.fromLTRB(AssalSpacing.lg, 0, AssalSpacing.lg, AssalSpacing.xl), children: [
              const SectionHeader(title: 'المنتجات'),
              FutureBuilder<AssalLoadState<List<AssalProductSummary>>>(
                future: productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return AssalMessageCard(icon: Icons.wifi_off_outlined, message: 'تعذر تحميل المنتجات الآن. تحقق من الاتصال ثم أعد المحاولة.', onRetry: _applySearch); if (!snapshot.hasData) return const AssalGlassLoading(height: 300);
                  final productState = snapshot.data!;
                  if (productState is AssalData<List<AssalProductSummary>>) {
                    _captureFilterOptions(productState.value);
                  }
                  return AssalStateView<List<AssalProductSummary>>(
                    state: snapshot.data!,
                    onRetry: _applySearch,
                    builder: (products) => GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220, crossAxisSpacing: AssalSpacing.md, mainAxisSpacing: AssalSpacing.md, childAspectRatio: .68),
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
                  if (snapshot.hasError) return AssalMessageCard(icon: Icons.wifi_off_outlined, message: 'تعذر تحميل المتاجر الآن. تحقق من الاتصال ثم أعد المحاولة.', onRetry: _applySearch); if (!snapshot.hasData) return const AssalGlassLoading(height: 120);
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
    final reference = locationReference ??= await _loadLocationReference();
    if (reference == null || !mounted) return;
    var draftRegion = regionId ?? '';
    var draftProvince = provinceId ?? '';
    var draftGrade = gradeLevel;
    var draftType = productType;
    var draftVerified = verifiedOnly;
    var draftOrigin = originCountry ?? '';
    var draftProcessing = processingMethod ?? '';
    var draftPackaging = packaging ?? '';
    var draftAvailability = availability ?? '';
    final priceMin = dataMinPrice ?? 0;
    final priceMax = (dataMaxPrice ?? 1) > priceMin ? dataMaxPrice! : priceMin + 1;
    final currentMinPrice = (minPrice ?? priceMin).clamp(priceMin, priceMax).toDouble();
    final currentMaxPrice = (maxPrice ?? priceMax).clamp(priceMin, priceMax).toDouble();
    var draftPriceRange = RangeValues(
      currentMinPrice <= currentMaxPrice ? currentMinPrice : priceMin,
      currentMaxPrice >= currentMinPrice ? currentMaxPrice : priceMax,
    );
    var draftMinRatingValue = (minRating ?? 0).clamp(0, dataMaxRating).toDouble();
    final typeItems = <DropdownMenuItem<ProductType?>>[
      const DropdownMenuItem<ProductType?>(value: null, child: Text('كل الأنواع')),
      ...ProductType.values.map<DropdownMenuItem<ProductType?>>((type) => DropdownMenuItem<ProductType?>(value: type, child: Text(_productTypeLabel(type)))),
    ];
    final gradeItems = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(value: null, child: Text('كل الدرجات')),
      ...[1, 2, 3, 4].map<DropdownMenuItem<int?>>((grade) => DropdownMenuItem<int?>(value: grade, child: Text('درجة $grade'))),
    ];
    final originItems = _stringOptions(originOptions);
    final processingItems = _stringOptions(processingOptions);
    final packagingItems = _stringOptions(packagingOptions);
    final availabilityItems = _stringOptions(availabilityOptions);
    final regionItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(value: '', child: Text('كل المحافظات')),
      ...reference.governorates.map(
        (region) => DropdownMenuItem<String>(
          value: region.code ?? region.id,
          child: Text(region.nameAr),
        ),
      ),
    ];
    final apply = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(left: AssalSpacing.xl, right: AssalSpacing.xl, top: AssalSpacing.xl, bottom: MediaQuery.viewInsetsOf(context).bottom + AssalSpacing.xl),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('تصفية النتائج', style: AssalTypography.heading2.copyWith(color: AssalColors.deepBrown)),
          const SizedBox(height: AssalSpacing.md),
          DropdownButtonFormField<String>(initialValue: draftRegion, decoration: const InputDecoration(labelText: 'المحافظة'), items: regionItems, onChanged: (value) => setModalState(() { draftRegion = value ?? ''; draftProvince = ''; })),
          DropdownButtonFormField<String>(initialValue: draftProvince, decoration: const InputDecoration(labelText: 'المديرية'), items: [const DropdownMenuItem<String>(value: '', child: Text('كل المديريات')), ...reference.districtsFor(draftRegion).map((district) => DropdownMenuItem<String>(value: district.code ?? district.id, child: Text(district.nameAr)))], onChanged: draftRegion.isEmpty ? null : (value) => setModalState(() => draftProvince = value ?? '')),
          DropdownButtonFormField<ProductType?>(initialValue: draftType, decoration: const InputDecoration(labelText: 'نوع المنتج'), items: typeItems, onChanged: (value) => setModalState(() => draftType = value)),
          DropdownButtonFormField<int?>(initialValue: draftGrade, decoration: const InputDecoration(labelText: 'درجة الجودة'), items: gradeItems, onChanged: (value) => setModalState(() => draftGrade = value)),
          SwitchListTile(value: draftVerified, onChanged: (value) => setModalState(() => draftVerified = value), title: const Text('المتاجر الموثقة فقط')),
          DropdownButtonFormField<String>(initialValue: draftOrigin, decoration: const InputDecoration(labelText: 'بلد/منطقة الأصل'), items: originItems, onChanged: (value) => setModalState(() => draftOrigin = value ?? '')),
          DropdownButtonFormField<String>(initialValue: draftProcessing, decoration: const InputDecoration(labelText: 'طريقة المعالجة'), items: processingItems, onChanged: (value) => setModalState(() => draftProcessing = value ?? '')),
          DropdownButtonFormField<String>(initialValue: draftPackaging, decoration: const InputDecoration(labelText: 'التعبئة'), items: packagingItems, onChanged: (value) => setModalState(() => draftPackaging = value ?? '')),
          DropdownButtonFormField<String>(initialValue: draftAvailability, decoration: const InputDecoration(labelText: 'التوفر'), items: availabilityItems, onChanged: (value) => setModalState(() => draftAvailability = value ?? '')),
          Text('نطاق السعر: ${draftPriceRange.start.toStringAsFixed(0)} – ${draftPriceRange.end.toStringAsFixed(0)} ريال', style: AssalTypography.bodyLarge.copyWith(color: AssalColors.textSecondary)),
          RangeSlider(
            min: priceMin,
            max: priceMax,
            divisions: 100,
            values: draftPriceRange,
            labels: RangeLabels(
              draftPriceRange.start.toStringAsFixed(0),
              draftPriceRange.end.toStringAsFixed(0),
            ),
            onChanged: (value) => setModalState(() => draftPriceRange = value),
          ),
          Text('أدنى تقييم: ${draftMinRatingValue.toStringAsFixed(1)} من ${dataMaxRating.toStringAsFixed(1)}', style: AssalTypography.bodyLarge.copyWith(color: AssalColors.textSecondary)),
          Slider(
            min: 0,
            max: dataMaxRating,
            divisions: 10,
            value: draftMinRatingValue,
            label: draftMinRatingValue.toStringAsFixed(1),
            onChanged: (value) => setModalState(() => draftMinRatingValue = value),
          ),
          const SizedBox(height: AssalSpacing.md),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () { regionId = draftRegion.trim().isEmpty ? null : draftRegion.trim(); provinceId = draftProvince.trim().isEmpty ? null : draftProvince.trim(); gradeLevel = draftGrade; productType = draftType; verifiedOnly = draftVerified; originCountry = draftOrigin.trim().isEmpty ? null : draftOrigin.trim(); processingMethod = draftProcessing.trim().isEmpty ? null : draftProcessing.trim(); packaging = draftPackaging.trim().isEmpty ? null : draftPackaging.trim(); availability = draftAvailability.trim().isEmpty ? null : draftAvailability.trim(); minRating = draftMinRatingValue <= 0 ? null : draftMinRatingValue; minPrice = draftPriceRange.start <= priceMin ? null : draftPriceRange.start; maxPrice = draftPriceRange.end >= priceMax ? null : draftPriceRange.end; Navigator.pop(sheetContext, true); }, child: const Text('تطبيق الفلاتر'))),
        ])),
      )),
    );
    if (apply == true) _applySearch();
  }

  Future<YemenLocationReference?> _loadLocationReference() async {
    try {
      return await YemenLocationReference.load();
    } on AssalReferenceDataFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.messageAr)),
        );
      }
      return null;
    }
  }
}

String _productTypeLabel(ProductType type) => switch (type) { ProductType.honey => 'عسل', ProductType.wax => 'شمع', ProductType.mix => 'خلطة', ProductType.raw => 'منتج خام', ProductType.gift => 'هدية' };

class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key, required this.repository});
  final AssalRepository repository;

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  late final Future<AssalLoadState<List<AssalStoreSummary>>> storesFuture;
  late final Future<YemenLocationReference?> locationsFuture;
  String searchQuery = '';
  String? regionId;
  bool verifiedOnly = false;

  @override
  void initState() {
    super.initState();
    storesFuture = widget.repository.listStores();
    locationsFuture = _loadLocations();
  }

  Future<YemenLocationReference?> _loadLocations() async {
    try {
      return await YemenLocationReference.load();
    } on Object {
      return null;
    }
  }

  List<AssalStoreSummary> _filtered(List<AssalStoreSummary> stores) {
    final query = searchQuery.trim().toLowerCase();
    return stores.where((store) {
      final matchesQuery = query.isEmpty ||
          store.nameAr.toLowerCase().contains(query) ||
          (store.regionNameAr ?? '').toLowerCase().contains(query);
      final matchesRegion = regionId == null || store.regionId == regionId;
      final matchesVerified = !verifiedOnly || store.isVerified;
      return matchesQuery && matchesRegion && matchesVerified;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AssalAppBar(title: 'المتاجر'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AssalSpacing.lg,
              AssalSpacing.md,
              AssalSpacing.lg,
              AssalSpacing.sm,
            ),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'ابحث باسم المتجر أو المنطقة',
              ),
            ),
          ),
          FutureBuilder<YemenLocationReference?>(
            future: locationsFuture,
            builder: (context, snapshot) {
              final locations = snapshot.data;
              if (locations == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: regionId,
                        decoration: const InputDecoration(labelText: 'المحافظة'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('كل المحافظات'),
                          ),
                          ...locations.governorates.map(
                            (region) => DropdownMenuItem<String?>(
                              value: region.code ?? region.id,
                              child: Text(region.nameAr),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() => regionId = value),
                      ),
                    ),
                    const SizedBox(width: AssalSpacing.sm),
                    FilterChip(
                      label: const Text('موثقة'),
                      selected: verifiedOnly,
                      onSelected: (value) =>
                          setState(() => verifiedOnly = value),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: FutureBuilder<AssalLoadState<List<AssalStoreSummary>>>(
              future: storesFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const AssalMessageCard(
                    icon: Icons.wifi_off_outlined,
                    message: 'تعذر تحميل المتاجر الآن.',
                  );
                }
                if (!snapshot.hasData) return const AssalGlassLoading();
                final state = snapshot.data!;
                if (state is AssalData<List<AssalStoreSummary>>) {
                  final stores = _filtered(state.value);
                  if (stores.isEmpty) {
                    return const AssalMessageCard(
                      icon: Icons.store_mall_directory_outlined,
                      message: 'لا توجد متاجر تطابق الفلاتر الحالية.',
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.all(AssalSpacing.lg),
                    children: stores
                        .map<Widget>(
                          (store) => StoreCard(
                            store: store,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StoreProfileScreen(
                                  repository: widget.repository,
                                  storeId: store.id,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                }
                return AssalStateView<List<AssalStoreSummary>>(
                  state: state,
                  builder: (_) => const SizedBox.shrink(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

