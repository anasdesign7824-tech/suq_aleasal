// Existing discovery code predates the shared UX pass and uses intentional one-line guards.
// Keep the current layout stable while new shared components remain fully linted.
// ignore_for_file: curly_braces_in_flow_control_structures
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
  const HomeScreen(
      {super.key,
      required this.repository,
      required this.onOpenSearch,
      required this.onOpenNotifications});
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
  late Future<AssalLoadState<List<AssalNotificationSummary>>>
      notificationsFuture;
  late Future<bool> initialContentFuture;
  final searchController = TextEditingController();
  late final ScrollController scrollController;
  bool deferredDataStarted = true;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    _load();
  }

  @override
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _load() {
    // All home rails start together. Empty Production data is rendered as an
    // explicit state; it must never be confused with a missing widget.
    featuredFuture = widget.repository
        .listProducts(query: const AssalProductQuery(featuredOnly: true));
    taxonomyFuture = widget.repository.listTaxonomy();
    bannersFuture = widget.repository.listBanners();
    notificationsFuture = _loadNotifications();
    storesFuture = widget.repository.listStores();
    popularFuture = widget.repository
        .listProducts(query: const AssalProductQuery(sort: AssalSort.popular));
    newProductsFuture = widget.repository
        .listProducts(query: const AssalProductQuery(sort: AssalSort.newest));
    verifiedProductsFuture = widget.repository.listProducts(
        query: const AssalProductQuery(
            verifiedStoresOnly: true, sort: AssalSort.rating));
    personalizedFuture = _buildPersonalizedFeed();
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

  Future<AssalLoadState<List<AssalProductSummary>>>
      _buildPersonalizedFeed() async {
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

    final favoriteProducts =
        favoriteState is AssalData<List<AssalProductSummary>>
            ? favoriteState.value
            : const <AssalProductSummary>[];
    final followedStores = followedState is AssalData<List<AssalStoreSummary>>
        ? followedState.value
        : const <AssalStoreSummary>[];
    final favoriteIds = favoriteProducts.map((item) => item.id).toSet();
    final followedStoreIds = followedStores.map((item) => item.id).toSet();
    final viewedIds =
        _preferenceStrings(user.preferences['viewed_product_ids']);
    final preferredTypes = _preferenceStrings(
      user.preferences['preferred_product_types'],
    );
    final location = (user.location ?? '').trim().toLowerCase();

    int score(AssalProductSummary product) {
      var value = 0;
      if (favoriteIds.contains(product.id)) value += 100;
      if (followedStoreIds.contains(product.storeId)) value += 70;
      if (viewedIds.contains(product.id.toLowerCase())) value += 35;
      if (preferredTypes.contains(product.productType.name.toLowerCase()))
        value += 30;
      final productLocations = <String?>[
        product.regionNameAr,
        product.provinceNameAr,
        product.originCountry,
      ];
      if (location.isNotEmpty &&
          productLocations.any(
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

  Future<AssalLoadState<List<AssalNotificationSummary>>>
      _loadNotifications() async {
    final session = await widget.repository.getSession();
    final userId = session.user?.id;
    if (userId == null || userId.isEmpty)
      return const AssalEmpty('سجّل الدخول لرؤية إشعاراتك');
    return widget.repository.listNotifications(userId);
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<bool>(
          future: initialContentFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return const CustomScrollView(slivers: [
                SliverFillRemaining(
                    hasScrollBody: false,
                    child: AssalMessageCard(
                        icon: Icons.wifi_off_outlined,
                        message:
                            'تعذر تجهيز الصفحة الآن. تحقق من الاتصال ثم أعد المحاولة.'))
              ]);
            if (snapshot.data != true) return _loadingBody();
            return CustomScrollView(controller: scrollController, slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedHeaderDelegate(
                  topInset: MediaQuery.paddingOf(context).top,
                  child: _Header(
                    repository: widget.repository,
                    notificationsFuture: notificationsFuture,
                    bannersFuture: bannersFuture,
                    onOpenNotifications: widget.onOpenNotifications,
                    searchController: searchController,
                    onOpenSearch: widget.onOpenSearch,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                  child: SizedBox(height: AssalSpacing.sm)),
              SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AssalSpacing.lg),
                  sliver: SliverToBoxAdapter(
                      child: FutureBuilder<
                              AssalLoadState<List<AssalBannerSummary>>>(
                          future: bannersFuture,
                          builder: (context, snapshot) {
                            if (snapshot.hasError)
                              return AssalMessageCard(
                                  icon: Icons.wifi_off_outlined,
                                  message:
                                      'تعذر تحميل هذه البيانات الآن. تحقق من الاتصال ثم أعد المحاولة.',
                                  onRetry: _refresh);
                            if (!snapshot.hasData)
                              return const AssalGlassLoading(height: 76);
                            return AssalStateView<List<AssalBannerSummary>>(
                                state: snapshot.data!,
                                onRetry: _refresh,
                                builder: (banners) => _BannersCarousel(
                                    banners: banners,
                                    onExplore: widget.onOpenSearch,
                                    onRetry: _refresh,
                                    useFallbackDemo: widget.repository.mode ==
                                        AssalDataSourceMode.demo));
                          }))),
              SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AssalSpacing.lg,
                      AssalSpacing.xl, AssalSpacing.lg, AssalSpacing.sm),
                  sliver: SliverToBoxAdapter(
                      child: SectionHeader(
                          title: 'استكشف حسب التصنيف',
                          actionLabel: 'كل التصنيفات',
                          onAction: widget.onOpenSearch))),
              SliverToBoxAdapter(
                  child: SizedBox(
                      height: 92,
                      child: FutureBuilder<AssalLoadState<List<AssalTaxonomy>>>(
                          future: taxonomyFuture,
                          builder: (context, snapshot) {
                            if (snapshot.hasError)
                              return AssalMessageCard(
                                  icon: Icons.wifi_off_outlined,
                                  message:
                                      'تعذر تحميل هذه البيانات الآن. تحقق من الاتصال ثم أعد المحاولة.',
                                  onRetry: _refresh);
                            if (!snapshot.hasData)
                              return const AssalGlassLoading(height: 92);
                            return AssalStateView<List<AssalTaxonomy>>(
                                state: snapshot.data!,
                                builder: (items) => ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AssalSpacing.lg),
                                    itemCount: items.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: AssalSpacing.sm),
                                    itemBuilder: (_, index) => _CategoryTile(
                                        item: items[index],
                                        onTap: () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (_) => SearchScreen(
                                                    repository:
                                                        widget.repository,
                                                    initialSubcategoryId:
                                                        items[index].id))))));
                          }))),
              SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AssalSpacing.lg,
                      AssalSpacing.xl, AssalSpacing.lg, AssalSpacing.sm),
                  sliver: SliverToBoxAdapter(
                      child: SectionHeader(
                          title: 'منتجات مختارة',
                          actionLabel: 'عرض الكل',
                          onAction: widget.onOpenSearch))),
              SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AssalSpacing.lg),
                  sliver: SliverToBoxAdapter(
                      child: FutureBuilder<
                              AssalLoadState<List<AssalProductSummary>>>(
                          future: featuredFuture,
                          builder: (context, snapshot) {
                            if (snapshot.hasError)
                              return AssalMessageCard(
                                  icon: Icons.wifi_off_outlined,
                                  message:
                                      'تعذر تحميل هذه البيانات الآن. تحقق من الاتصال ثم أعد المحاولة.',
                                  onRetry: _refresh);
                            if (!snapshot.hasData)
                              return const AssalGlassLoading(height: 300);
                            return AssalStateView<List<AssalProductSummary>>(
                                state: snapshot.data!,
                                onRetry: _refresh,
                                builder: (products) => GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithMaxCrossAxisExtent(
                                            maxCrossAxisExtent: 220,
                                            crossAxisSpacing: AssalSpacing.md,
                                            mainAxisSpacing: AssalSpacing.md,
                                            childAspectRatio: .68),
                                    itemCount: products.length > 6
                                        ? 6
                                        : products.length,
                                    itemBuilder: (_, index) => ProductCard(
                                        product: products[index],
                                        onTap: () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (_) => ProductDetailScreen(
                                                    repository:
                                                        widget.repository,
                                                    productId: products[index].id))))));
                          }))),
              if (deferredDataStarted) ...[
                SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AssalSpacing.lg,
                        AssalSpacing.xl, AssalSpacing.lg, AssalSpacing.sm),
                    sliver: SliverToBoxAdapter(
                        child: _ProductRail(
                            repository: widget.repository,
                            title: 'الأكثر مشاهدة',
                            future: popularFuture!,
                            onRetry: _refresh))),
                SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AssalSpacing.lg,
                        AssalSpacing.xl, AssalSpacing.lg, AssalSpacing.sm),
                    sliver: SliverToBoxAdapter(
                        child: _ProductRail(
                            repository: widget.repository,
                            title: 'وصل حديثًا',
                            future: newProductsFuture!,
                            onRetry: _refresh))),
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
                SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AssalSpacing.lg,
                        AssalSpacing.xl, AssalSpacing.lg, AssalSpacing.sm),
                    sliver: SliverToBoxAdapter(
                        child: SectionHeader(
                            title: 'متاجر موثوقة',
                            actionLabel: 'عرض المتاجر',
                            onAction: _openStores))),
                SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AssalSpacing.lg, 0, AssalSpacing.lg, AssalSpacing.xl),
                    sliver: SliverToBoxAdapter(
                        child: FutureBuilder<
                                AssalLoadState<List<AssalStoreSummary>>>(
                            future: storesFuture!,
                            builder: (context, snapshot) {
                              if (snapshot.hasError)
                                return AssalMessageCard(
                                    icon: Icons.wifi_off_outlined,
                                    message:
                                        'تعذر تحميل هذه البيانات الآن. تحقق من الاتصال ثم أعد المحاولة.',
                                    onRetry: _refresh);
                              if (!snapshot.hasData)
                                return const AssalGlassLoading(height: 100);
                              return AssalStateView<List<AssalStoreSummary>>(
                                state: snapshot.data!,
                                builder: (stores) => Column(
                                  children: stores.take(3).map<Widget>((store) {
                                    return StoreCard(
                                      store: store,
                                      onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  StoreProfileScreen(
                                                      repository:
                                                          widget.repository,
                                                      storeId: store.id))),
                                    );
                                  }).toList(),
                                ),
                              );
                            }))),
              ] else
                const SliverToBoxAdapter(child: SizedBox.shrink()),
              const SliverToBoxAdapter(
                  child: SizedBox(height: AssalSpacing.xl)),
            ]);
          },
        ),
      );

  Widget _loadingBody() => CustomScrollView(slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedHeaderDelegate(
            topInset: MediaQuery.paddingOf(context).top,
            child: _Header(
              repository: widget.repository,
              notificationsFuture: notificationsFuture,
              bannersFuture: bannersFuture,
              onOpenNotifications: widget.onOpenNotifications,
              searchController: searchController,
              onOpenSearch: widget.onOpenSearch,
            ),
          ),
        ),
        const SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
                padding: EdgeInsets.all(AssalSpacing.lg),
                child: AssalGlassLoading(
                    height: 520, label: 'جارٍ تحميل الصفحة والمنتجات...'))),
      ]);
}

