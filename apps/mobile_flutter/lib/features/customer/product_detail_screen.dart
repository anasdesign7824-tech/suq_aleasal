import 'package:flutter/material.dart';

import '../../../../../packages/contracts_dart/lib/assal_domain.dart';
import '../../../../../packages/data_dart/lib/assal_repository.dart';
import '../../../../../packages/design_system/dart/lib/assal_tokens.dart';
import '../../core/assal_widgets.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.repository, required this.productId});

  final AssalRepository repository;
  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<AssalLoadState<AssalProductSummary>> productFuture;
  late Future<AssalLoadState<List<AssalReviewSummary>>> reviewsFuture;

  @override
  void initState() {
    super.initState();
    productFuture = widget.repository.getProduct(widget.productId);
    reviewsFuture = widget.repository.listReviews(widget.productId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('تفاصيل المنتج')),
        body: FutureBuilder<AssalLoadState<AssalProductSummary>>(
          future: productFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            return AssalStateView<AssalProductSummary>(
              state: snapshot.data!,
              onRetry: () => setState(() => productFuture = widget.repository.getProduct(widget.productId)),
              builder: (product) => ListView(padding: const EdgeInsets.all(AssalSpacing.lg), children: [
                Container(height: 220, decoration: BoxDecoration(color: AssalColors.honeyLight, borderRadius: BorderRadius.circular(AssalRadius.extraLarge)), child: const AssalBrandMark(size: 150, showName: false)),
                const SizedBox(height: AssalSpacing.lg),
                Text(product.nameAr, style: AssalTypography.heading1.copyWith(color: AssalColors.deepBrown)),
                const SizedBox(height: AssalSpacing.sm),
                Row(children: [const Icon(Icons.star, color: AssalColors.primaryDark), const SizedBox(width: 4), Text('${product.ratingAverage.toStringAsFixed(1)} من 5'), const SizedBox(width: AssalSpacing.md), Text('${product.reviewCount} مراجعات', style: AssalTypography.body.copyWith(color: AssalColors.textSecondary))]),
                const SizedBox(height: AssalSpacing.lg),
                if (product.description != null) Text(product.description!, style: AssalTypography.bodyLarge),
                const SizedBox(height: AssalSpacing.xl),
                FilledButton.icon(onPressed: () => _showContactSheet(context, product), icon: const Icon(Icons.chat_bubble_outline), label: const Text('تواصل مع المتجر')),
                const SizedBox(height: AssalSpacing.xl),
                Text('مراجعات العملاء', style: AssalTypography.heading2.copyWith(color: AssalColors.deepBrown)),
                const SizedBox(height: AssalSpacing.md),
                FutureBuilder<AssalLoadState<List<AssalReviewSummary>>>(future: reviewsFuture, builder: (context, reviewSnapshot) {
                  if (!reviewSnapshot.hasData) return const Padding(padding: EdgeInsets.all(AssalSpacing.lg), child: Center(child: CircularProgressIndicator()));
                  return AssalStateView<List<AssalReviewSummary>>(state: reviewSnapshot.data!, builder: (reviews) => Column(children: reviews.map((review) => Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text('${review.rating} ★'), subtitle: Text(review.body ?? 'مراجعة موثقة'))).toList()));
                }),
              ]),
            );
          },
        ),
      );

  void _showContactSheet(BuildContext context, AssalProductSummary product) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AssalSpacing.xl),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('طلب تواصل', style: AssalTypography.heading2),
          const SizedBox(height: AssalSpacing.sm),
          Text('أرسل استفسارك حول ${product.nameAr} إلى المتجر في Demo Mode.'),
          const SizedBox(height: AssalSpacing.lg),
          TextField(maxLines: 3, decoration: const InputDecoration(hintText: 'اكتب رسالتك هنا')),
          const SizedBox(height: AssalSpacing.lg),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('تم حفظ الطلب التجريبي'))); }, child: const Text('إرسال الطلب'))),
        ]),
      ),
    );
  }
}
