import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_design/assal_tokens.dart';
import 'assal_assets.dart';


class AssalBrandMark extends StatelessWidget {
  const AssalBrandMark({
    super.key,
    this.size = 44,
    this.showName = false,
    this.framed = false,
    this.nameColor,
  });
  final double size;
  final bool showName;
  final bool framed;
  final Color? nameColor;

  @override
  Widget build(BuildContext context) {
    final mark = framed
        ? Container(
            width: size,
            height: size,
            padding:
                EdgeInsets.all(size >= 64 ? AssalSpacing.sm : AssalSpacing.xs),
            decoration: BoxDecoration(
              color: context.assalSurfaceRaised,
              borderRadius: BorderRadius.circular(AssalRadius.medium),
              border:
                  Border.all(color: context.assalBorderStrong),
            ),
            child: SvgPicture.asset(
              AssalAssets.logoInternal,
              colorFilter: ColorFilter.mode(
                context.assalPrimaryLight,
                BlendMode.srcIn,
              ),
            ),
          )
        : SvgPicture.asset(
            AssalAssets.logoInternal,
            width: size,
            height: size,
            colorFilter: ColorFilter.mode(
              context.assalPrimaryLight,
              BlendMode.srcIn,
            ),
          );

    return Semantics(
      label: 'عسلكم',
      image: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          if (showName) ...[
            SizedBox(width: AssalSpacing.sm),
            Text(
              'عسلكم',
              style: AssalTypography.heading3.copyWith(
                color: nameColor ?? context.assalTextPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AssalDesignCartStore extends ChangeNotifier {
  AssalDesignCartStore._();
  static final AssalDesignCartStore instance = AssalDesignCartStore._();

  final Map<String, String> _items = <String, String>{};

  int get count => _items.length;
  List<MapEntry<String, String>> get items => _items.entries.toList();
  bool contains(String productId) => _items.containsKey(productId);

  void add(String productId, String label) {
    _items[productId] = label;
    notifyListeners();
  }

  void remove(String productId) {
    if (_items.remove(productId) != null) notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}

class DemoModePill extends StatelessWidget {
  const DemoModePill({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: AssalSpacing.md, vertical: AssalSpacing.xs),
        decoration: BoxDecoration(
            color: context.assalSurfaceVariant,
            borderRadius: BorderRadius.circular(AssalRadius.pill),
            border: Border.all(color: context.assalBorder)),
        child: Text('تجربة بلا تسجيل',
            style: AssalTypography.caption
                .copyWith(color: context.assalTextSecondary)),
      );
}

class AssalAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AssalAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBrand = true,
    this.bottom,
  });

  final String title;
  final List<Widget>? actions;
  final bool showBrand;

  final PreferredSizeWidget? bottom;
  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.assalSurface,
        border: Border(bottom: BorderSide(color: context.assalBorder)),
      ),
      child: AppBar(
        bottom: bottom,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        forceMaterialTransparency: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: context.assalTextPrimary),
        titleTextStyle: AssalTypography.heading3
            .copyWith(color: context.assalTextPrimary),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              context.assalIsDark ? Brightness.light : Brightness.dark,
          statusBarBrightness:
              context.assalIsDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: context.assalBackground,
          systemNavigationBarIconBrightness:
              context.assalIsDark ? Brightness.light : Brightness.dark,
          systemNavigationBarContrastEnforced: false,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
        titleSpacing: AssalSpacing.sm,
        leading: canPop
            ? IconButton(
                tooltip: 'رجوع',
                icon: Icon(Icons.arrow_forward_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : showBrand
                ? Padding(
                    padding: EdgeInsets.all(AssalSpacing.sm),
                    child: AssalBrandMark(
                      size: 34,
                      showName: false,
                      framed: true,
                      nameColor: context.assalTextPrimary,
                    ),
                  )
                : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showBrand && canPop) ...[
              AssalBrandMark(
                size: 28,
                showName: false,
                framed: true,
                nameColor: context.assalTextPrimary,
              ),
              SizedBox(width: AssalSpacing.sm),
            ],
            Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: actions,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class AssalGlassLoading extends StatefulWidget {
  const AssalGlassLoading({
    super.key,
    this.height = 72,
    this.label = 'جارٍ تجهيز تجربة عسلكم...',
  });
  final double height;
  final String label;

  @override
  State<AssalGlassLoading> createState() => _AssalGlassLoadingState();
}

class _AssalGlassLoadingState extends State<AssalGlassLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.height.clamp(48, 120).toDouble();
    return Semantics(
      liveRegion: true,
      label: widget.label,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotationTransition(
                turns: _controller,
                child: Icon(
                  Icons.hive_outlined,
                  size: 22,
                  color: context.assalPrimary,
                ),
              ),
              SizedBox(width: AssalSpacing.xs),
              Text(
                widget.label,
                style: AssalTypography.bodySmall.copyWith(
                  color: context.assalTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AssalSkeleton extends StatelessWidget {
  const AssalSkeleton({super.key, this.height = 16, this.width, this.radius});
  final double height;
  final double? width;
  final double? radius;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: context.assalSurfaceVariant,
          borderRadius: BorderRadius.circular(radius ?? AssalRadius.small),
          border: Border.all(color: context.assalBorder),
        ),
      );
}

class AssalSkeletonList extends StatelessWidget {
  const AssalSkeletonList({super.key, this.count = 5});
  final int count;
  @override
  Widget build(BuildContext context) => ListView.separated(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.all(AssalSpacing.lg),
        itemCount: count,
        separatorBuilder: (_, __) => SizedBox(height: AssalSpacing.md),
        itemBuilder: (_, index) => Container(
          height: 104,
          decoration: BoxDecoration(
            color: context.assalSurfaceVariant,
            borderRadius: BorderRadius.circular(AssalRadius.large),
            border: Border.all(color: context.assalBorder),
          ),
          padding: EdgeInsets.all(AssalSpacing.md),
          child: Row(children: [
            AssalSkeleton(height: 68, width: 68, radius: 18),
            SizedBox(width: AssalSpacing.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AssalSkeleton(height: 14, width: 160),
                  SizedBox(height: AssalSpacing.sm),
                  AssalSkeleton(height: 11, width: 96),
                ],
              ),
            ),
          ]),
        ),
      );
}

class AssalFutureStateView<T> extends StatelessWidget {
  const AssalFutureStateView(
      {super.key,
      required this.future,
      required this.builder,
      this.onRetry,
      this.loadingHeight = 180});
  final Future<AssalLoadState<T>> future;
  final Widget Function(T value) builder;
  final VoidCallback? onRetry;
  final double loadingHeight;

  @override
  Widget build(BuildContext context) => FutureBuilder<AssalLoadState<T>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AssalMessageCard(
                icon: Icons.wifi_off_outlined,
                message:
                    'تعذر تحميل البيانات الآن. تحقق من الاتصال ثم حاول مرة أخرى.',
                onRetry: onRetry);
          }
          if (!snapshot.hasData) {
            return const AssalGlassLoading(height: 76);
          }
          return AssalStateView<T>(
              state: snapshot.data!, builder: builder, onRetry: onRetry);
        },
      );
}

class AssalStateView<T> extends StatelessWidget {
  const AssalStateView({
    super.key,
    required this.state,
    required this.builder,
    this.onRetry,
    this.emptyMessageAr =
        'لا توجد نتائج متاحة الآن. جرّب تغيير الفلاتر أو البحث مرة أخرى.',
  });
  final AssalLoadState<T> state;
  final Widget Function(T value) builder;
  final VoidCallback? onRetry;
  final String emptyMessageAr;

