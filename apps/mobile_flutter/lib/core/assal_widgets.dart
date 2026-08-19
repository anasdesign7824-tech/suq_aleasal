import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_design/assal_tokens.dart';
import 'assal_assets.dart';

const assalDarkGradient = AssalColors.darkGradient;

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
              color: AssalColors.cream,
              borderRadius: BorderRadius.circular(AssalRadius.small),
              border:
                  Border.all(color: AssalColors.cream.withValues(alpha: .9)),
            ),
            child: SvgPicture.asset(AssalAssets.logoInternal),
          )
        : SvgPicture.asset(
            AssalAssets.logoInternal,
            width: size,
            height: size,
          );

    return Semantics(
      label: 'عسلكم',
      image: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          if (showName) ...[
            const SizedBox(width: AssalSpacing.sm),
            Text(
              'عسلكم',
              style: AssalTypography.heading3.copyWith(
                color: nameColor ?? AssalColors.deepBrown,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DemoModePill extends StatelessWidget {
  const DemoModePill({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AssalSpacing.md, vertical: AssalSpacing.xs),
        decoration: BoxDecoration(
            color: AssalColors.honeyLight,
            borderRadius: BorderRadius.circular(AssalRadius.pill)),
        child: Text('تجربة بلا تسجيل',
            style: AssalTypography.caption
                .copyWith(color: AssalColors.primaryDark)),
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
      decoration: const BoxDecoration(gradient: assalDarkGradient),
      child: AppBar(
        bottom: bottom,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        forceMaterialTransparency: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: AssalTypography.heading3.copyWith(color: Colors.white),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AssalColors.primaryDark,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarContrastEnforced: false,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
        titleSpacing: AssalSpacing.sm,
        leading: canPop
            ? IconButton(
                tooltip: 'رجوع',
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : showBrand
                ? const Padding(
                    padding: EdgeInsets.all(AssalSpacing.sm),
                    child: AssalBrandMark(
                      size: 36,
                      showName: false,
                      framed: true,
                      nameColor: Colors.white,
                    ),
                  )
                : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showBrand && canPop) ...[
              const AssalBrandMark(
                size: 28,
                showName: true,
                framed: true,
                nameColor: Colors.white,
              ),
              const SizedBox(width: AssalSpacing.sm),
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
    final height = widget.height.clamp(56, 104).toDouble();
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
                child: const Icon(
                  Icons.hive_outlined,
                  size: 22,
                  color: AssalColors.primaryDark,
                ),
              ),
              const SizedBox(width: AssalSpacing.xs),
              Text(
                widget.label,
                style: AssalTypography.bodySmall.copyWith(
                  color: AssalColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
            return AssalGlassLoading(height: loadingHeight);
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
        AssalLoading<T>() => const AssalGlassLoading(),
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

class AssalMessageCard extends StatelessWidget {
  const AssalMessageCard({
    super.key,
    required this.icon,
    required this.message,
    this.onRetry,
  });
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AssalSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 34, color: AssalColors.textMuted),
                const SizedBox(height: AssalSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AssalTypography.body.copyWith(
                    color: AssalColors.textSecondary,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: AssalSpacing.sm),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ],
            ),
          ),
        ),
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
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title,
            style: AssalTypography.heading3
                .copyWith(color: AssalColors.deepBrown)),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ]);
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
        Text(label, style: AssalTypography.subtitle),
        const SizedBox(height: AssalSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AssalRadius.large),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: AssalColors.honeyLight,
                  child: image ?? Center(child: Icon(icon, size: 42)),
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
            color: AssalColors.honeyLight,
            borderRadius: BorderRadius.circular(AssalRadius.large)),
        clipBehavior: Clip.antiAlias,
        child: imageUrl != null && imageUrl!.startsWith('http')
            ? Image.network(imageUrl!,
                fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback())
            : _fallback(),
      );
  Widget _fallback() => Center(
      child: Icon(icon, size: height * .38, color: AssalColors.primaryDark));
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
                      child: IconButton.filledTonal(
                          onPressed: onFavorite,
                          icon: const Icon(Icons.bookmark_border),
                          tooltip: 'حفظ المنتج')),
                if (showVerifiedBadge)
                  Positioned(
                    top: AssalSpacing.sm,
                    right: AssalSpacing.sm,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AssalColors.success,
                        borderRadius: BorderRadius.circular(AssalRadius.pill),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AssalSpacing.sm,
                          vertical: AssalSpacing.xs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified,
                                size: 14, color: AssalColors.cream),
                            SizedBox(width: AssalSpacing.xs),
                            Text('موثق Pro',
                                style: TextStyle(color: AssalColors.cream)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ]),
              Padding(
                padding: const EdgeInsets.all(AssalSpacing.md),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.nameAr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AssalTypography.title
                              .copyWith(color: AssalColors.deepBrown)),
                      const SizedBox(height: AssalSpacing.xs),
                      Text(
                          product.subcategoryNameAr ??
                              product.categoryNameAr ??
                              'منتج نحلي يمني',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AssalTypography.bodySmall
                              .copyWith(color: AssalColors.textSecondary)),
                      const SizedBox(height: AssalSpacing.xs),
                      Text(
                          formatAssalPrice(product.price, product.currencyCode),
                          style: AssalTypography.bodySmall.copyWith(
                              color: AssalColors.primaryDark,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: AssalSpacing.xs),
                      Row(children: [
                        RatingStars(rating: product.ratingAverage),
                        const SizedBox(width: AssalSpacing.xs),
                        Text('(${product.reviewCount})',
                            style: AssalTypography.caption
                                .copyWith(color: AssalColors.textMuted)),
                        const Spacer(),
                        if (product.availability.isNotEmpty)
                          Flexible(
                              child: Text(product.availability,
                                  overflow: TextOverflow.ellipsis,
                                  style: AssalTypography.caption.copyWith(
                                      color: AssalColors.textSecondary)))
                      ]),
                      const SizedBox(height: AssalSpacing.sm),
                      Row(children: [
                        if (product.gradeLevel != null)
                          InfoChip(label: 'درجة ${product.gradeLevel}'),
                        const Spacer(),
                        const Icon(Icons.arrow_back_rounded,
                            size: 18, color: AssalColors.primaryDark),
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
              padding: const EdgeInsets.all(AssalSpacing.lg),
              child: Row(children: [
                CircleAvatar(
                    radius: 30,
                    backgroundColor: AssalColors.honeyLight,
                    backgroundImage: logoUrl != null && logoUrl.startsWith('http')
                        ? NetworkImage(logoUrl)
                        : null,
                    child: logoUrl == null || !logoUrl.startsWith('http')
                        ? const Icon(Icons.storefront_outlined,
                            color: AssalColors.primaryDark, size: 28)
                        : null),
                  const SizedBox(width: AssalSpacing.md),
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
                                      .copyWith(color: AssalColors.deepBrown))),
                          if (store.isVerified)
                            const Tooltip(
                              message: 'متجر موثق Pro',
                              child: Icon(Icons.verified,
                                  color: AssalColors.primaryDark, size: 18),
                            )
                        ]),
                        const SizedBox(height: AssalSpacing.xs),
                        Text(store.regionNameAr ?? 'منصة عسلكم',
                            style: AssalTypography.bodySmall
                                .copyWith(color: AssalColors.textSecondary)),
                        const SizedBox(height: AssalSpacing.xs),
                        Row(children: [
                          RatingStars(rating: store.ratingAverage),
                          const SizedBox(width: AssalSpacing.sm),
                          Text('${store.followersCount} متابع',
                              style: AssalTypography.caption
                                  .copyWith(color: AssalColors.textMuted))
                        ]),
                      ])),
                  const Icon(Icons.chevron_left, color: AssalColors.textMuted),
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
              color: AssalColors.primaryDark)));
}

class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.label, this.icon});
  final String label;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AssalSpacing.sm, vertical: AssalSpacing.xs),
      decoration: BoxDecoration(
          color: AssalColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AssalRadius.small)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) Icon(icon, size: 14, color: AssalColors.primaryDark),
        if (icon != null) const SizedBox(width: 3),
        Text(label,
            style:
                AssalTypography.caption.copyWith(color: AssalColors.secondary))
      ]));
}

Future<bool> showAuthPrompt(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('هذه الميزة تحتاج حسابًا'),
        content: const Text(
            'أنشئ حسابًا مجانيًا لحفظ المنتجات ومتابعة المتاجر وإرسال الطلبات، أو تابع التصفح كزائر.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('متابعة التصفح')),
          OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('تسجيل الدخول')),
        ],
      ),
    ) ??
    false;
