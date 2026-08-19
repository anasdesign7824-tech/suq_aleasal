import 'package:flutter/material.dart';
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
  const ProductDetailScreen(
      {super.key, required this.repository, required this.productId});
  final AssalRepository repository;
  final String productId;
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<AssalLoadState<AssalProductSummary>> productFuture;
  final Map<String, Future<AssalLoadState<AssalStoreSummary>>> storeFutures =
      <String, Future<AssalLoadState<AssalStoreSummary>>>{};
  late final PageController galleryController;
  bool liked = false;
  bool favorite = false;
  int galleryIndex = 0;
  @override
  void initState() {
    super.initState();
    productFuture = widget.repository.getProduct(widget.productId);
    galleryController = PageController();
    _trackProductView();
  }

  Future<void> _trackProductView() async {
    await widget.repository.trackProductView(widget.productId);
  }

  @override
  void dispose() {
    galleryController.dispose();
    super.dispose();
  }

  Future<AssalLoadState<AssalStoreSummary>> _storeFuture(String storeId) =>
      storeFutures.putIfAbsent(
          storeId, () => widget.repository.getStore(storeId));
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
              return const AssalMessageCard(
                  icon: Icons.wifi_off_outlined,
                  message:
                      'تعذر تحميل البيانات الآن. تحقق من الاتصال ثم أعد المحاولة.');
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
            child: Column(
              children: [
                _productHero(product, gallery),
                const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'معلومات المنتج'),
                    Tab(text: 'التقييمات والتفاعل'),
                    Tab(text: 'منتجات مشابهة'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _productInfoTab(product, store),
                      _productInteractionTab(product),
                      _similarProductsTab(product),
                    ],
                  ),
                ),
                if (store != null)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AssalSpacing.lg,
                          AssalSpacing.sm, AssalSpacing.lg, AssalSpacing.sm),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _request(product, store),
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('إرسال طلب تواصل'),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );

  Widget _productHero(AssalProductSummary product, List<String?> gallery) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(
            AssalSpacing.lg, AssalSpacing.lg, AssalSpacing.lg, 0),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: galleryController,
                itemCount: gallery.length,
                onPageChanged: (index) => setState(() => galleryIndex = index),
                itemBuilder: (_, index) => AssalImageTile(
                  imageUrl: gallery[index],
                  height: 220,
                  icon: index.isEven
                      ? Icons.wb_sunny_outlined
                      : Icons.hive_outlined,
                ),
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
              ],
            ),
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
            _MetadataCard(product: product),
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
                  subtitle: Text(store.isVerified
                      ? 'متجر موثق · ${store.regionNameAr ?? ''}'
                      : 'متجر على منصة عسلكم'),
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
                    onPressed: () async {
                      final session =
                          await requireUserSession(context, widget.repository);
                      if (session == null || !mounted || session.user == null) {
                        return;
                      }
                      final result = await widget.repository
                          .toggleLike(session.user!.id, product.id);
                      if (result is AssalData<bool>) {
                        setState(() => liked = result.value);
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
                    onPressed: () async {
                      final session =
                          await requireUserSession(context, widget.repository);
                      if (session == null || !mounted || session.user == null) {
                        return;
                      }
                      final result = await widget.repository
                          .toggleFavorite(session.user!.id, product.id);
                      if (result is AssalData<bool>) {
                        setState(() => favorite = result.value);
                      }
                    },
                    icon:
                        Icon(favorite ? Icons.bookmark : Icons.bookmark_border),
                    label: Text(favorite ? 'محفوظ' : 'حفظ'),
                  ),
                ),
              ],
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
      return const AssalMessageCard(
          icon: Icons.category_outlined,
          message: 'لا تتوفر منتجات مشابهة لهذا التصنيف بعد.');
    }
    return FutureBuilder<AssalLoadState<List<AssalProductSummary>>>(
      future: widget.repository.listProducts(
        query: AssalProductQuery(subcategoryId: product.taxonomyId),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const AssalMessageCard(
              icon: Icons.wifi_off_outlined,
              message:
                  'تعذر تحميل المنتجات المشابهة الآن. تحقق من الاتصال ثم أعد المحاولة.');
        }
        if (!snapshot.hasData) return const AssalGlassLoading();
        return Padding(
          padding: const EdgeInsets.all(AssalSpacing.lg),
          child: AssalStateView<List<AssalProductSummary>>(
            state: snapshot.data!,
            builder: (items) {
              final similar =
                  items.where((item) => item.id != product.id).toList();
              return similar.isEmpty
                  ? const AssalMessageCard(
                      icon: Icons.inventory_2_outlined,
                      message: 'لا توجد منتجات مشابهة منشورة بعد.')
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        crossAxisSpacing: AssalSpacing.md,
                        mainAxisSpacing: AssalSpacing.md,
                        childAspectRatio: .68,
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
          ),
        );
      },
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

  void _share() => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تجهيز رابط المشاركة في Demo Mode')));
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.product});
  final AssalProductSummary product;

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
            _row('المنطقة', product.regionNameAr ?? 'غير محددة'),
            if (product.provinceNameAr != null)
              _row('المحافظة', product.provinceNameAr!),
            if (product.originCountry != null)
              _row('بلد الأصل', product.originCountry!),
            _row('التصنيف', product.subcategoryNameAr ?? 'غير محدد'),
            if (product.qualityLabelAr != null)
              _row('الجودة', product.qualityLabelAr!),
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
            _row('التوفر', product.availability),
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

  @override
  void initState() {
    super.initState();
    storeFuture = widget.repository.getStore(widget.storeId);
    productsFuture = widget.repository
        .listProducts(query: AssalProductQuery(storeId: widget.storeId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AssalAppBar(title: 'صفحة المتجر'),
      body: FutureBuilder<AssalLoadState<AssalStoreSummary>>(
        future: storeFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const AssalMessageCard(
                icon: Icons.wifi_off_outlined,
                message:
                    'تعذر تحميل البيانات الآن. تحقق من الاتصال ثم أعد المحاولة.');
          }
          if (!snapshot.hasData) return const AssalGlassLoading();
          return AssalStateView<AssalStoreSummary>(
              state: snapshot.data!, builder: _content);
        },
      ),
    );
  }

  Widget _content(AssalStoreSummary store) => DefaultTabController(
        length: 3,
        child: Column(
          children: [
            _storeHeader(store),
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'المنتجات'),
                Tab(text: 'معلومات المتجر'),
                Tab(text: 'التواصل والطلب'),
              ],
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
    final logoUrl = store.logoUrl ?? store.avatarUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AssalSpacing.lg, AssalSpacing.lg, AssalSpacing.lg, 0),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: AssalImageTile(
                    imageUrl: store.coverUrl,
                    height: 180,
                    icon: Icons.hive_outlined,
                  ),
                ),
                Positioned(
                  bottom: -28,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: AssalColors.honeyLight,
                      backgroundImage:
                          logoUrl != null && logoUrl.startsWith('http')
                              ? NetworkImage(logoUrl)
                              : null,
                      child: logoUrl == null || !logoUrl.startsWith('http')
                          ? const Icon(Icons.storefront_outlined,
                              size: 34, color: AssalColors.primaryDark)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 38),
          Text(
            store.nameAr,
            textAlign: TextAlign.center,
            style:
                AssalTypography.heading1.copyWith(color: AssalColors.deepBrown),
          ),
          const SizedBox(height: AssalSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (store.isVerified)
                const Icon(Icons.verified,
                    size: 18, color: AssalColors.primaryDark),
              const SizedBox(width: 4),
              Text(
                store.isVerified ? 'متجر موثق' : 'متجر في طور التعريف',
                style: AssalTypography.body
                    .copyWith(color: AssalColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AssalSpacing.md),
          Text(
            store.description ?? 'متجر متخصص في المنتجات النحلية اليمنية.',
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AssalTypography.bodyLarge
                .copyWith(color: AssalColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _productsTab(AssalStoreSummary store) =>
      FutureBuilder<AssalLoadState<List<AssalProductSummary>>>(
        future: productsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const AssalMessageCard(
                icon: Icons.wifi_off_outlined,
                message:
                    'تعذر تحميل البيانات الآن. تحقق من الاتصال ثم أعد المحاولة.');
          }
          if (!snapshot.hasData) return const AssalGlassLoading();
          return Padding(
            padding: const EdgeInsets.all(AssalSpacing.lg),
            child: AssalStateView<List<AssalProductSummary>>(
              state: snapshot.data!,
              builder: (products) => products.isEmpty
                  ? const AssalMessageCard(
                      icon: Icons.inventory_2_outlined,
                      message: 'لا توجد منتجات منشورة في هذا المتجر بعد.')
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        crossAxisSpacing: AssalSpacing.md,
                        mainAxisSpacing: AssalSpacing.md,
                        childAspectRatio: .68,
                      ),
                      itemCount: products.length,
                      itemBuilder: (_, index) {
                        final product = products[index];
                        return ProductCard(
                          product: product,
                          showVerifiedBadge: store.isVerified,
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
            ),
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
            const SizedBox(height: AssalSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stat('${store.followersCount}', 'متابع'),
                _stat('${store.reviewCount}', 'مراجعة'),
                _stat('${store.yearsExperience}', 'سنوات خبرة'),
              ],
            ),
            const SizedBox(height: AssalSpacing.xl),
            const SectionHeader(title: 'الموقع والتخصصات'),
            if (store.regionNameAr != null)
              _storeInfoRow(
                  Icons.location_on_outlined, 'المنطقة', store.regionNameAr!),
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
          ],
        ),
      );

  Widget _contactTab(AssalStoreSummary store) => SingleChildScrollView(
        padding: const EdgeInsets.all(AssalSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'التواصل والطلب'),
            if (store.socialLinks.isEmpty &&
                store.contactPhone == null &&
                store.contactWhatsapp == null &&
                store.contactTelegram == null)
              const AssalMessageCard(
                icon: Icons.forum_outlined,
                message: 'لم يضف المتجر قنوات تواصل بعد.',
              )
            else ...[
              if (store.contactPhone != null)
                ActionChip(
                  avatar: const Icon(Icons.phone_outlined, size: 16),
                  label: const Text('الهاتف'),
                  onPressed: () => _showContact('phone', store.contactPhone!),
                ),
              if (store.contactWhatsapp != null)
                ActionChip(
                  avatar: const Icon(Icons.chat_outlined, size: 16),
                  label: const Text('واتساب'),
                  onPressed: () =>
                      _showContact('whatsapp', store.contactWhatsapp!),
                ),
              if (store.contactTelegram != null)
                ActionChip(
                  avatar: const Icon(Icons.send_outlined, size: 16),
                  label: const Text('تلغرام'),
                  onPressed: () =>
                      _showContact('telegram', store.contactTelegram!),
                ),
              Wrap(
                spacing: AssalSpacing.sm,
                runSpacing: AssalSpacing.sm,
                children: store.socialLinks.entries
                    .map((entry) => ActionChip(
                          avatar: const Icon(Icons.link, size: 16),
                          label: Text(_socialLabel(entry.key)),
                          onPressed: () => _showContact(entry.key, entry.value),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: AssalSpacing.lg),
            if (store.deliveryOptions.isNotEmpty)
              _storeInfoRow(Icons.local_shipping_outlined, 'التوصيل',
                  store.deliveryOptions.join('، ')),
            if (store.pickupLocations.isNotEmpty)
              _storeInfoRow(Icons.location_on_outlined, 'الاستلام',
                  store.pickupLocations.join('، ')),
            const SizedBox(height: AssalSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      final session =
                          await requireUserSession(context, widget.repository);
                      if (session == null || !mounted || session.user == null) {
                        return;
                      }
                      final result = await widget.repository
                          .toggleFollow(session.user!.id, store.id);
                      if (result is AssalData<bool>) {
                        setState(() => following = result.value);
                      }
                    },
                    icon:
                        Icon(following ? Icons.check : Icons.person_add_alt_1),
                    label: Text(following ? 'تتابعه' : 'متابعة'),
                  ),
                ),
                const SizedBox(width: AssalSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final session =
                          await requireUserSession(context, widget.repository);
                      if (session == null || !mounted || session.user == null) {
                        return;
                      }
                      final result = await widget.repository
                          .createConversation(session.user!.id, store.id);
                      if (!mounted ||
                          result is! AssalData<AssalConversationSummary>) {
                        return;
                      }
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ConversationScreen(
                              repository: widget.repository,
                              conversation: result.value)));
                    },
                    icon: const Icon(Icons.forum_outlined),
                    label: const Text('مراسلة'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  void _showContact(String channel, String value) => showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
              title: Text('بيانات ${_socialLabel(channel)}'),
              content: SelectableText(value),
              actions: [
                FilledButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('إغلاق'))
              ]));

  Widget _storeInfoRow(IconData icon, String label, String value) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AssalColors.primaryDark),
      title: Text(label),
      subtitle: Text(value));

  Widget _stat(String value, String label) => Column(children: [
        Text(value,
            style: AssalTypography.heading3
                .copyWith(color: AssalColors.deepBrown)),
        Text(label,
            style:
                AssalTypography.caption.copyWith(color: AssalColors.textMuted))
      ]);
}