  @override
  Widget build(BuildContext context) => switch (state) {
        AssalLoading<T>() => const AssalSkeletonList(count: 3),
        AssalData<T>(:final value) => value is Iterable && value.isEmpty
            ? AssalMessageCard(
                icon: Icons.inbox_outlined,
                message: emptyMessageAr,
                onRetry: onRetry,
              )
            : builder(value),
        AssalEmpty<T>(:final messageAr) => AssalMessageCard(
            icon: Icons.inbox_outlined,
            message: messageAr,
            onRetry: onRetry,
          ),
        AssalError<T>(:final messageAr) => AssalMessageCard(
            icon: Icons.error_outline, message: messageAr, onRetry: onRetry),
      };
}

class HoneySectionHeader extends StatelessWidget {
  const HoneySectionHeader(
      {super.key, required this.title, this.subtitle, this.actionLabel, this.onAction});
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AssalTypography.heading3
                      .copyWith(color: context.assalTextPrimary),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AssalTypography.caption
                        .copyWith(color: context.assalTextMuted),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(
      {super.key, required this.title, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) =>
      HoneySectionHeader(title: title, actionLabel: actionLabel, onAction: onAction);
}

class AssalMessageCard extends StatelessWidget {
  const AssalMessageCard({
    super.key,
    required this.icon,
    required this.message,
    this.onRetry,
    this.title,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: AssalSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: context.assalSurfaceVariant,
                    borderRadius: BorderRadius.circular(AssalRadius.large),
                    border: Border.all(color: context.assalBorder),
                  ),
                  child: Icon(icon, size: 30, color: context.assalPrimary),
                ),
                SizedBox(height: AssalSpacing.md),
                if (title != null) ...[
                  Text(
                    title!,
                    textAlign: TextAlign.center,
                    style: AssalTypography.title
                        .copyWith(color: context.assalTextPrimary),
                  ),
                  SizedBox(height: AssalSpacing.xs),
                ],
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AssalTypography.body
                      .copyWith(color: context.assalTextSecondary),
                ),
                if (onRetry != null || actionLabel != null) ...[
                  SizedBox(height: AssalSpacing.md),
                  Wrap(
                    spacing: AssalSpacing.sm,
                    runSpacing: AssalSpacing.sm,
                    alignment: WrapAlignment.center,
                    children: [
                      if (onRetry != null)
                        OutlinedButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('إعادة المحاولة'),
                        ),
                      if (actionLabel != null && onAction != null)
                        FilledButton(
                          onPressed: onAction,
                          child: Text(actionLabel!),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}

class AssalImageUploadSlot extends StatelessWidget {
  const AssalImageUploadSlot({
    super.key,
    required this.label,
    required this.icon,
    required this.imageUrl,
    required this.bytes,
    required this.onPick,
    this.height = 150,
  });

  final String label;
  final IconData icon;
  final String? imageUrl;
  final Uint8List? bytes;
  final VoidCallback? onPick;
  final double height;

  @override
  Widget build(BuildContext context) {
    final image = bytes != null
        ? Image.memory(bytes!, fit: BoxFit.cover, width: double.infinity)
        : imageUrl != null && imageUrl!.startsWith('http')
            ? Image.network(imageUrl!,
                fit: BoxFit.cover, width: double.infinity)
            : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AssalTypography.subtitle
              .copyWith(color: context.assalTextPrimary),
        ),
        SizedBox(height: AssalSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AssalRadius.large),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: context.assalSurfaceVariant,
                  child: image ??
                      Center(
                        child: Icon(icon,
                            size: 42, color: context.assalPrimaryLight),
                      ),
                ),
                Positioned(
                  bottom: AssalSpacing.sm,
                  left: AssalSpacing.sm,
                  right: AssalSpacing.sm,
                  child: FilledButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(bytes != null || imageUrl != null
                        ? 'تغيير الصورة'
                        : 'إضافة الصورة'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AssalImageTile extends StatelessWidget {
  const AssalImageTile(
      {super.key,
      this.imageUrl,
      this.height = 150,
      this.icon = Icons.local_florist_outlined});
  final String? imageUrl;
  final double height;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
            color: context.assalSurfaceVariant,
            borderRadius: BorderRadius.circular(AssalRadius.large),
            border: Border.all(color: context.assalBorder)),
        clipBehavior: Clip.antiAlias,
        child: imageUrl != null && imageUrl!.startsWith('http')
            ? Image.network(imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                errorBuilder: (_, __, ___) => _fallback(context))
            : _fallback(context),
      );
  Widget _fallback(BuildContext context) => Center(
      child: Icon(icon, size: height * .38, color: context.assalPrimaryLight));
}

String formatAssalPrice(double? price, String currencyCode) {
  if (price == null) return 'السعر عند الطلب';
  final currency = switch (currencyCode.toUpperCase()) {
    'YER' => 'ريال يمني',
    'SAR' => 'ريال سعودي',
    'USD' => 'دولار أمريكي',
    _ => currencyCode,
  };
  return '${price.toStringAsFixed(0)} $currency';
}

String assalProductTypeLabel(ProductType type) => switch (type) {
      ProductType.honey => 'عسل',
      ProductType.wax => 'شمع',
      ProductType.mix => 'خلطة',
      ProductType.raw => 'منتج خام',
      ProductType.gift => 'هدية',
    };

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onFavorite,
    this.showVerifiedBadge = false,
  });
  final AssalProductSummary product;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final bool showVerifiedBadge;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: product.nameAr,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stack(children: [
                AssalImageTile(imageUrl: product.primaryImageUrl, height: 138),
                if (onFavorite != null)
                  Positioned(
                      top: AssalSpacing.sm,
                      left: AssalSpacing.sm,
                      child: IconButton(
                          onPressed: onFavorite,
                          icon: Icon(Icons.bookmark_border),
                          tooltip: 'حفظ المنتج')),
                if (showVerifiedBadge)
                  Positioned(
                    top: AssalSpacing.sm,
                    right: AssalSpacing.sm,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AssalSpacing.sm,
                        vertical: AssalSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: context.assalHoneyLight,
                        borderRadius: BorderRadius.circular(AssalRadius.pill),
                        border: Border.all(color: context.assalBorderStrong),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified,
                              size: 14, color: context.assalPrimaryLight),
                          SizedBox(width: AssalSpacing.xs),
                          Text('موثق Pro',
                              style: AssalTypography.caption.copyWith(
                                  color: context.assalPrimaryLight)),
                        ],
                      ),
                    ),
                  ),
              ]),
              Padding(
                padding: EdgeInsets.all(AssalSpacing.md),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.nameAr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AssalTypography.title
                              .copyWith(color: context.assalTextPrimary)),
                      SizedBox(height: AssalSpacing.xs),
                      Text(
                          product.weightLabel ??
                              product.subcategoryNameAr ??
                              product.categoryNameAr ??
                              'منتج نحلي يمني',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AssalTypography.bodySmall
                              .copyWith(color: context.assalTextSecondary)),
                      SizedBox(height: AssalSpacing.xs),
                      Row(children: [
                        RatingStars(rating: product.ratingAverage),
                        SizedBox(width: AssalSpacing.xs),
                        Text('(${product.reviewCount})',
                            style: AssalTypography.caption
                                .copyWith(color: context.assalTextMuted)),
                        Spacer(),
                        if (product.gradeLevel != null)
                          Flexible(
                              child: Text('درجة ${product.gradeLevel}',
                                  overflow: TextOverflow.ellipsis,
                                  style: AssalTypography.caption.copyWith(
                                      color: context.assalTextSecondary))),
                      ]),
                      SizedBox(height: AssalSpacing.sm),
                      Row(children: [
                        Expanded(
                          child: Text(
                            formatAssalPrice(
                                product.price, product.currencyCode),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AssalTypography.bodySmall.copyWith(
                                color: context.assalPrimaryLight,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                        SizedBox(width: AssalSpacing.xs),
                        IconButton(
                          onPressed: () {
                            AssalDesignCartStore.instance.add(
                                product.id, product.nameAr);
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(
                                  content: Text(
                                      'أُضيف «${product.nameAr}» إلى سلة التصميم'),
                                  duration: const Duration(seconds: 2)));
                          },
                          tooltip: 'أضف إلى السلة',
                          icon: Icon(Icons.shopping_cart_outlined, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: context.assalPrimary,
                            foregroundColor: context.assalCream,
                            minimumSize: const Size(36, 36),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ]),
                    ]),
              ),
            ]),
          ),
        ),
      );
}

