import 'package:flutter/material.dart';

import '../../../../../packages/contracts_dart/lib/assal_domain.dart';
import '../../../../../packages/data_dart/lib/assal_repository.dart';
import '../../../../../packages/design_system/dart/lib/assal_tokens.dart';
import '../../core/assal_widgets.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});

  final AssalRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final searchController = TextEditingController();
  late Future<AssalLoadState<List<AssalProductSummary>>> productsFuture;

  @override
  void initState() {
    super.initState();
    productsFuture = widget.repository.listProducts(query: const AssalProductQuery(featuredOnly: true));
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void search(String value) {
    setState(() {
      productsFuture = widget.repository.listProducts(query: AssalProductQuery(search: value));
    });
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: () async => setState(() => productsFuture = widget.repository.listProducts(query: const AssalProductQuery(featuredOnly: true))),
        child: CustomScrollView(slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AssalSpacing.lg, AssalSpacing.lg, AssalSpacing.lg, AssalSpacing.md),
            sliver: SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const AssalBrandMark(size: 42),
                const DemoModePill(),
              ]),
              const SizedBox(height: AssalSpacing.xl),
              Text('اكتشف العسل اليمني من مصدره', style: AssalTypography.heading1.copyWith(color: AssalColors.deepBrown)),
              const SizedBox(height: AssalSpacing.sm),
              Text('متاجر موثوقة، منتجات مختارة، وتجربة تواصل واضحة.', style: AssalTypography.bodyLarge.copyWith(color: AssalColors.textSecondary)),
              const SizedBox(height: AssalSpacing.lg),
              TextField(
                controller: searchController,
                onSubmitted: search,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث عن سدر، سمر، شمع أو هدية'),
              ),
            ])),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.lg),
            sliver: SliverToBoxAdapter(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('منتجات مختارة', style: AssalTypography.heading2.copyWith(color: AssalColors.deepBrown)),
              TextButton(onPressed: () => search(''), child: const Text('عرض الكل')),
            ])),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AssalSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: FutureBuilder<AssalLoadState<List<AssalProductSummary>>>(
                future: productsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox(height: 260, child: Center(child: CircularProgressIndicator()));
                  return AssalStateView<List<AssalProductSummary>>(
                    state: snapshot.data!,
                    onRetry: () => setState(() => productsFuture = widget.repository.listProducts(query: const AssalProductQuery(featuredOnly: true))),
                    builder: (products) => GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: AssalSpacing.md, mainAxisSpacing: AssalSpacing.md, childAspectRatio: .68),
                      itemCount: products.length,
                      itemBuilder: (_, index) => ProductCard(product: products[index], onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(repository: widget.repository, productId: products[index].id)))),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ]),
      );
}
