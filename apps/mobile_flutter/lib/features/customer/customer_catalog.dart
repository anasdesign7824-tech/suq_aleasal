import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_design/assal_tokens.dart';
import '../../core/assal_widgets.dart';
import 'customer_core.dart';
import 'customer_social.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.repository,
    required this.productId,
    this.initialProduct,
  });
  final AssalRepository repository;
  final String productId;
  final AssalProductSummary? initialProduct;
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
    productFuture = widget.initialProduct != null
        ? Future.value(AssalData(widget.initialProduct!))
        : widget.repository.getProduct(widget.productId);
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
            if (!snapshot.hasData) return const AssalSkeletonList(count: 5);
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
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _productHero(product, gallery)),
              SliverPadding(
                padding: const EdgeInsets.all(AssalSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _productActions(product),
                    const SizedBox(height: AssalSpacing.md),
                    _productIdentity(product),
                    const SizedBox(height: AssalSpacing.lg),
                    _metadataSection(product),
                    if (store != null) ...[
                      const SizedBox(height: AssalSpacing.lg),
                      _storePreview(store),
                    ],
                    const SizedBox(height: AssalSpacing.lg),
                    _requestCard(product, store),
                    const SizedBox(height: AssalSpacing.xl),
                    HoneySectionHeader(
                      title: 'التقييمات والتفاعل',
                      subtitle: 'آراء موثوقة من مجتمع عسلكم',
                    ),
                    const SizedBox(height: AssalSpacing.md),
                    ReviewsSection(repository: widget.repository, product: product),
                    const SizedBox(height: AssalSpacing.xl),
                    const HoneySectionHeader(title: 'التعليقات'),
                    const SizedBox(height: AssalSpacing.md),
                    CommentsSection(
                        repository: widget.repository, targetId: product.id),
                    const SizedBox(height: AssalSpacing.xl),
                    const HoneySectionHeader(
                      title: 'منتجات مشابهة',
                      subtitle: 'من نفس التصنيف',
                    ),
                    const SizedBox(height: AssalSpacing.md),
                    _similarProducts(product),
                  ]),
                ),
              ),
            ],
          );
        },
      );

  Widget _productHero(AssalProductSummary product, List<String?> gallery) {
    final width = MediaQuery.sizeOf(context).width;
    return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AssalSpacing.lg, AssalSpacing.lg, AssalSpacing.lg, 0),
            child: SizedBox(
              height: width,
              width: width,
              child: PageView.builder(
                controller: galleryController,
                itemCount: gallery.length,
                onPageChanged: (index) => setState(() => galleryIndex = index),
                itemBuilder: (_, index) => AssalImageTile(
                  imageUrl: gallery[index],
                  height: width,
                  icon: index.isEven
                      ? Icons.wb_sunny_outlined
                      : Icons.hive_outlined,
                ),
              ),
            ),
          ),
          SizedBox(height: AssalSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              gallery.length,
              (index) => AnimatedContainer(
                duration: Duration(milliseconds: 180),
                width: index == galleryIndex ? 22 : 8,
                height: 8,
                margin: EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index == galleryIndex
                      ? context.assalPrimary
                      : context.assalBorder,
                  borderRadius: BorderRadius.circular(AssalRadius.pill),
                ),
              ),
            ),
          ),
        ],
      );
  }

  Widget _productActions(AssalProductSummary product) => Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final session =
                  await requireUserSession(context, widget.repository);
              if (session == null || !mounted || session.user == null) return;
              final result = await widget.repository
                  .toggleLike(session.user!.id, product.id);
              if (result is AssalData<bool>) setState(() => liked = result.value);
            },
            icon: Icon(liked ? Icons.thumb_up : Icons.thumb_up_outlined),
            label: Text(liked ? 'أعجبتني' : 'إعجاب'),
          ),
        ),
        const SizedBox(width: AssalSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final session =
                  await requireUserSession(context, widget.repository);
              if (session == null || !mounted || session.user == null) return;
              final result = await widget.repository
                  .toggleFavorite(session.user!.id, product.id);
              if (result is AssalData<bool>) setState(() => favorite = result.value);
            },
            icon: Icon(favorite ? Icons.bookmark : Icons.bookmark_border),
            label: Text(favorite ? 'محفوظ' : 'حفظ'),
          ),
        ),
      ]);

  Widget _productIdentity(AssalProductSummary product) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.nameAr,
            style: AssalTypography.heading1
                .copyWith(color: context.assalTextPrimary),
          ),
          SizedBox(height: AssalSpacing.sm),
          Wrap(
            spacing: AssalSpacing.sm,
            runSpacing: AssalSpacing.sm,
            children: [
              InfoChip(label: assalProductTypeLabel(product.productType)),
              if (product.subcategoryNameAr != null)
                InfoChip(label: product.subcategoryNameAr!),
              if (product.regionNameAr != null)
                InfoChip(label: product.regionNameAr!),
            ],
          ),
          SizedBox(height: AssalSpacing.md),
          Row(
            children: [
              Icon(Icons.star, size: 18, color: context.assalPrimaryLight),
              SizedBox(width: AssalSpacing.xs),
              Text(product.ratingAverage.toStringAsFixed(1)),
              SizedBox(width: AssalSpacing.sm),
              Text('${product.reviewCount} مراجعة',
                  style: AssalTypography.caption
                      .copyWith(color: context.assalTextMuted)),
              Spacer(),
              Text(
                formatAssalPrice(product.price, product.currencyCode),
                style: AssalTypography.title
                    .copyWith(color: context.assalPrimaryLight),
              ),
            ],
          ),
        ],
      );

  Widget _metadataSection(AssalProductSummary product) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HoneySectionHeader(
            title: 'بيانات المصدر والجودة',
            subtitle: 'كل معلومة من السجل المعتمد',
          ),
          const SizedBox(height: AssalSpacing.md),
          _MetadataCard(product: product),
        ],
      );

  Widget _storePreview(AssalStoreSummary store) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StoreProfileScreen(
                  repository: widget.repository, storeId: store.id),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(AssalSpacing.lg),
            child: Row(children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: context.assalSurfaceVariant,
                backgroundImage: (store.logoUrl ?? store.avatarUrl) != null &&
                        (store.logoUrl ?? store.avatarUrl)!.startsWith('http')
                    ? NetworkImage((store.logoUrl ?? store.avatarUrl)!)
                    : null,
                child: (store.logoUrl ?? store.avatarUrl) == null
                    ? Icon(Icons.storefront_outlined,
                        color: context.assalPrimaryLight)
                    : null,
              ),
              SizedBox(width: AssalSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.nameAr,
                        style: AssalTypography.title
                            .copyWith(color: context.assalTextPrimary)),
                    SizedBox(height: AssalSpacing.xs),
                    Text(
                      store.isVerified
                          ? 'متجر موثق · ${store.regionNameAr ?? ''}'
                          : 'متجر على منصة عسلكم',
                      style: AssalTypography.bodySmall
                          .copyWith(color: context.assalTextSecondary),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StoreProfileScreen(
                        repository: widget.repository, storeId: store.id),
                  ),
                ),
                child: Text('فتح المتجر'),
              ),
            ]),
          ),
        ),
      );

  Widget _requestCard(
      AssalProductSummary product, AssalStoreSummary? store) {
    if (store == null) return SizedBox.shrink();
    return Card(
      color: context.assalSurfaceVariant,
      child: Padding(
        padding: EdgeInsets.all(AssalSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('جاهز للاستفسار والطلب',
                style: AssalTypography.heading3
                    .copyWith(color: context.assalTextPrimary)),
            SizedBox(height: AssalSpacing.xs),
            Text(
              'حدد التفاصيل و أرسل طلب تواصل مباشرًا إلى المتجر.',
              style: AssalTypography.body
                  .copyWith(color: context.assalTextSecondary),
            ),
            SizedBox(height: AssalSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _request(product, store),
                icon: Icon(Icons.chat_bubble_outline),
                label: const Text('إرسال طلب تواصل'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _similarProducts(AssalProductSummary product) {
    if (product.taxonomyId == null) {
      return const AssalMessageCard(
          icon: Icons.category_outlined,
          title: 'لا يوجد تصنيف',
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
        if (!snapshot.hasData) return const AssalSkeletonList(count: 3);
        return AssalStateView<List<AssalProductSummary>>(
          state: snapshot.data!,
          builder: (items) {
            final similar = items.where((item) => item.id != product.id).toList();
            return similar.isEmpty
                ? const AssalMessageCard(
                    icon: Icons.inventory_2_outlined,
                    message: 'لا توجد منتجات مشابهة منشورة بعد.')
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
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

  Future<void> _share() async {
    final text = 'منتج من سوق عسلكم\\nمعرّف المنتج: ${widget.productId}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ بطاقة المنتج للمشاركة.')),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.product});
  final AssalProductSummary product;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AssalSpacing.lg),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _row(context, 'نوع المنتج', assalProductTypeLabel(product.productType)),
            if (product.honeyIdentity != null)
              _row(context, 'هوية العسل', product.honeyIdentity!),
            _row(context, 'المنطقة', product.regionNameAr ?? 'غير محددة'),
            if (product.provinceNameAr != null)
              _row(context, 'المحافظة', product.provinceNameAr!),
            if (product.originCountry != null)
              _row(context, 'بلد الأصل', product.originCountry!),
            _row(context, 'التصنيف', product.subcategoryNameAr ?? 'غير محدد'),
            if (product.qualityLabelAr != null)
              _row(context, 'الجودة', product.qualityLabelAr!),
            if (product.processingMethodAr != null)
              _row(context, 'المعالجة', product.processingMethodAr!),
            if (product.processingStatusAr != null)
              _row(context, 'حالة المعالجة', product.processingStatusAr!),
            if (product.packagingLabelAr != null)
              _row(context, 'التعبئة', product.packagingLabelAr!),
            if (product.productionDate != null)
              _row(context, 'تاريخ الإنتاج', _dateLabel(product.productionDate)),
            if (product.packagedDate != null)
              _row(context, 'تاريخ التعبئة', _dateLabel(product.packagedDate)),
            if (product.shelfLifeLabelAr != null)
              _row(context, 'الصلاحية', product.shelfLifeLabelAr!),
            _row(context, 'التوفر', product.availability),
            if (product.weightLabel != null)
              _row(context, 'الوزن', product.weightLabel!),
            if (product.harvestLabel != null)
              _row(context, 'القطفة', product.harvestLabel!),
            if (product.deliveryOptions.isNotEmpty)
              _row(context, 'التسليم', product.deliveryOptions.join('، ')),
            if (product.pickupLocations.isNotEmpty)
              _row(context, 'الاستلام', product.pickupLocations.join('، ')),
          ]),
        ),
      );

  Widget _row(BuildContext context, String label, String value) => Padding(
      padding: EdgeInsets.symmetric(vertical: AssalSpacing.xs),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 96,
            child: Text(label,
                style: AssalTypography.bodySmall
                    .copyWith(color: context.assalTextMuted))),
        Expanded(
            child: Text(value,
                style: AssalTypography.body
                    .copyWith(color: context.assalTextPrimary)))
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
          if (!snapshot.hasData) return const AssalSkeletonList(count: 5);
          return AssalStateView<AssalStoreSummary>(
              state: snapshot.data!, builder: _content);
        },
      ),
    );
  }

  Widget _content(AssalStoreSummary store) => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _storeHeader(store)),
          SliverPadding(
            padding: const EdgeInsets.all(AssalSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                HoneySectionHeader(title: 'منتجات المتجر'),
                const SizedBox(height: AssalSpacing.md),
                _productsTab(store),
                const SizedBox(height: AssalSpacing.xl),
                _storeInfoTab(store),
                const SizedBox(height: AssalSpacing.xl),
                _contactTab(store),
              ]),
            ),
          ),
        ],
      );

  Widget _storeHeader(AssalStoreSummary store) {
    final logoUrl = store.logoUrl ?? store.avatarUrl;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
              AssalSpacing.lg, AssalSpacing.lg, AssalSpacing.lg, 0),
          child: AspectRatio(
            aspectRatio: 1.6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AssalRadius.extraLarge),
              child: Container(
                color: context.assalSurfaceVariant,
                child: AssalImageTile(
                  imageUrl: store.coverUrl,
                  height: 180,
                  icon: Icons.hive_outlined,
                ),
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(0, -40),
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: context.assalSurfaceRaised,
                backgroundImage:
                    logoUrl != null && logoUrl.startsWith('http')
                        ? NetworkImage(logoUrl)
                        : null,
                child: logoUrl == null || !logoUrl.startsWith('http')
                    ? Icon(Icons.storefront_outlined,
                        size: 36, color: context.assalPrimaryLight)
                    : null,
              ),
              SizedBox(height: AssalSpacing.sm),
              Text(
                store.nameAr,
                textAlign: TextAlign.center,
                style:
                    AssalTypography.heading1.copyWith(color: context.assalTextPrimary),
              ),
              SizedBox(height: AssalSpacing.sm),
              Wrap(
                spacing: AssalSpacing.sm,
                children: [
                  InfoChip(
                    label: store.isVerified
                        ? 'موثق Pro'
                        : store.status == StoreStatus.active
                            ? 'متجر مفعّل'
                            : 'المتجر قيد التفعيل',
                    icon: store.isVerified
                        ? Icons.verified
                        : store.status == StoreStatus.active
                            ? Icons.storefront_outlined
                            : Icons.hourglass_empty_outlined,
                  ),
                  if (store.regionNameAr != null)
                    InfoChip(
                        label: store.regionNameAr!,
                        icon: Icons.location_on_outlined),
                ],
              ),
              if (store.description != null) ...[
                SizedBox(height: AssalSpacing.md),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: AssalSpacing.lg),
                  child: Text(
                    store.description!,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AssalTypography.bodyLarge
                        .copyWith(color: context.assalTextSecondary),
                  ),
                ),
              ],
              SizedBox(height: AssalSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _stat('${store.followersCount}', 'متابع'),
                  _stat('${store.reviewCount}', 'مراجعة'),
                  _stat(store.ratingAverage.toStringAsFixed(1), 'التقييم'),
                ],
              ),
            ],
          ),
        ),
      ],
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
          if (!snapshot.hasData) return const AssalSkeletonList(count: 3);
          return AssalStateView<List<AssalProductSummary>>(
            state: snapshot.data!,
            builder: (products) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
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
          );
        },
      );

  Widget _storeInfoTab(AssalStoreSummary store) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HoneySectionHeader(title: 'عن المتجر'),
          const SizedBox(height: AssalSpacing.sm),
          Text(
            store.bio ?? store.description ?? 'لم يضف المتجر نبذة تعريفية بعد.',
            style: AssalTypography.bodyLarge,
          ),
          const SizedBox(height: AssalSpacing.xl),
          const HoneySectionHeader(title: 'الموقع والتخصصات'),
          const SizedBox(height: AssalSpacing.sm),
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
            const HoneySectionHeader(title: 'التوثيقات'),
            const SizedBox(height: AssalSpacing.sm),
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
      );

  Widget _contactTab(AssalStoreSummary store) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HoneySectionHeader(title: 'التواصل والطلب'),
          const SizedBox(height: AssalSpacing.sm),
          if (store.socialLinks.isEmpty &&
              store.contactPhone == null &&
              store.contactWhatsapp == null &&
              store.contactTelegram == null)
            const AssalMessageCard(
              icon: Icons.forum_outlined,
              message: 'لم يضف المتجر قنوات تواصل بعد.',
            )
          else ...[
            Wrap(
              spacing: AssalSpacing.sm,
              runSpacing: AssalSpacing.sm,
              children: [
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
                ...store.socialLinks.entries.map(
                  (entry) => ActionChip(
                    avatar: const Icon(Icons.link, size: 16),
                    label: Text(_socialLabel(entry.key)),
                    onPressed: () => _showContact(entry.key, entry.value),
                  ),
                ),
              ],
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
                  icon: Icon(following ? Icons.check : Icons.person_add_alt_1),
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
                  icon: Icon(Icons.forum_outlined),
                  label: Text('مراسلة'),
                ),
              ),
            ],
          ),
        ],
      );

  void _showContact(String channel, String value) => showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
              backgroundColor: context.assalSurfaceRaised,
              title: Text('بيانات ${_socialLabel(channel)}'),
              content: SelectableText(value),
              actions: [
                FilledButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text('إغلاق'))
              ]));

  Widget _storeInfoRow(IconData icon, String label, String value) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: context.assalPrimaryLight),
      title: Text(label),
      subtitle: Text(value));

  Widget _stat(String value, String label) => Column(children: [
        Text(value,
            style: AssalTypography.heading3
                .copyWith(color: context.assalTextPrimary)),
        Text(label,
            style: AssalTypography.caption.copyWith(color: context.assalTextMuted))
      ]);
}