class StoreCard extends StatelessWidget {
  const StoreCard({super.key, required this.store, required this.onTap});
  final AssalStoreSummary store;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final logoUrl = store.logoUrl ?? store.avatarUrl;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: onTap,
          child: Padding(
              padding: EdgeInsets.all(AssalSpacing.lg),
              child: Row(children: [
                CircleAvatar(
                    radius: 30,
                    backgroundColor: context.assalSurfaceVariant,
                    backgroundImage: logoUrl != null && logoUrl.startsWith('http')
                        ? NetworkImage(logoUrl)
                        : null,
                    child: logoUrl == null || !logoUrl.startsWith('http')
                        ? Icon(Icons.storefront_outlined,
                            color: context.assalPrimaryLight, size: 28)
                        : null),
                  SizedBox(width: AssalSpacing.md),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(children: [
                          Expanded(
                              child: Text(store.nameAr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AssalTypography.title
                                      .copyWith(color: context.assalTextPrimary))),
                          if (store.isVerified)
                            Tooltip(
                              message: 'متجر موثق Pro',
                              child: Icon(Icons.verified,
                                  color: context.assalPrimaryLight, size: 18),
                            )
                        ]),
                        SizedBox(height: AssalSpacing.xs),
                        Text(store.regionNameAr ?? 'منصة عسلكم',
                            style: AssalTypography.bodySmall
                                .copyWith(color: context.assalTextSecondary)),
                        SizedBox(height: AssalSpacing.xs),
                        Row(children: [
                          RatingStars(rating: store.ratingAverage),
                          SizedBox(width: AssalSpacing.sm),
                          Text('${store.followersCount} متابع',
                              style: AssalTypography.caption
                                  .copyWith(color: context.assalTextMuted))
                        ]),
                      ])),
                  Icon(Icons.chevron_left, color: context.assalTextMuted),
                ]),
            ),
          ),
      );
  }
}

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating});
  final double rating;
  @override
  Widget build(BuildContext context) => Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
          5,
          (index) => Icon(
              index < rating.round()
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              size: 16,
              color: context.assalPrimaryLight)));
}