class _NewsTicker extends StatefulWidget {
  const _NewsTicker({required this.items, required this.onTap});
  final List<AssalBannerSummary> items;
  final VoidCallback onTap;

  @override
  State<_NewsTicker> createState() => _NewsTickerState();
}

class _NewsTickerState extends State<_NewsTicker> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.items.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        setState(() => _index = (_index + 1) % widget.items.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final item = widget.items[_index % widget.items.length];
    return Padding(
      padding: const EdgeInsets.only(top: AssalSpacing.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AssalRadius.medium),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.md),
            decoration: BoxDecoration(
              color: AssalColors.surface.withValues(alpha: .78),
              borderRadius: BorderRadius.circular(AssalRadius.medium),
              border: Border.all(
                color: AssalColors.cream.withValues(alpha: .95),
              ),
              boxShadow: [
                BoxShadow(
                  color: AssalColors.deepBrown.withValues(alpha: .06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.campaign_outlined,
                  size: 20,
                  color: AssalColors.primaryDark,
                ),
                const SizedBox(width: AssalSpacing.sm),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(.08, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Align(
                      key: ValueKey(item.id),
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        item.titleAr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AssalTypography.body.copyWith(
                          color: AssalColors.deepBrown,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AssalSpacing.sm),
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 14,
                  color: AssalColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedHeaderDelegate({required this.topInset, required this.child});
  static const contentExtent = 160.0;
  final double topInset;
  final Widget child;

  @override
  double get minExtent => topInset + contentExtent;

  @override
  double get maxExtent => topInset + contentExtent;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      DecoratedBox(
        decoration: const BoxDecoration(gradient: assalDarkGradient),
        child: Material(
          color: Colors.transparent,
          elevation: overlapsContent ? 4 : 0,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AssalSpacing.lg,
              topInset + AssalSpacing.xs,
              AssalSpacing.lg,
              AssalSpacing.sm,
            ),
            child: SizedBox(
              height: contentExtent - AssalSpacing.xs - AssalSpacing.sm,
              child: child,
            ),
          ),
        ),
      );

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) => true;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.repository,
    required this.notificationsFuture,
    required this.bannersFuture,
    required this.onOpenNotifications,
    required this.searchController,
    required this.onOpenSearch,
  });
  final AssalRepository repository;
  final Future<AssalLoadState<List<AssalNotificationSummary>>>
      notificationsFuture;
  final Future<AssalLoadState<List<AssalBannerSummary>>> bannersFuture;
  final VoidCallback onOpenNotifications;
  final TextEditingController searchController;
  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AssalBrandMark(
                  size: 30,
                  showName: true,
                  framed: true,
                  nameColor: Colors.white,
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      ),
                      icon: const Icon(Icons.settings_outlined,
                          color: Colors.white),
                      tooltip: 'الإعدادات',
                      visualDensity: VisualDensity.compact,
                    ),
                    FutureBuilder<
                        AssalLoadState<List<AssalNotificationSummary>>>(
                      future: notificationsFuture,
                      builder: (context, snapshot) {
                        final state = snapshot.data;
                        final unread =
                            state is AssalData<List<AssalNotificationSummary>>
                                ? state.value
                                    .where((item) => item.readAt == null)
                                    .length
                                : 0;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              onPressed: onOpenNotifications,
                              icon: const Icon(Icons.notifications_none_rounded,
                                  color: Colors.white),
                              tooltip: 'الإشعارات',
                              visualDensity: VisualDensity.compact,
                            ),
                            if (unread > 0)
                              Positioned(
                                top: 1,
                                right: 1,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AssalColors.error,
                                    borderRadius:
                                        BorderRadius.circular(AssalRadius.pill),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    child: Text(
                                      '$unread',
                                      style: AssalTypography.caption
                                          .copyWith(color: AssalColors.cream),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AssalSpacing.xs),
          FutureBuilder<AssalLoadState<List<AssalBannerSummary>>>(
            future: bannersFuture,
            builder: (context, snapshot) {
              final state = snapshot.data;
              final items = state is AssalData<List<AssalBannerSummary>>
                  ? state.value
                  : const <AssalBannerSummary>[];
              final tickerItems = items.isNotEmpty ||
                      repository.mode != AssalDataSourceMode.demo ||
                      state != null
                  ? items
                  : const <AssalBannerSummary>[
                      AssalBannerSummary(
                        id: 'demo-ticker-loading',
                        titleAr:
                            'الثقة تبدأ من المصدر   •   سدر يمني من وديانه',
                        descriptionAr: '',
                        ctaLabelAr: 'استكشف',
                        imageUrl: '',
                      ),
                    ];
              return _HomeIntroTicker(
                items: tickerItems,
                onTap: onOpenSearch,
              );
            },
          ),
          const SizedBox(height: AssalSpacing.md),
          SizedBox(
            height: 48,
            child: TextField(
              controller: searchController,
              readOnly: true,
              onTap: onOpenSearch,
              style: AssalTypography.body.copyWith(
                color: AssalColors.deepBrown,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AssalColors.cream,
                prefixIcon:
                    const Icon(Icons.search, color: AssalColors.deepBrown),
                suffixIcon: const Icon(Icons.tune_rounded,
                    color: AssalColors.deepBrown),
                hintText: 'ابحث عن سدر، سمر، شمع أو هدية',
                hintStyle: AssalTypography.bodySmall.copyWith(
                  color: AssalColors.textMuted,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: AssalSpacing.md),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AssalRadius.medium),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      );
}

class _HomeIntroTicker extends StatefulWidget {
  const _HomeIntroTicker({required this.items, required this.onTap});
  final List<AssalBannerSummary> items;
  final VoidCallback onTap;

  @override
  State<_HomeIntroTicker> createState() => _HomeIntroTickerState();
}

class _HomeIntroTickerState extends State<_HomeIntroTicker>
    with SingleTickerProviderStateMixin {
  static const _introText =
      'اكتشف العسل من مصدره • تصفح المتاجر والمنتجات اليمنية الموثوقة • تواصل مع التاجر بسهولة';
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannerText = widget.items
        .map((item) => item.titleAr.trim())
        .where((item) => item.isNotEmpty)
        .join('   •   ');
    final text =
        bannerText.isEmpty ? _introText : '$_introText   •   $bannerText';
    final style = AssalTypography.bodySmall.copyWith(
      color: AssalColors.cream,
      fontWeight: FontWeight.w600,
      letterSpacing: .1,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AssalRadius.medium),
        child: Container(
          height: 42,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
              colors: [
                Colors.white.withValues(alpha: .20),
                Colors.white.withValues(alpha: .07),
                Colors.white.withValues(alpha: .16),
              ],
            ),
            borderRadius: BorderRadius.circular(AssalRadius.large),
            border: Border.all(color: Colors.white.withValues(alpha: .34)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .10),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final painter = TextPainter(
                text: TextSpan(text: text, style: style),
                textDirection: TextDirection.rtl,
                maxLines: 1,
              )..layout();
              final textWidth = painter.width + AssalSpacing.lg;
              final start = constraints.maxWidth + AssalSpacing.md;
              final end = -textWidth - AssalSpacing.md;
              return AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  final x = start + (end - start) * controller.value;
                  return ClipRect(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          left: x,
                          top: 0,
                          bottom: 0,
                          width: textWidth,
                          child: Center(child: child),
                        ),
                      ],
                    ),
                  );
                },
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    text,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: style,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BannersCarousel extends StatefulWidget {
  const _BannersCarousel({
    required this.banners,
    required this.onExplore,
    required this.onRetry,
    required this.useFallbackDemo,
  });
  final List<AssalBannerSummary> banners;
  final VoidCallback onExplore;
  final VoidCallback onRetry;
  final bool useFallbackDemo;

  @override
  State<_BannersCarousel> createState() => _BannersCarouselState();
}