String _socialLabel(String key) => switch (key) {
      'whatsapp' => 'واتساب',
      'instagram' => 'إنستغرام',
      'telegram' => 'تلغرام',
      _ => key,
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

  Future<void> _submit() async {
    if (saving) return;
    if (bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اكتب رسالة الطلب أولًا.')));
      return;
    }
    final session = await widget.repository.getSession();
    if (!session.isAuthenticated || session.user == null) return;
    setState(() => saving = true);
    final result = await widget.repository.createRequest(
      session.user!.id,
      AssalRequestDraft(
        storeId: widget.store.id,
        productId: widget.product.id,
        subject: 'طلب تواصل: ${widget.product.nameAr}',
        body: bodyController.text.trim(),
        quantity: quantity,
        phone: phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        handoffOption: option,
        deliveryNote: deliveryNoteController.text.trim().isEmpty
            ? null
            : deliveryNoteController.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => saving = false);
    if (result is AssalData<AssalRequestSummary>) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال طلب التواصل إلى المتجر.')));
      Navigator.of(context).pop();
    } else if (result is AssalError<AssalRequestSummary>) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.messageAr)));
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AssalSpacing.lg),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('طلب تواصل',
                    style: AssalTypography.heading2
                        .copyWith(color: context.assalTextPrimary)),
                SizedBox(height: AssalSpacing.xs),
                Text(
                  widget.product.nameAr,
                  style: AssalTypography.body
                      .copyWith(color: context.assalTextSecondary),
                ),
                SizedBox(height: AssalSpacing.lg),
                Row(children: [
                  Expanded(
                    child: _quantityCard(
                      Icons.remove_rounded,
                      () => setState(() {
                        if (quantity > 1) quantity--;
                      }),
                    ),
                  ),
                  const SizedBox(width: AssalSpacing.sm),
                  SizedBox(
                      width: 56,
                      child: Center(
                          child: Text('$quantity',
                              style: AssalTypography.heading3))),
                  const SizedBox(width: AssalSpacing.sm),
                  Expanded(
                    child: _quantityCard(
                      Icons.add_rounded,
                      () => setState(() => quantity++),
                    ),
                  ),
                ]),
                const SizedBox(height: AssalSpacing.lg),
                DropdownButtonFormField<HandoffOption>(
                  initialValue: option,
                  decoration:
                      const InputDecoration(labelText: 'طريقة الاستلام'),
                  items: HandoffOption.values
                      .map((item) => DropdownMenuItem<HandoffOption>(
                          value: item, child: Text(item.labelAr)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => option = value ?? HandoffOption.contact),
                ),
                const SizedBox(height: AssalSpacing.md),
                TextField(
                  controller: bodyController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'رسالة الطلب'),
                ),
                const SizedBox(height: AssalSpacing.md),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(labelText: 'الهاتف (اختياري)'),
                ),
                const SizedBox(height: AssalSpacing.md),
                TextField(
                  controller: deliveryNoteController,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(labelText: 'ملاحظات التسليم'),
                ),
                const SizedBox(height: AssalSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: saving ? null : _submit,
                    icon: const Icon(Icons.send_outlined),
                    label: Text(saving ? 'جارٍ الإرسال...' : 'إرسال الطلب'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _quantityCard(IconData icon, VoidCallback onTap) => IconButton(
        onPressed: onTap,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: context.assalSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AssalRadius.medium),
            side: BorderSide(color: context.assalBorder),
          ),
        ),
      );
}