class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.label, this.icon});
  final String label;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
      padding: EdgeInsets.symmetric(
          horizontal: AssalSpacing.sm, vertical: AssalSpacing.xs),
      decoration: BoxDecoration(
          color: context.assalSurfaceVariant,
          borderRadius: BorderRadius.circular(AssalRadius.small),
          border: Border.all(color: context.assalBorder)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null)
          Icon(icon, size: 14, color: context.assalPrimaryLight),
        if (icon != null) SizedBox(width: 3),
        Text(label,
            style: AssalTypography.caption
                .copyWith(color: context.assalTextSecondary))
      ]));
}

class HoneyPill extends StatelessWidget {
  const HoneyPill(
      {super.key,
      required this.label,
      this.icon,
      this.color,
      this.selected = false,
      this.onTap});
  final String label;
  final IconData? icon;
  final Color? color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: EdgeInsets.symmetric(
          horizontal: AssalSpacing.md, vertical: AssalSpacing.sm),
      decoration: BoxDecoration(
        color: selected ? context.assalHoneyLight : context.assalSurfaceVariant,
        borderRadius: BorderRadius.circular(AssalRadius.pill),
        border: Border.all(
            color: selected ? context.assalPrimary : context.assalBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon,
              size: 16,
              color: selected ? context.assalPrimaryLight : context.assalTextSecondary),
          SizedBox(width: AssalSpacing.xs),
        ],
        Text(label,
            style: AssalTypography.caption.copyWith(
                color: selected
                    ? context.assalPrimaryLight
                    : color ?? context.assalTextSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      ]),
    );
    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(AssalRadius.pill),
      onTap: onTap,
      child: content,
    );
  }
}

Future<bool> showAuthPrompt(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.assalSurfaceRaised,
        title: Text('هذه الميزة تحتاج حسابًا'),
        content: Text(
            'أنشئ حسابًا مجانيًا لحفظ المنتجات ومتابعة المتاجر وإرسال الطلبات، أو تابع التصفح كزائر.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('متابعة التصفح')),
          OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('تسجيل الدخول')),
        ],
      ),
    ) ??
    false;