class _BannersCarouselState extends State<_BannersCarousel> {
  late final PageController controller;
  Timer? timer;
  int currentIndex = 0;

  List<AssalBannerSummary> get visibleBanners => widget.banners
      .where((item) =>
          item.imageUrl.trim().startsWith('http') ||
          item.imageUrl.trim().startsWith('assets/'))
      .take(4)
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    controller = PageController();
    if (visibleBanners.length > 1) {
      timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || !controller.hasClients) return;
        final next = (currentIndex + 1) % visibleBanners.length;
        controller.animateToPage(next,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic);
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
    final banners = visibleBanners;
    if (banners.isEmpty) {
      if (widget.useFallbackDemo) {
        return _HeroBanner(onExplore: widget.onExplore);
      }
      return _BannerEmptyState(
          onExplore: widget.onExplore, onRetry: widget.onRetry);
    }
    return Column(children: [
      SizedBox(
        height: 210,
        child: PageView.builder(
          controller: controller,
          itemCount: banners.length,
          onPageChanged: (index) => setState(() => currentIndex = index),
          itemBuilder: (_, index) =>
              _BannerCard(item: banners[index], onExplore: widget.onExplore),
        ),
      ),
      const SizedBox(height: AssalSpacing.sm),
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
              banners.length,
              (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: index == currentIndex ? 22 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                      color: index == currentIndex
                          ? AssalColors.primaryDark
                          : AssalColors.border,
                      borderRadius: BorderRadius.circular(AssalRadius.pill))))),
    ]);
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.item, required this.onExplore});
  final AssalBannerSummary item;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final source = item.imageUrl.trim();
    final image = source.startsWith('assets/')
        ? Image.asset(
            source,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _BannerImageFallback(),
          )
        : Image.network(
            source,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const AssalGlassLoading(
                    height: 72, label: 'جارٍ تحميل الصورة...'),
            errorBuilder: (_, __, ___) => const _BannerImageFallback(),
          );
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AssalRadius.extraLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onExplore,
        child: SizedBox(
          height: 210,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              image,
              if (item.titleAr.trim().isNotEmpty)
                Positioned(
                  left: AssalSpacing.md,
                  right: AssalSpacing.md,
                  bottom: AssalSpacing.md,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AssalColors.deepBrown.withValues(alpha: .72),
                      borderRadius: BorderRadius.circular(AssalRadius.medium),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AssalSpacing.md,
                          vertical: AssalSpacing.xs),
                      child: Text(
                        item.titleAr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AssalTypography.bodySmall.copyWith(
                          color: AssalColors.cream,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerEmptyState extends StatelessWidget {
  const _BannerEmptyState({required this.onExplore, required this.onRetry});
  final VoidCallback onExplore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          SizedBox(
            height: 210,
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AssalRadius.extraLarge),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onExplore,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AssalColors.deepBrown, AssalColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(AssalRadius.extraLarge),
                    border: Border.all(
                      color: AssalColors.primaryLight.withValues(alpha: .35),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AssalSpacing.xl),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.image_outlined,
                          size: 58,
                          color: AssalColors.primaryLight,
                        ),
                        const SizedBox(width: AssalSpacing.lg),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'لا توجد بنرات منشورة بعد',
                                style: AssalTypography.heading3.copyWith(
                                  color: AssalColors.cream,
                                ),
                              ),
                              const SizedBox(height: AssalSpacing.sm),
                              Text(
                                'سيظهر المحتوى هنا تلقائيًا عند نشره من لوحة الإدارة.',
                                style: AssalTypography.bodySmall.copyWith(
                                  color:
                                      AssalColors.cream.withValues(alpha: .84),
                                ),
                              ),
                              const SizedBox(height: AssalSpacing.md),
                              Wrap(
                                spacing: AssalSpacing.sm,
                                children: [
                                  OutlinedButton(
                                    onPressed: onExplore,
                                    child: const Text('استكشف المنتجات'),
                                  ),
                                  TextButton(
                                    onPressed: onRetry,
                                    child: const Text('تحديث'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AssalSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 8,
                decoration: BoxDecoration(
                  color: AssalColors.primaryDark,
                  borderRadius: BorderRadius.circular(AssalRadius.pill),
                ),
              ),
            ],
          ),
        ],
      );
}

