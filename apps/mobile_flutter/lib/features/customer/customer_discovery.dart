import 'dart:async';

import 'package:flutter/material.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_design/assal_tokens.dart';
import '../../core/assal_widgets.dart';
import '../../core/yemen_location_reference.dart';
import 'customer_catalog.dart';

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
      return AssalEmpty('سجّل الدخول لرؤية إشعاراتك');
    return widget.repository.listNotifications(userId);
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        color: context.assalPrimary,
        onRefresh: () async => _refresh(),
        child: FutureBuilder<bool>(
          future: initialContentFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return CustomScrollView(slivers: [
                SliverFillRemaining(
                    hasScrollBody: false,
                    child: AssalMessageCard(
                        icon: Icons.wifi_off_outlined,
                        message:
                            'تعذر تجهيز الصفحة الآن. تحقق من الاتصال ثم أعد المحاولة.'))
              ]);
            if (snapshot.data != true) return _loadingBody();
            return CustomScrollView(controller: scrollController, slivers: [
              SliverToBoxAdapter(
                child: _HomeHeader(
                  repository: widget.repository,
                  notificationsFuture: notificationsFuture,
                  onOpenNotifications: widget.onOpenNotifications,
                  searchController: searchController,
                  onOpenSearch: widget.onOpenSearch,
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
                padding: const EdgeInsets.fromLTRB(
                    AssalSpacing.lg, AssalSpacing.xl, AssalSpacing.lg, AssalSpacing.sm),
                sliver: SliverToBoxAdapter(
                  child: HoneySectionHeader(
                    title: 'الأقسام',
                    subtitle: 'اكتشف التصنيف الرئيسي ثم التفاصيل',
                    actionLabel: 'كل الأقسام',
                    onAction: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            CategoriesScreen(repository: widget.repository))),
                  ),
                ),
              ),
              SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AssalSpacing.lg),
                  sliver: SliverToBoxAdapter(
                      child: FutureBuilder<
                              AssalLoadState<List<AssalTaxonomy>>>(
                          future: taxonomyFuture,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return const AssalGlassLoading(height: 72);
                            return AssalStateView<List<AssalTaxonomy>>(
                                state: snapshot.data!,
                                onRetry: _refresh,
                                builder: (items) => _CategoryRail(
                                    items: items,
                                    onTap: (item) =>
                                        Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    SearchScreen(
                                                        repository: widget
                                                            .repository,
                                                        initialSubcategoryId:
                                                            item.id)))));
                          }))),
              SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AssalSpacing.lg,
                      AssalSpacing.xl, AssalSpacing.lg, AssalSpacing.sm),
                  sliver: SliverToBoxAdapter(
                      child: HoneySectionHeader(
                          title: 'منتجات مختارة',
                          subtitle: 'أفضل ما تقدمه المنصة الآن',
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
                            subtitle: 'منتجات يتابعها السوق الآن',
                            future: popularFuture!,
                            onRetry: _refresh))),
                SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AssalSpacing.lg,
                        AssalSpacing.xl, AssalSpacing.lg, AssalSpacing.sm),
                    sliver: SliverToBoxAdapter(
                        child: _ProductRail(
                            repository: widget.repository,
                            title: 'وصل حديثًا',
                            subtitle: 'أحدث الإضافات من المناحل',
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
                      subtitle: 'من متاجر موثقة',
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
                        subtitle: 'مبنية على تفاعلك',
                        future: personalizedFuture!,
                        onRetry: _refresh,
                      ),
                    ),
                  ),
                SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AssalSpacing.lg,
                        AssalSpacing.xl, AssalSpacing.lg, AssalSpacing.sm),
                    sliver: SliverToBoxAdapter(
                        child: HoneySectionHeader(
                            title: 'متاجر موثوقة',
                            subtitle: 'ابدأ من مصدر تثق به',
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
        SliverToBoxAdapter(
          child: _HomeHeader(
            repository: widget.repository,
            notificationsFuture: notificationsFuture,
            onOpenNotifications: widget.onOpenNotifications,
            searchController: searchController,
            onOpenSearch: widget.onOpenSearch,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AssalSpacing.lg)),
        const SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
                padding: EdgeInsets.all(AssalSpacing.lg),
                child: AssalSkeletonList(count: 5))),
      ]);
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.repository,
    required this.notificationsFuture,
    required this.onOpenNotifications,
    required this.searchController,
    required this.onOpenSearch,
  });
  final AssalRepository repository;
  final Future<AssalLoadState<List<AssalNotificationSummary>>> notificationsFuture;
  final VoidCallback onOpenNotifications;
  final TextEditingController searchController;
  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      color: context.assalSurface,
      padding: EdgeInsets.fromLTRB(
          AssalSpacing.lg, top + AssalSpacing.sm, AssalSpacing.lg, AssalSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AssalBrandMark(size: 40, showName: true),
              const Spacer(),
              FutureBuilder<AssalLoadState<List<AssalNotificationSummary>>>(
                future: notificationsFuture,
                builder: (context, snapshot) {
                  final unread = snapshot.data is AssalData<List<AssalNotificationSummary>>
                      ? (snapshot.data! as AssalData<List<AssalNotificationSummary>>)
                          .value
                          .where((item) => item.readAt == null)
                          .length
                      : 0;
                  return Badge(
                    isLabelVisible: unread > 0,
                    label: Text('$unread'),
                    backgroundColor: context.assalPrimary,
                    child: IconButton(
                      onPressed: onOpenNotifications,
                      icon: Icon(Icons.notifications_none_rounded),
                      tooltip: 'الإشعارات',
                      color: context.assalTextPrimary,
                    ),
                  );
                },
              ),
              SizedBox(width: AssalSpacing.xs),
              Icon(Icons.more_vert_rounded),
            ],
          ),
          SizedBox(height: AssalSpacing.lg),
          Text(
            'العسل اليمني من مصدره',
            style: AssalTypography.heading2
                .copyWith(color: context.assalTextPrimary),
          ),
          SizedBox(height: AssalSpacing.xs),
          Text(
            'اكتشف النوع والمنطقة والتوثيق قبل أن تتواصل.',
            style:
                AssalTypography.body.copyWith(color: context.assalTextSecondary),
          ),
          SizedBox(height: AssalSpacing.md),
          InkWell(
            borderRadius: BorderRadius.circular(AssalRadius.medium),
            onTap: onOpenSearch,
            child: Container(
              height: 48,
              padding: EdgeInsets.symmetric(horizontal: AssalSpacing.md),
              decoration: BoxDecoration(
                color: context.assalSurfaceVariant,
                borderRadius: BorderRadius.circular(AssalRadius.medium),
                border: Border.all(color: context.assalBorder),
              ),
              child: Row(children: [
                Icon(Icons.search, color: context.assalPrimaryLight, size: 20),
                SizedBox(width: AssalSpacing.sm),
                Text('ابحث عن صنف أو منطقة أو متجر',
                    style: AssalTypography.body
                        .copyWith(color: context.assalTextMuted)),
              ]),
            ),
          ),
        ],
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
  late final PageController controller = PageController(viewportFraction: .88);
  int index = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return AssalMessageCard(
        icon: Icons.campaign_outlined,
        title: 'لا توجد حملات الآن',
        message: 'ستظهر هنا العروض والتعريف بالمنصة فور توفرها.',
        actionLabel: 'ابدأ البحث',
        onAction: widget.onExplore,
      );
    }
    return SizedBox(
      height: 168,
      child: PageView.builder(
        controller: controller,
        itemCount: widget.banners.length,
        onPageChanged: (value) => setState(() => index = value),
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.xs),
          child: _BannerCard(
            banner: widget.banners[i],
            onExplore: widget.onExplore,
          ),
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner, required this.onExplore});
  final AssalBannerSummary banner;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final hasImage = banner.imageUrl != null && banner.imageUrl!.startsWith('http');
    return Container(
      decoration: BoxDecoration(
        gradient: context.assalGradient,
        borderRadius: BorderRadius.circular(AssalRadius.extraLarge),
        border: Border.all(color: context.assalBorderStrong),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              banner.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => SizedBox.shrink(),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.bottomStart,
                end: AlignmentDirectional.topEnd,
                colors: [
                  context.assalBackground,
                  context.assalBackground.withValues(alpha: .55),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(AssalSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  banner.titleAr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AssalTypography.heading2
                      .copyWith(color: context.assalCream),
                ),
                SizedBox(height: AssalSpacing.xs),
                Text(
                  banner.descriptionAr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      AssalTypography.body.copyWith(color: context.assalTextSecondary),
                ),
                SizedBox(height: AssalSpacing.md),
                FilledButton(
                  onPressed: onExplore,
                  child: Text(banner.ctaLabelAr),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({required this.items, required this.onTap});
  final List<AssalTaxonomy> items;
  final ValueChanged<AssalTaxonomy> onTap;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(10).toList();
    if (visible.isEmpty) {
      return const AssalMessageCard(
        icon: Icons.category_outlined,
        message: 'لم تُحمّل الأقسام بعد.',
      );
    }
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(width: AssalSpacing.sm),
        itemBuilder: (context, index) {
          final item = visible[index];
          return InkWell(
            borderRadius: BorderRadius.circular(AssalRadius.medium),
            onTap: () => onTap(item),
            child: Container(
              width: 108,
              padding: EdgeInsets.all(AssalSpacing.sm),
              decoration: BoxDecoration(
                color: context.assalSurfaceVariant,
                borderRadius: BorderRadius.circular(AssalRadius.medium),
                border: Border.all(color: context.assalBorder),
              ),
              child: Column(
                children: [
                  Icon(_taxonomyIcon(item.nameAr), color: context.assalPrimaryLight),
                  SizedBox(height: AssalSpacing.xs),
                  Expanded(
                    child: Text(
                      item.nameAr,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AssalTypography.caption.copyWith(
                          color: context.assalTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductRail extends StatelessWidget {
  const _ProductRail({
    required this.repository,
    required this.title,
    required this.future,
    required this.onRetry,
    this.subtitle,
    this.verifiedOnly = false,
  });
  final AssalRepository repository;
  final String title;
  final String? subtitle;
  final Future<AssalLoadState<List<AssalProductSummary>>> future;
  final VoidCallback onRetry;
  final bool verifiedOnly;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HoneySectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: AssalSpacing.md),
          FutureBuilder<AssalLoadState<List<AssalProductSummary>>>(
            future: future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const AssalSkeletonList(count: 4);
              return AssalStateView<List<AssalProductSummary>>(
                state: snapshot.data!,
                onRetry: onRetry,
                builder: (products) => SizedBox(
                  height: 232,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: products.length > 8 ? 8 : products.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AssalSpacing.md),
                    itemBuilder: (_, index) => SizedBox(
                      width: 170,
                      child: ProductCard(
                        product: products[index],
                        showVerifiedBadge: verifiedOnly,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                                repository: repository,
                                productId: products[index].id))),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
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
          if (!snapshot.hasData) return const AssalSkeleton(count: 5);
          return AssalStateView<List<AssalCategorySummary>>(
            state: snapshot.data!,
            builder: (categories) => CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AssalSpacing.lg),
                  sliver: SliverToBoxAdapter(
                    child: HoneySectionHeader(
                      title: 'تصفح حسب القسم',
                      subtitle: 'التصنيف الرئيسي ثم التفاصيل ثم المنتجات',
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.lg),
                  sliver: SliverList.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AssalSpacing.md),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SearchScreen(
                                  repository: repository,
                                  initialCategoryId: category.id,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(AssalSpacing.lg),
                              child: Row(children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: context.assalHoneyLight,
                                    borderRadius: BorderRadius.circular(AssalRadius.medium),
                                    border: Border.all(color: context.assalBorderStrong),
                                  ),
                                  child: Icon(
                                    _taxonomyIcon(category.nameAr, category.productType),
                                    color: context.assalPrimaryLight,
                                  ),
                                ),
                                SizedBox(width: AssalSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(category.nameAr,
                                          style: AssalTypography.title
                                              .copyWith(color: context.assalTextPrimary)),
                                      SizedBox(height: AssalSpacing.xs),
                                      Text(
                                        '${category.productCount} منتج متاح',
                                        style: AssalTypography.bodySmall
                                            .copyWith(color: context.assalTextSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_left,
                                    color: context.assalTextMuted),
                              ]),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
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
  if (name.contains('سمر') || name.contains('طلح')) return Icons.eco_outlined;
  if (name.contains('خلط') || name.contains('مزيج')) return Icons.local_florist_outlined;
  if (name.contains('هد')) return Icons.card_giftcard_outlined;
  if (name.contains('خام')) return Icons.hive_outlined;
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
      locationReference?.governorateByCode(id)?.nameAr ?? 'المحافظة المحددة';

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
      sort: sort,
    );
    productsFuture = widget.repository.listProducts(query: query);
    storesFuture = widget.repository.listStores(regionId: regionId);
    popularSearchesFuture = widget.repository.listPopularSearches();
  }

  int get _activeFilterCount => [
        categoryId,
        subcategoryId,
        regionId,
        provinceId,
        gradeLevel,
        productType,
        originCountry,
        processingMethod,
        packaging,
        availability,
        minRating,
        minPrice,
        maxPrice,
      ].where((value) => value != null).length +
          (verifiedOnly ? 1 : 0);

  void _clearFilters() {
    setState(() {
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
    });
  }

  List<Widget> _activeFilterChips() => [
        if (categoryId != null)
          InfoChip(label: _categoryLabel(categoryId!)),
        if (subcategoryId != null)
          InfoChip(label: _subcategoryLabel(subcategoryId!)),
        if (regionId != null) InfoChip(label: _regionLabel(regionId!)),
        if (provinceId != null) InfoChip(label: _provinceLabel(provinceId!)),
        if (gradeLevel != null) InfoChip(label: 'درجة $gradeLevel'),
        if (productType != null)
          InfoChip(label: assalProductTypeLabel(productType!)),
        if (verifiedOnly) const InfoChip(label: 'موثقة'),
        if (minPrice != null || maxPrice != null)
          InfoChip(
              label:
                  '${minPrice?.toStringAsFixed(0) ?? '0'} – ${maxPrice?.toStringAsFixed(0) ?? '∞'}'),
      ];

  void _applySearch() {
    setState(_search);
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
              hintText: 'ابحث عن صنف أو منطقة أو متجر',
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
                _applySearch();
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
                  const HoneySectionHeader(title: 'المنتجات'),
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
                  const HoneySectionHeader(title: 'المتاجر'),
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
        final current = product.price!;
        dataMinPrice = dataMinPrice == null ? current : (dataMinPrice! < current ? dataMinPrice : current);
        dataMaxPrice = dataMaxPrice == null ? current : (dataMaxPrice! > current ? dataMaxPrice : current);
      }
    }
  }

  Future<void> _showFilters() async {
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
    final typeItems = <DropdownMenuItem<ProductType?>>[
      const DropdownMenuItem<ProductType?>(value: null, child: Text('كل الأنواع')),
      ...ProductType.values.map((type) => DropdownMenuItem<ProductType?>(
          value: type, child: Text(assalProductTypeLabel(type)))),
    ];
    final gradeItems = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(value: null, child: Text('كل الدرجات')),
      for (var level = 1; level <= 4; level++)
        DropdownMenuItem<int?>(value: level, child: Text('درجة $level')),
    ];
    final regionItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(value: '', child: Text('كل المحافظات')),
      ...(reference?.governorates ?? const <AssalRegion>[]).map(
        (region) => DropdownMenuItem<String>(
          value: region.code ?? region.id,
          child: Text(region.nameAr),
        ),
      ),
    ];
    final apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AssalSpacing.lg),
            child: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تصفية النتائج',
                          style: AssalTypography.heading2
                              .copyWith(color: context.assalTextPrimary)),
                      SizedBox(height: AssalSpacing.md),
                      DropdownButtonFormField<String>(
                          initialValue: draftRegion,
                          decoration:
                              InputDecoration(labelText: 'المحافظة'),
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
                          items: [
                            const DropdownMenuItem<String>(
                                value: '', child: Text('كل التصنيفات')),
                            ...filterTaxonomy
                                .where((item) =>
                                    draftCategory.isEmpty ||
                                    (item.metadata['category_id'] == draftCategory) ||
                                    _categoryCodeMatches(item, draftCategory))
                                .map((item) => DropdownMenuItem<String>(
                                    value: item.id, child: Text(item.nameAr))),
                          ],
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
                          items: [
                            const DropdownMenuItem<String>(
                                value: '', child: Text('جميع الأنواع')),
                            ...originOptions.map((item) =>
                                DropdownMenuItem<String>(
                                    value: item, child: Text(item))),
                          ],
                          onChanged: (value) =>
                              setModalState(() => draftOrigin = value ?? '')),
                      DropdownButtonFormField<String>(
                          initialValue: draftProcessing,
                          decoration: const InputDecoration(
                              labelText: 'طريقة المعالجة'),
                          items: [
                            const DropdownMenuItem<String>(
                                value: '', child: Text('جميع الطرق')),
                            ...processingOptions.map((item) =>
                                DropdownMenuItem<String>(
                                    value: item, child: Text(item))),
                          ],
                          onChanged: (value) => setModalState(
                              () => draftProcessing = value ?? '')),
                      DropdownButtonFormField<String>(
                          initialValue: draftPackaging,
                          decoration:
                              const InputDecoration(labelText: 'التعبئة'),
                          items: [
                            const DropdownMenuItem<String>(
                                value: '', child: Text('جميع الأنواع')),
                            ...packagingOptions.map((item) =>
                                DropdownMenuItem<String>(
                                    value: item, child: Text(item))),
                          ],
                          onChanged: (value) => setModalState(
                              () => draftPackaging = value ?? '')),
                      DropdownButtonFormField<String>(
                          initialValue: draftAvailability,
                          decoration:
                              const InputDecoration(labelText: 'التوفر'),
                          items: [
                            DropdownMenuItem<String>(
                                value: '', child: Text('جميع الحالات')),
                            ...availabilityOptions.map((item) =>
                                DropdownMenuItem<String>(
                                    value: item, child: Text(item))),
                          ],
                          onChanged: (value) => setModalState(
                              () => draftAvailability = value ?? '')),
                      Text(
                          'نطاق السعر: ${draftPriceRange.start.toStringAsFixed(0)} – ${draftPriceRange.end.toStringAsFixed(0)} ريال',
                          style: AssalTypography.bodyLarge
                              .copyWith(color: context.assalTextSecondary)),
                      RangeSlider(
                        activeColor: context.assalPrimary,
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
                              .copyWith(color: context.assalTextSecondary)),
                      Slider(
                        min: 0,
                        max: dataMaxRating,
                        activeColor: context.assalPrimary,
                        divisions: 10,
                        value: draftMinRatingValue,
                        label: draftMinRatingValue.toStringAsFixed(1),
                        onChanged: (value) =>
                            setModalState(() => draftMinRatingValue = value),
                      ),
                      SizedBox(height: AssalSpacing.md),
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
          ),
        ),
      ),
    );
    if (apply == true) _applySearch();
  }

  bool _categoryCodeMatches(AssalTaxonomy item, String categoryId) {
    final metadata = item.metadata;
    final candidateValues = <Object?>[
      metadata['category_id'],
      metadata['categoryId'],
      metadata['parent_id'],
      metadata['parentId'],
    ];
    return candidateValues.contains(categoryId);
  }
}

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
  final Map<String, String> regionNames = <String, String>{};
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
      final reference = await YemenLocationReference.load();
      for (final governorate in reference.governorates) {
        final id = governorate.code ?? governorate.id;
        regionNames[id] = governorate.nameAr;
      }
      return reference;
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
      final matchesRegion = regionId == null ||
          store.regionId == regionId ||
          _regionMatches(store.regionNameAr, regionId!);
      final matchesVerified = !verifiedOnly || store.isVerified;
      return matchesQuery && matchesRegion && matchesVerified;
    }).toList(growable: false);
  }

  bool _regionMatches(String? regionName, String requested) {
    if (regionName == null) return false;
    final label = regionNames[requested] ?? requested;
    return regionName.toLowerCase().contains(label.toLowerCase()) ||
        regionName.toLowerCase().contains(requested.toLowerCase());
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
                if (!snapshot.hasData) return const AssalSkeletonList(count: 3);
                final state = snapshot.data!;
                if (state is AssalData<List<AssalStoreSummary>>) {
                  final stores = _filtered(state.value);
                  if (stores.isEmpty) {
                    return const AssalMessageCard(
                      icon: Icons.store_mall_directory_outlined,
                      title: 'لا توجد متاجر',
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