String _socialLabel(String key) => switch (key) {
      'whatsapp' => 'واتساب',
      'instagram' => 'إنستغرام',
      'telegram' => 'تلغرام',
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
  final deliveryNoteController = TextEditingController();
  int quantity = 1;
  HandoffOption option = HandoffOption.contact;
  bool saving = false;

  @override
  void dispose() {
    bodyController.dispose();
    phoneController.dispose();
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
              Text('طلب تواصل مع ${widget.store.nameAr}',
                  style: AssalTypography.heading2
                      .copyWith(color: AssalColors.deepBrown)),
              const SizedBox(height: AssalSpacing.sm),
              Text(widget.product.nameAr, style: AssalTypography.subtitle),
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
                  controller: deliveryNoteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'ملاحظات التسليم (اختياري)',
                      hintText: 'مثال: التواصل قبل الوصول')),
              const SizedBox(height: AssalSpacing.md),
              DropdownButtonFormField<HandoffOption>(
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
              SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      onPressed: saving ? null : _submit,
                      child: saving
                          ? const AssalGlassLoading(
                              height: 44, label: 'جارٍ الإرسال...')
                          : const Text('حفظ وإرسال الطلب'))),
            ]),
      ),
    );
  }

  Future<void> _submit() async {
    final body = bodyController.text.trim();
    if (body.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اكتب رسالة أوضح للتاجر.')));
      return;
    }
    setState(() => saving = true);
    final result = await widget.repository.createRequest(
        'demo-customer',
        AssalRequestDraft(
            storeId: widget.store.id,
            productId: widget.product.id,
            subject: 'استفسار عن ${widget.product.nameAr}',
            body: body,
            quantity: quantity,
            phone: phoneController.text.trim().isEmpty
                ? null
                : phoneController.text.trim(),
            handoffOption: option,
            deliveryNote: deliveryNoteController.text.trim().isEmpty
                ? null
                : deliveryNoteController.text.trim(),
            handoffDetails: {
              'quantity_label': '$quantity',
              'source': 'customer_request'
            }));
    if (!mounted) return;
    setState(() => saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result is AssalData<AssalRequestSummary>
            ? 'تم حفظ الطلب ويمكنك متابعته من ملفك.'
            : 'تعذر حفظ الطلب، حاول مرة أخرى.')));
  }
}