class _BannerImageFallback extends StatelessWidget {
  const _BannerImageFallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: AssalColors.cream,
        child: Center(
          child: Icon(Icons.image_not_supported_outlined,
              color: AssalColors.textMuted, size: 38),
        ),
      );
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onExplore});
  final VoidCallback onExplore;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(AssalSpacing.xl),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AssalColors.deepBrown, AssalColors.secondary]),
          borderRadius: BorderRadius.circular(AssalRadius.extraLarge)),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('الثقة تبدأ من المصدر',
              style:
                  AssalTypography.heading2.copyWith(color: AssalColors.cream)),
          const SizedBox(height: AssalSpacing.sm),
          Text('اعرف النوع والمنطقة والتوثيق قبل أن تتواصل.',
              style: AssalTypography.body.copyWith(color: AssalColors.cream)),
          const SizedBox(height: AssalSpacing.md),
          FilledButton.tonal(
              onPressed: onExplore, child: const Text('ابدأ الاكتشاف'))
        ])),
        const Icon(Icons.local_florist_rounded,
            size: 74, color: AssalColors.primaryLight)
      ]));
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.item, required this.onTap});
  final AssalTaxonomy item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AssalRadius.large),
      child: Container(
          width: 122,
          padding: const EdgeInsets.all(AssalSpacing.sm),
          decoration: BoxDecoration(
              color: AssalColors.surface,
              border: Border.all(color: AssalColors.border),
              borderRadius: BorderRadius.circular(AssalRadius.large)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(
              _taxonomyIcon(item.nameAr),
              color: AssalColors.primaryDark,
            ),
            const SizedBox(height: AssalSpacing.xs),
            Text(item.nameAr,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AssalTypography.caption
                    .copyWith(color: AssalColors.deepBrown))
          ])));
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
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              if (snapshot.hasError)
                return AssalMessageCard(
                    icon: Icons.wifi_off_outlined,
                    message:
                        'تعذر تحميل هذه البيانات الآن. تحقق من الاتصال ثم أعد المحاولة.',
                    onRetry: onRetry);
              if (!snapshot.hasData) return const AssalGlassLoading();
              return AssalStateView<List<AssalProductSummary>>(
                state: snapshot.data!,
                builder: (products) => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AssalSpacing.xs),
                  itemCount: products.length > 8 ? 8 : products.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AssalSpacing.md),
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
  const CategoriesScreen({
    super.key,
    required this.repository,
    this.showAppBar = true,
  });
  final AssalRepository repository;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar ? const AssalAppBar(title: 'التصنيفات') : null,
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
                final description = category.description?.trim();
                final subtitle = <String>[
                  if (description != null &&
                      description.isNotEmpty &&
                      !description.contains('Master'))
                    description,
                  '${category.productCount} منتج متاح',
                ].join('\n');
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AssalColors.honeyLight,
                      child: Icon(
                        _taxonomyIcon(category.nameAr, category.productType),
                        color: AssalColors.primaryDark,
                      ),
                    ),
                    title: Text(category.nameAr),
                    subtitle: Text(subtitle),
                    isThreeLine: subtitle.contains('\n'),
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
}

