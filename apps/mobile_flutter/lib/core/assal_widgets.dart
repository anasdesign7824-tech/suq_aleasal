import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../packages/contracts_dart/lib/assal_domain.dart';
import '../../../../packages/design_system/dart/lib/assal_tokens.dart';

class AssalBrandMark extends StatelessWidget {
  const AssalBrandMark({super.key, this.size = 48, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset('assets/logo-internal.svg', width: size, height: size),
        if (showName) ...[
          const SizedBox(width: AssalSpacing.sm),
          Text('عسلكم', style: AssalTypography.heading3.copyWith(color: AssalColors.deepBrown)),
        ],
      ],
    );
  }
}

class DemoModePill extends StatelessWidget {
  const DemoModePill({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.md, vertical: AssalSpacing.xs),
        decoration: BoxDecoration(color: AssalColors.honeyLight, borderRadius: BorderRadius.circular(AssalRadius.pill)),
        child: const Text('نسخة تجريبية', style: AssalTypography.caption),
      );
}

class AssalStateView<T> extends StatelessWidget {
  const AssalStateView({super.key, required this.state, required this.builder, this.onRetry});

  final AssalLoadState<T> state;
  final Widget Function(T value) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      AssalLoading<T>() => const Center(child: CircularProgressIndicator()),
      AssalData<T>(:final value) => builder(value),
      AssalEmpty<T>(:final messageAr) => _MessageCard(icon: Icons.inbox_outlined, message: messageAr),
      AssalError<T>(:final messageAr, :final code) => _MessageCard(icon: Icons.error_outline, message: '$messageAr${code == null ? '' : '\nرمز: $code'}', onRetry: onRetry),
    };
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.icon, required this.message, this.onRetry});

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AssalSpacing.xl),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 40, color: AssalColors.textMuted),
              const SizedBox(height: AssalSpacing.md),
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: AssalSpacing.md),
                OutlinedButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
              ],
            ]),
          ),
        ),
      );
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final AssalProductSummary product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AssalRadius.large),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: 120,
              width: double.infinity,
              color: AssalColors.honeyLight,
              child: Center(child: SvgPicture.asset('assets/logo-internal.svg', width: 86, height: 86)),
            ),
            Padding(
              padding: const EdgeInsets.all(AssalSpacing.md),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product.nameAr, maxLines: 2, overflow: TextOverflow.ellipsis, style: AssalTypography.title),
                const SizedBox(height: AssalSpacing.xs),
                Text('${product.ratingAverage.toStringAsFixed(1)} ★  •  ${product.reviewCount} مراجعات', style: AssalTypography.bodySmall.copyWith(color: AssalColors.textSecondary)),
                const SizedBox(height: AssalSpacing.sm),
                Row(children: [
                  if (product.isFeatured) const _Badge(label: 'مختار'),
                  const Spacer(),
                  const Icon(Icons.arrow_back, size: 18, color: AssalColors.primaryDark),
                ]),
              ]),
            ),
          ]),
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.sm, vertical: AssalSpacing.xs),
        decoration: BoxDecoration(color: AssalColors.cream, borderRadius: BorderRadius.circular(AssalRadius.small)),
        child: Text(label, style: AssalTypography.caption.copyWith(color: AssalColors.secondary)),
      );
}
