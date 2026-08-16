from pathlib import Path

path = Path('/home/ubuntu/suq_aleasal/apps/mobile_flutter/lib/features/customer/customer_experience.dart')
text = path.read_text(encoding='utf-8')
old_home = "            return AssalStateView<List<AssalStoreSummary>>(state: snapshot.data!, builder: (stores) => Column(children: stores.take(3).map((store) => StoreCard(store: store, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoreProfileScreen(repository: widget.repository, storeId: store.id)))).toList()));\n"
new_home = """            return AssalStateView<List<AssalStoreSummary>>(
              state: snapshot.data!,
              builder: (stores) => Column(
                children: stores.take(3).map<Widget>((store) {
                  return StoreCard(
                    store: store,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoreProfileScreen(repository: widget.repository, storeId: store.id))),
                  );
                }).toList(),
              ),
            );
"""
if old_home not in text:
    raise SystemExit('home store anchor not found')
text = text.replace(old_home, new_home, 1)
start = text.index('class _StoreProfileScreenState extends State<StoreProfileScreen> {')
end = text.index('class RequestSheet extends StatefulWidget', start)
store = r'''class _StoreProfileScreenState extends State<StoreProfileScreen> {
  bool following = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('صفحة المتجر')),
      body: FutureBuilder<AssalLoadState<AssalStoreSummary>>(
        future: widget.repository.getStore(widget.storeId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return AssalStateView<AssalStoreSummary>(state: snapshot.data!, builder: _content);
        },
      ),
    );
  }

  Widget _content(AssalStoreSummary store) {
    final specialties = store.specialties.isEmpty ? ['عسل يمني', 'مصدر موثق'] : store.specialties;
    return ListView(padding: const EdgeInsets.all(AssalSpacing.lg), children: [
      Container(height: 150, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AssalColors.secondary, AssalColors.deepBrown]), borderRadius: BorderRadius.circular(AssalRadius.extraLarge)), child: const Center(child: Icon(Icons.hive_outlined, size: 80, color: AssalColors.primaryLight))),
      Transform.translate(offset: const Offset(0, -28), child: const CircleAvatar(radius: 36, backgroundColor: AssalColors.honeyLight, child: Icon(Icons.storefront_outlined, size: 34, color: AssalColors.primaryDark))),
      Text(store.nameAr, textAlign: TextAlign.center, style: AssalTypography.heading1.copyWith(color: AssalColors.deepBrown)),
      const SizedBox(height: AssalSpacing.sm),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [if (store.isVerified) const Icon(Icons.verified, size: 18, color: AssalColors.primaryDark), const SizedBox(width: 4), Text(store.isVerified ? 'متجر موثق' : 'متجر في طور التعريف', style: AssalTypography.body.copyWith(color: AssalColors.textSecondary))]),
      const SizedBox(height: AssalSpacing.md),
      Text(store.description ?? 'متجر متخصص في المنتجات النحلية اليمنية.', textAlign: TextAlign.center, style: AssalTypography.bodyLarge.copyWith(color: AssalColors.textSecondary)),
      const SizedBox(height: AssalSpacing.lg),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_stat('${store.followersCount}', 'متابع'), _stat('${store.reviewCount}', 'مراجعة'), _stat('${store.yearsExperience}', 'سنوات خبرة')]),
      const SizedBox(height: AssalSpacing.lg),
      Row(children: [
        Expanded(child: FilledButton.icon(onPressed: () async { final allowed = await requireAuth(context, widget.repository); if (!allowed || !mounted) return; final result = await widget.repository.toggleFollow('demo-customer', store.id); if (result is AssalData<bool>) setState(() => following = result.value); }, icon: Icon(following ? Icons.check : Icons.person_add_alt_1), label: Text(following ? 'تتابعه' : 'متابعة'))),
        const SizedBox(width: AssalSpacing.sm),
        Expanded(child: OutlinedButton.icon(onPressed: () async { final allowed = await requireAuth(context, widget.repository); if (!allowed || !mounted) return; final conversation = AssalConversationSummary(id: 'demo-conversation-${store.id}', storeId: store.id, storeName: store.nameAr, lastMessage: 'ابدأ محادثة جديدة', updatedAt: DateTime.now()); Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConversationScreen(repository: widget.repository, conversation: conversation))); }, icon: const Icon(Icons.forum_outlined), label: const Text('مراسلة'))),
      ]),
      const SizedBox(height: AssalSpacing.xl),
      const SectionHeader(title: 'تخصصات المتجر'),
      Wrap(spacing: AssalSpacing.sm, runSpacing: AssalSpacing.sm, children: specialties.map<Widget>((item) => InfoChip(label: item)).toList()),
      const SizedBox(height: AssalSpacing.xl),
      const SectionHeader(title: 'منتجات المتجر'),
      FutureBuilder<AssalLoadState<List<AssalProductSummary>>>(
        future: widget.repository.listProducts(query: AssalProductQuery(storeId: store.id)),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return AssalStateView<List<AssalProductSummary>>(
            state: snapshot.data!,
            builder: (products) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: AssalSpacing.md, mainAxisSpacing: AssalSpacing.md, childAspectRatio: .68),
              itemCount: products.length,
              itemBuilder: (_, index) {
                final product = products[index];
                return ProductCard(product: product, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(repository: widget.repository, productId: product.id))));
              },
            ),
          );
        },
      ),
    ]);
  }

  Widget _stat(String value, String label) => Column(children: [Text(value, style: AssalTypography.heading3.copyWith(color: AssalColors.deepBrown)), Text(label, style: AssalTypography.caption.copyWith(color: AssalColors.textMuted))]);
}

'''
text = text[:start] + store + text[end:]
path.write_text(text, encoding='utf-8')
print('store profile fixed')