IconData _taxonomyIcon(String nameAr, [ProductType? type]) {
  final name = nameAr.trim();
  if (name.contains('شمع')) return Icons.hexagon_outlined;
  if (name.contains('سدر')) return Icons.water_drop_outlined;
  if (name.contains('سمر') || name.contains('طلح')) {
    return Icons.eco_outlined;
  }
  if (name.contains('خلط') || name.contains('مزيج')) {
    return Icons.local_florist_outlined;
  }
  if (name.contains('هد')) return Icons.card_giftcard_outlined;
  if (name.contains('صافي') || name.contains('سائل')) {
    return Icons.opacity_outlined;
  }
  return switch (type ?? ProductType.honey) {
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
  late final TextEditingController controller =
      TextEditingController(text: widget.initialQuery);
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
  List<AssalCategorySummary> filterCategories = const <AssalCategorySummary>[];
  List<AssalTaxonomy> filterTaxonomy = const <AssalTaxonomy>[];
  late Future<AssalLoadState<List<AssalStoreSummary>>> storesFuture;
  late Future<AssalLoadState<List<String>>> popularSearchesFuture;

  @override
  void initState() {
    super.initState();
    categoryId = widget.initialCategoryId;
    subcategoryId = widget.initialSubcategoryId;
    verifiedOnly = widget.verifiedOnly;
    unawaited(_primeFilterLabels());
    unawaited(_primeLocationReference());
    _search();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _primeFilterLabels() async {
    final categories = await widget.repository.listCategories();
    final taxonomy = await widget.repository.listTaxonomy();
    if (!mounted) return;
    setState(() {
      if (categories is AssalData<List<AssalCategorySummary>>) {
        filterCategories = categories.value;
      }
      if (taxonomy is AssalData<List<AssalTaxonomy>>) {
        filterTaxonomy = taxonomy.value;
      }
    });
  }

  Future<void> _primeLocationReference() async {
    try {
      final reference = await YemenLocationReference.load();
      if (mounted) locationReference = reference;
    } on Object {
      // The filter sheet retries explicitly and owns the user-facing message.
    }
  }

  String _categoryLabel(String id) => filterCategories
      .where((item) => item.id == id)
      .map((item) => item.nameAr)
      .firstWhere((name) => name.isNotEmpty, orElse: () => 'القسم المحدد');

  String _subcategoryLabel(String id) => filterTaxonomy
      .where((item) => item.id == id)
      .map((item) => item.nameAr)
      .firstWhere((name) => name.isNotEmpty, orElse: () => 'التصنيف المحدد');

  String _regionLabel(String id) =>
      locationReference?.governorateByCode(id)?.nameAr ??
      locationReference?.governorateByCode(id)?.nameAr ??
      'المحافظة المحددة';

  String _provinceLabel(String id) =>
      locationReference?.districtByCode(id)?.nameAr ?? 'المديرية المحددة';

  void _search() {
    final query = AssalProductQuery(
        categoryId: categoryId,
        search: controller.text,
        subcategoryId: subcategoryId,
        regionId: regionId,
        provinceId: provinceId,
        gradeLevel: gradeLevel,
        productType: productType,
        verifiedStoresOnly: verifiedOnly,
        originCountry: originCountry,
        processingMethod: processingMethod,
        packaging: packaging,
        availability: availability,
        minRating: minRating,
        minPrice: minPrice,
        maxPrice: maxPrice,
        sort: sort);
    productsFuture = widget.repository.listProducts(query: query);
    storesFuture = widget.repository.listStores();
    popularSearchesFuture = widget.repository.listPopularSearches();
  }

  void _captureFilterOptions(List<AssalProductSummary> products) {
    for (final product in products) {
      if (product.originCountry != null)
        originOptions.add(product.originCountry!);
      if (product.processingMethodAr != null)
        processingOptions.add(product.processingMethodAr!);
      if (product.packagingLabelAr != null)
        packagingOptions.add(product.packagingLabelAr!);
      if (product.availability.isNotEmpty)
        availabilityOptions.add(product.availability);
      if (product.price != null) {
        dataMinPrice = dataMinPrice == null || product.price! < dataMinPrice!
            ? product.price
            : dataMinPrice;
        dataMaxPrice = dataMaxPrice == null || product.price! > dataMaxPrice!
            ? product.price
            : dataMaxPrice;
      }
      if (product.ratingAverage > dataMaxRating)
        dataMaxRating = product.ratingAverage;
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
          InputChip(
              label: Text('القسم: ${_categoryLabel(categoryId!)}'),
              onDeleted: () => setState(() {
                    categoryId = null;
                    _search();
                  })),
        if (subcategoryId != null)
          InputChip(
              label: Text('التصنيف: ${_subcategoryLabel(subcategoryId!)}'),
              onDeleted: () => setState(() {
                    subcategoryId = null;
                    _search();
                  })),
        if (regionId != null)
          InputChip(
              label: Text('المحافظة: ${_regionLabel(regionId!)}'),
              onDeleted: () => setState(() {
                    regionId = null;
                    provinceId = null;
                    _search();
                  })),
        if (provinceId != null)
          InputChip(
              label: Text('المديرية: ${_provinceLabel(provinceId!)}'),
              onDeleted: () => setState(() {
                    provinceId = null;
                    _search();
                  })),
        if (productType != null)
          InputChip(
              label: Text(_productTypeLabel(productType!)),
              onDeleted: () => setState(() {
                    productType = null;
                    _search();
                  })),
        if (gradeLevel != null)
          InputChip(
              label: Text('الدرجة $gradeLevel'),
              onDeleted: () => setState(() {
                    gradeLevel = null;
                    _search();
                  })),
        if (verifiedOnly)
          InputChip(
              label: const Text('متاجر موثقة'),
              onDeleted: () => setState(() {
                    verifiedOnly = false;
                    _search();
                  })),
        if (originCountry != null)
          InputChip(
              label: Text('الأصل: $originCountry'),
              onDeleted: () => setState(() {
                    originCountry = null;
                    _search();
                  })),
        if (processingMethod != null)
          InputChip(
              label: Text('المعالجة: $processingMethod'),
              onDeleted: () => setState(() {
                    processingMethod = null;
                    _search();
                  })),
        if (packaging != null)
          InputChip(
              label: Text('التعبئة: $packaging'),
              onDeleted: () => setState(() {
                    packaging = null;
                    _search();
                  })),
        if (availability != null)
          InputChip(
              label: Text('التوفر: $availability'),
              onDeleted: () => setState(() {
                    availability = null;
                    _search();
                  })),
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
          padding: const EdgeInsets.fromLTRB(
              AssalSpacing.lg, AssalSpacing.md, AssalSpacing.lg, 0),
          child: TextField(
            controller: controller,
            autofocus: true,
            onSubmitted: (_) => _applySearch(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'اكتب اسم المنتج أو المنطقة',
              suffixIcon: IconButton(
                  onPressed: () {
                    controller.clear();
                    _applySearch();
                  },
                  icon: const Icon(Icons.clear),
                  tooltip: 'مسح'),
            ),
          ),
        ),
        FutureBuilder<AssalLoadState<List<String>>>(
          future: popularSearchesFuture,
          builder: (context, snapshot) {
            if (snapshot.data is! AssalData<List<String>>)
              return const SizedBox.shrink();
            final terms = (snapshot.data! as AssalData<List<String>>).value;
            return SizedBox(
              height: 42,
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: AssalSpacing.lg),
                scrollDirection: Axis.horizontal,
                itemCount: terms.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AssalSpacing.sm),
                itemBuilder: (_, index) => ActionChip(
                    label: Text(terms[index]),
                    onPressed: () {
                      controller.text = terms[index];
                      _applySearch();
                    }),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AssalSpacing.lg, vertical: AssalSpacing.sm),
          child: Row(children: [
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: _showFilters,
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(_activeFilterCount == 0
                        ? 'الفلاتر'
                        : 'الفلاتر ($_activeFilterCount)'))),
            const SizedBox(width: AssalSpacing.sm),
            PopupMenuButton<AssalSort>(
              initialValue: sort,
              onSelected: (value) => setState(() {
                sort = value;
                _search();
              }),
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: AssalSort.featured, child: Text('المميزة أولًا')),
                PopupMenuItem(value: AssalSort.newest, child: Text('الأحدث')),
                PopupMenuItem(
                    value: AssalSort.popular, child: Text('الأكثر شعبية')),
                PopupMenuItem(
                    value: AssalSort.rating, child: Text('الأعلى تقييمًا')),
              ],
              child: const Chip(
                  avatar: Icon(Icons.sort, size: 18), label: Text('ترتيب')),
            ),
          ]),
        ),
        if (_activeFilterCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AssalSpacing.lg, 0, AssalSpacing.lg, AssalSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: Wrap(
                        spacing: AssalSpacing.xs,
                        runSpacing: AssalSpacing.xs,
                        children: _activeFilterChips())),
                TextButton(
                    onPressed: _clearFilters, child: const Text('مسح الكل')),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _applySearch(),
            child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AssalSpacing.lg, 0, AssalSpacing.lg, AssalSpacing.xl),
                children: [
                  const SectionHeader(title: 'المنتجات'),
                  FutureBuilder<AssalLoadState<List<AssalProductSummary>>>(
                    future: productsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasError)
                        return AssalMessageCard(
                            icon: Icons.wifi_off_outlined,
                            message:
                                'تعذر تحميل المنتجات الآن. تحقق من الاتصال ثم أعد المحاولة.',
                            onRetry: _applySearch);
                      if (!snapshot.hasData)
                        return const AssalGlassLoading(height: 300);
                      final productState = snapshot.data!;
                      if (productState
                          is AssalData<List<AssalProductSummary>>) {
                        _captureFilterOptions(productState.value);
                      }
                      return AssalStateView<List<AssalProductSummary>>(
                        state: snapshot.data!,
                        onRetry: _applySearch,
                        builder: (products) => GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 220,
                                  crossAxisSpacing: AssalSpacing.md,
                                  mainAxisSpacing: AssalSpacing.md,
                                  childAspectRatio: .68),
                          itemCount: products.length,
                          itemBuilder: (_, index) {
                            final product = products[index];
                            return ProductCard(
                              product: product,
                              onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => ProductDetailScreen(
                                          repository: widget.repository,
                                          productId: product.id))),
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
                      if (snapshot.hasError)
                        return AssalMessageCard(
                            icon: Icons.wifi_off_outlined,
                            message:
                                'تعذر تحميل المتاجر الآن. تحقق من الاتصال ثم أعد المحاولة.',
                            onRetry: _applySearch);
                      if (!snapshot.hasData)
                        return const AssalGlassLoading(height: 120);
                      return AssalStateView<List<AssalStoreSummary>>(
                        state: snapshot.data!,
                        builder: (stores) => Column(
                          children: stores.map<Widget>((store) {
                            return StoreCard(
                              store: store,
                              onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => StoreProfileScreen(
                                          repository: widget.repository,
                                          storeId: store.id))),
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
    // The sheet must open immediately. Reference reads are local/refreshable and
    // must not block the user's tap while production queries are in flight.
    unawaited(_primeFilterLabels());
    unawaited(_primeLocationReference());
    final reference = locationReference;
    if (!mounted) return;
    var draftRegion = regionId ?? '';
    var draftProvince = provinceId ?? '';
    var draftCategory = categoryId ?? '';
    var draftSubcategory = subcategoryId ?? '';
    var draftGrade = gradeLevel;
    var draftType = productType;
    var draftVerified = verifiedOnly;
    var draftOrigin = originCountry ?? '';
    var draftProcessing = processingMethod ?? '';
    var draftPackaging = packaging ?? '';
    var draftAvailability = availability ?? '';
    final priceMin = dataMinPrice ?? 0;
    final observedMaxPrice = dataMaxPrice ?? priceMin;
    final priceMax =
        observedMaxPrice > priceMin ? observedMaxPrice : priceMin + 1;
    final currentMinPrice =
        (minPrice ?? priceMin).clamp(priceMin, priceMax).toDouble();
    final currentMaxPrice =
        (maxPrice ?? priceMax).clamp(priceMin, priceMax).toDouble();
    var draftPriceRange = RangeValues(
      currentMinPrice <= currentMaxPrice ? currentMinPrice : priceMin,
      currentMaxPrice >= currentMinPrice ? currentMaxPrice : priceMax,
    );
    var draftMinRatingValue =
        (minRating ?? 0).clamp(0, dataMaxRating).toDouble();
    final categoryItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(value: '', child: Text('كل الأقسام')),
      ...filterCategories.map(
        (category) => DropdownMenuItem<String>(
          value: category.id,
          child: Text(category.nameAr),
        ),
      ),
    ];
    List<DropdownMenuItem<String>> subcategoryItemsFor(
        String selectedCategory) {
      final taxonomies = filterTaxonomy.where((taxonomy) {
        final parentId = taxonomy.metadata['category_id'] ??
            taxonomy.metadata['parent_category_id'] ??
            taxonomy.metadata['parent_id'];
        return selectedCategory.isEmpty ||
            parentId == null ||
            parentId.toString() == selectedCategory;
      });
      return [
        const DropdownMenuItem<String>(
          value: '',
          child: Text('كل التصنيفات الفرعية'),
        ),
        ...taxonomies.map(
          (taxonomy) => DropdownMenuItem<String>(
            value: taxonomy.id,
            child: Text(taxonomy.nameAr),
          ),
        ),
      ];
    }

    if (!categoryItems.any((item) => item.value == draftCategory)) {
      draftCategory = '';
    }
    if (!subcategoryItemsFor(draftCategory)
        .any((item) => item.value == draftSubcategory)) {
      draftSubcategory = '';
    }
    final typeItems = <DropdownMenuItem<ProductType?>>[
      const DropdownMenuItem<ProductType?>(
          value: null, child: Text('كل الأنواع')),
      ...ProductType.values.map<DropdownMenuItem<ProductType?>>((type) =>
          DropdownMenuItem<ProductType?>(
              value: type, child: Text(_productTypeLabel(type)))),
    ];
    final gradeItems = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(value: null, child: Text('كل الدرجات')),
      ...[1, 2, 3, 4].map<DropdownMenuItem<int?>>((grade) =>
          DropdownMenuItem<int?>(value: grade, child: Text('درجة $grade'))),
    ];
    final originItems = _stringOptions(originOptions);
    final processingItems = _stringOptions(processingOptions);
    final packagingItems = _stringOptions(packagingOptions);
    final availabilityItems = _stringOptions(availabilityOptions);
    final regionItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(value: '', child: Text('كل المحافظات')),
      ...(reference?.governorates ?? const <AssalRegion>[]).map(
        (region) => DropdownMenuItem<String>(
          value: region.code ?? region.id,
          child: Text(region.nameAr),
        ),
      ),
    ];
    if (!regionItems.any((item) => item.value == draftRegion)) {
      draftRegion = '';
    }
    final validDistricts =
        reference?.districtsFor(draftRegion) ?? const <AssalRegion>[];
    if (!validDistricts
        .any((item) => (item.code ?? item.id) == draftProvince)) {
      draftProvince = '';
    }
    final apply = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
          builder: (context, setModalState) => Padding(
                padding: EdgeInsets.only(
                    left: AssalSpacing.xl,
                    right: AssalSpacing.xl,
                    top: AssalSpacing.xl,
                    bottom: MediaQuery.viewInsetsOf(context).bottom +
                        AssalSpacing.xl),
                child: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('تصفية النتائج',
                          style: AssalTypography.heading2
                              .copyWith(color: AssalColors.deepBrown)),
                      const SizedBox(height: AssalSpacing.md),
                      DropdownButtonFormField<String>(
                          initialValue: draftRegion,
                          decoration:
                              const InputDecoration(labelText: 'المحافظة'),
                          items: regionItems,
                          onChanged: (value) => setModalState(() {
                                draftRegion = value ?? '';
                                draftProvince = '';
                              })),
                      DropdownButtonFormField<String>(
                          initialValue: draftProvince,
                          decoration:
                              const InputDecoration(labelText: 'المديرية'),
                          items: [
                            const DropdownMenuItem<String>(
                                value: '', child: Text('كل المديريات')),
                            ...(reference?.districtsFor(draftRegion) ??
                                    const <AssalRegion>[])
                                .map((district) => DropdownMenuItem<String>(
                                    value: district.code ?? district.id,
                                    child: Text(district.nameAr)))
                          ],
                          onChanged: draftRegion.isEmpty
                              ? null
                              : (value) => setModalState(
                                  () => draftProvince = value ?? '')),
                      DropdownButtonFormField<String>(
                          initialValue: draftCategory,
                          decoration: const InputDecoration(labelText: 'القسم'),
                          items: categoryItems,
                          onChanged: (value) => setModalState(() {
                                draftCategory = value ?? '';
                                draftSubcategory = '';
                              })),
                      DropdownButtonFormField<String>(
                          initialValue: draftSubcategory,
                          decoration: const InputDecoration(
                              labelText: 'التصنيف الفرعي'),
                          items: subcategoryItemsFor(draftCategory),
                          onChanged: (value) => setModalState(
                              () => draftSubcategory = value ?? '')),
                      DropdownButtonFormField<ProductType?>(
                          initialValue: draftType,
                          decoration:
                              const InputDecoration(labelText: 'نوع المنتج'),
                          items: typeItems,
                          onChanged: (value) =>
                              setModalState(() => draftType = value)),
                      DropdownButtonFormField<int?>(
                          initialValue: draftGrade,
                          decoration:
                              const InputDecoration(labelText: 'درجة الجودة'),
                          items: gradeItems,
                          onChanged: (value) =>
                              setModalState(() => draftGrade = value)),
                      SwitchListTile(
                          value: draftVerified,
                          onChanged: (value) =>
                              setModalState(() => draftVerified = value),
                          title: const Text('المتاجر الموثقة فقط')),
                      DropdownButtonFormField<String>(
                          initialValue: draftOrigin,
                          decoration: const InputDecoration(
                              labelText: 'بلد/منطقة الأصل'),
                          items: originItems,
                          onChanged: (value) =>
                              setModalState(() => draftOrigin = value ?? '')),
                      DropdownButtonFormField<String>(
                          initialValue: draftProcessing,
                          decoration: const InputDecoration(
                              labelText: 'طريقة المعالجة'),
                          items: processingItems,
                          onChanged: (value) => setModalState(
                              () => draftProcessing = value ?? '')),
                      DropdownButtonFormField<String>(
                          initialValue: draftPackaging,
                          decoration:
                              const InputDecoration(labelText: 'التعبئة'),
                          items: packagingItems,
                          onChanged: (value) => setModalState(
                              () => draftPackaging = value ?? '')),
                      DropdownButtonFormField<String>(
                          initialValue: draftAvailability,
                          decoration:
                              const InputDecoration(labelText: 'التوفر'),
                          items: availabilityItems,
                          onChanged: (value) => setModalState(
                              () => draftAvailability = value ?? '')),
                      Text(
                          'نطاق السعر: ${draftPriceRange.start.toStringAsFixed(0)} – ${draftPriceRange.end.toStringAsFixed(0)} ريال',
                          style: AssalTypography.bodyLarge
                              .copyWith(color: AssalColors.textSecondary)),
                      RangeSlider(
                        min: priceMin,
                        max: priceMax,
                        divisions: 100,
                        values: draftPriceRange,
                        labels: RangeLabels(
                          draftPriceRange.start.toStringAsFixed(0),
                          draftPriceRange.end.toStringAsFixed(0),
                        ),
                        onChanged: (value) =>
                            setModalState(() => draftPriceRange = value),
                      ),
                      Text(
                          'أدنى تقييم: ${draftMinRatingValue.toStringAsFixed(1)} من ${dataMaxRating.toStringAsFixed(1)}',
                          style: AssalTypography.bodyLarge
                              .copyWith(color: AssalColors.textSecondary)),
                      Slider(
                        min: 0,
                        max: dataMaxRating,
                        divisions: 10,
                        value: draftMinRatingValue,
                        label: draftMinRatingValue.toStringAsFixed(1),
                        onChanged: (value) =>
                            setModalState(() => draftMinRatingValue = value),
                      ),
                      const SizedBox(height: AssalSpacing.md),
                      SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                              onPressed: () {
                                regionId = draftRegion.trim().isEmpty
                                    ? null
                                    : draftRegion.trim();
                                provinceId = draftProvince.trim().isEmpty
                                    ? null
                                    : draftProvince.trim();
                                categoryId = draftCategory.trim().isEmpty
                                    ? null
                                    : draftCategory.trim();
                                subcategoryId = draftSubcategory.trim().isEmpty
                                    ? null
                                    : draftSubcategory.trim();
                                gradeLevel = draftGrade;
                                productType = draftType;
                                verifiedOnly = draftVerified;
                                originCountry = draftOrigin.trim().isEmpty
                                    ? null
                                    : draftOrigin.trim();
                                processingMethod =
                                    draftProcessing.trim().isEmpty
                                        ? null
                                        : draftProcessing.trim();
                                packaging = draftPackaging.trim().isEmpty
                                    ? null
                                    : draftPackaging.trim();
                                availability = draftAvailability.trim().isEmpty
                                    ? null
                                    : draftAvailability.trim();
                                minRating = draftMinRatingValue <= 0
                                    ? null
                                    : draftMinRatingValue;
                                minPrice = draftPriceRange.start <= priceMin
                                    ? null
                                    : draftPriceRange.start;
                                maxPrice = draftPriceRange.end >= priceMax
                                    ? null
                                    : draftPriceRange.end;
                                Navigator.pop(sheetContext, true);
                              },
                              child: const Text('تطبيق الفلاتر'))),
                    ])),
              )),
    );
    if (apply == true) _applySearch();
  }
}

String _productTypeLabel(ProductType type) => switch (type) {
      ProductType.honey => 'عسل',
      ProductType.wax => 'شمع',
      ProductType.mix => 'خلطة',
      ProductType.raw => 'منتج خام',
      ProductType.gift => 'هدية'
    };

class StoresScreen extends StatefulWidget {
  const StoresScreen({
    super.key,
    required this.repository,
    this.showAppBar = true,
  });
  final AssalRepository repository;
  final bool showAppBar;

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
      appBar: widget.showAppBar ? const AssalAppBar(title: 'المتاجر') : null,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: AssalSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: regionId,
                        decoration:
                            const InputDecoration(labelText: 'المحافظة'),
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
