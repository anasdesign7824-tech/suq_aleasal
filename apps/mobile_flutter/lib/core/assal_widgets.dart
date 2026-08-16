import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_design/assal_tokens.dart';
import 'assal_assets.dart';

class AssalBrandMark extends StatelessWidget {
  const AssalBrandMark({super.key, this.size = 44, this.showName = true});
  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'عسلكم',
        image: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(AssalAssets.logoInternal, width: size, height: size),
            if (showName) ...[
              const SizedBox(width: AssalSpacing.sm),
              Text('عسلكم', style: AssalTypography.heading3.copyWith(color: AssalColors.deepBrown)),
            ],
          ],
        ),
      );
}

class DemoModePill extends StatelessWidget {
  const DemoModePill({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.md, vertical: AssalSpacing.xs),
        decoration: BoxDecoration(color: AssalColors.honeyLight, borderRadius: BorderRadius.circular(AssalRadius.pill)),
        child: Text('تجربة بلا تسجيل', style: AssalTypography.caption.copyWith(color: AssalColors.primaryDark)),
      );
}

class AssalStateView<T> extends StatelessWidget {
  const AssalStateView({super.key, required this.state, required this.builder, this.onRetry});
  final AssalLoadState<T> state;
  final Widget Function(T value) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => switch (state) {
        AssalLoading<T>() => const Center(child: Padding(padding: EdgeInsets.all(AssalSpacing.x2l), child: CircularProgressIndicator(color: AssalColors.primaryDark))),
        AssalData<T>(:final value) => builder(value),
        AssalEmpty<T>(:final messageAr) => AssalMessageCard(icon: Icons.inbox_outlined, message: messageAr),
        AssalError<T>(:final messageAr, :final code) => AssalMessageCard(icon: Icons.error_outline, message: '$messageAr${code == null ? '' : '\nرمز: $code'}', onRetry: onRetry),
      };
}

class AssalMessageCard extends StatelessWidget {
  const AssalMessageCard({super.key, required this.icon, required this.message, this.onRetry});
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(vertical: AssalSpacing.md),
        child: Padding(
          padding: const EdgeInsets.all(AssalSpacing.x2l),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 42, color: AssalColors.textMuted),
            const SizedBox(height: AssalSpacing.md),
            Text(message, textAlign: TextAlign.center, style: AssalTypography.body.copyWith(color: AssalColors.textSecondary)),
            if (onRetry != null) ...[
              const SizedBox(height: AssalSpacing.md),
              OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
            ],
          ]),
        ),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: AssalTypography.heading3.copyWith(color: AssalColors.deepBrown)),
        if (actionLabel != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ]);
}

class AssalImageTile extends StatelessWidget {
  const AssalImageTile({super.key, this.imageUrl, this.height = 150, this.icon = Icons.local_florist_outlined});
  final String? imageUrl;
  final double height;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(color: AssalColors.honeyLight, borderRadius: BorderRadius.circular(AssalRadius.large)),
        clipBehavior: Clip.antiAlias,
        child: imageUrl != null && imageUrl!.startsWith('http')
            ? Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback())
            : _fallback(),
      );
  Widget _fallback() => Center(child: Icon(icon, size: height * .38, color: AssalColors.primaryDark));
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap, this.onFavorite});
  final AssalProductSummary product;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: product.nameAr,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stack(children: [
                AssalImageTile(imageUrl: product.primaryImageUrl, height: 138),
                if (onFavorite != null) Positioned(top: AssalSpacing.sm, left: AssalSpacing.sm, child: IconButton.filledTonal(onPressed: onFavorite, icon: const Icon(Icons.bookmark_border), tooltip: 'حفظ المنتج')),
              ]),
              Padding(
                padding: const EdgeInsets.all(AssalSpacing.md),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(product.nameAr, maxLines: 2, overflow: TextOverflow.ellipsis, style: AssalTypography.title.copyWith(color: AssalColors.deepBrown)),
                  const SizedBox(height: AssalSpacing.xs),
                  Text(product.subcategoryNameAr ?? product.categoryNameAr ?? 'منتج نحلي يمني', maxLines: 1, overflow: TextOverflow.ellipsis, style: AssalTypography.bodySmall.copyWith(color: AssalColors.textSecondary)),
                  const SizedBox(height: AssalSpacing.xs),
                  if (product.price != null) Text('${product.price!.toStringAsFixed(0)} ${product.currencyCode}', style: AssalTypography.bodySmall.copyWith(color: AssalColors.primaryDark, fontWeight: FontWeight.w700)),
                  const SizedBox(height: AssalSpacing.xs),
                  Row(children: [RatingStars(rating: product.ratingAverage), const SizedBox(width: AssalSpacing.xs), Text('(${product.reviewCount})', style: AssalTypography.caption.copyWith(color: AssalColors.textMuted)), const Spacer(), if (product.availability.isNotEmpty) Flexible(child: Text(product.availability, overflow: TextOverflow.ellipsis, style: AssalTypography.caption.copyWith(color: AssalColors.textSecondary)))]),
                  const SizedBox(height: AssalSpacing.sm),
                  Row(children: [
                    if (product.gradeLevel != null) InfoChip(label: 'درجة ${product.gradeLevel}'),
                    const Spacer(),
                    const Icon(Icons.arrow_back_rounded, size: 18, color: AssalColors.primaryDark),
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
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(AssalSpacing.lg), child: Row(children: [
          const CircleAvatar(radius: 30, backgroundColor: AssalColors.honeyLight, child: Icon(Icons.storefront_outlined, color: AssalColors.primaryDark, size: 28)),
          const SizedBox(width: AssalSpacing.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(store.nameAr, maxLines: 1, overflow: TextOverflow.ellipsis, style: AssalTypography.title.copyWith(color: AssalColors.deepBrown))), if (store.isVerified) const Icon(Icons.verified, color: AssalColors.primaryDark, size: 18)]),
            const SizedBox(height: AssalSpacing.xs),
            Text(store.regionNameAr ?? 'منصة عسلكم', style: AssalTypography.bodySmall.copyWith(color: AssalColors.textSecondary)),
            const SizedBox(height: AssalSpacing.xs),
            Row(children: [RatingStars(rating: store.ratingAverage), const SizedBox(width: AssalSpacing.sm), Text('${store.followersCount} متابع', style: AssalTypography.caption.copyWith(color: AssalColors.textMuted))]),
          ])),
          const Icon(Icons.chevron_left, color: AssalColors.textMuted),
        ]))),
      );
}

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating});
  final double rating;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (index) => Icon(index < rating.round() ? Icons.star_rounded : Icons.star_border_rounded, size: 16, color: AssalColors.primaryDark)));
}

class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.label, this.icon});
  final String label;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.sm, vertical: AssalSpacing.xs), decoration: BoxDecoration(color: AssalColors.surfaceVariant, borderRadius: BorderRadius.circular(AssalRadius.small)), child: Row(mainAxisSize: MainAxisSize.min, children: [if (icon != null) Icon(icon, size: 14, color: AssalColors.primaryDark), if (icon != null) const SizedBox(width: 3), Text(label, style: AssalTypography.caption.copyWith(color: AssalColors.secondary))]));
}

Future<bool> showAuthPrompt(BuildContext context) async => await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('هذه الميزة تحتاج حسابًا'),
        content: const Text('أنشئ حسابًا مجانيًا لحفظ المنتجات ومتابعة المتاجر وإرسال الطلبات، أو تابع التصفح كزائر.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('متابعة التصفح')),
          OutlinedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('تسجيل الدخول')),
        ],
      ),
    ) ?? false;
