from pathlib import Path

path = Path('/home/ubuntu/suq_aleasal/apps/mobile_flutter/lib/features/customer/customer_experience.dart')
text = path.read_text(encoding='utf-8')
old = """                      itemBuilder: (_, index) => ProductCard(product: products[index], onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(repository: widget.repository, productId: products[index].id))),\n"""
new = """                      itemBuilder: (_, index) {\n                        final product = products[index];\n                        return ProductCard(\n                          product: product,\n                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(repository: widget.repository, productId: product.id))),\n                        );\n                      },\n"""
if old not in text:
    raise SystemExit('product itemBuilder anchor not found')
text = text.replace(old, new, 1)

start = text.index('class _ReviewsSectionState extends State<_ReviewsSection> {')
end = text.index('class _CommentsSection extends StatefulWidget', start)
reviews = r'''class _ReviewsSectionState extends State<_ReviewsSection> {
  late Future<AssalLoadState<List<AssalReviewSummary>>> future;

  @override
  void initState() {
    super.initState();
    future = widget.repository.listReviews(widget.product.id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'المراجعات'),
      FutureBuilder<AssalLoadState<List<AssalReviewSummary>>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return AssalStateView<List<AssalReviewSummary>>(
            state: snapshot.data!,
            builder: (reviews) => Column(
              children: reviews.map<Widget>((review) => Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                  title: Row(children: [Text(review.authorName ?? 'عميل'), const SizedBox(width: AssalSpacing.sm), RatingStars(rating: review.rating.toDouble())]),
                  subtitle: Text(review.body ?? 'تجربة موثقة'),
                ),
              )).toList(),
            ),
          );
        },
      ),
      const SizedBox(height: AssalSpacing.sm),
      OutlinedButton.icon(onPressed: _writeReview, icon: const Icon(Icons.rate_review_outlined), label: const Text('أضف مراجعتك')),
    ]);
  }

  Future<void> _writeReview() async {
    final allowed = await requireAuth(context, widget.repository);
    if (!allowed || !mounted) return;
    final body = TextEditingController();
    var rating = 5;
    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setModal) => AlertDialog(
        title: const Text('مراجعتك'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<int>(value: rating, items: [1, 2, 3, 4, 5].map<DropdownMenuItem<int>>((item) => DropdownMenuItem(value: item, child: Text('$item نجوم'))).toList(), onChanged: (value) => setModal(() => rating = value ?? 5)),
          TextField(controller: body, maxLines: 3, decoration: const InputDecoration(hintText: 'شارك ما يفيد الآخرين')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('نشر')),
        ],
      )),
    );
    if (submit == true && body.text.trim().isNotEmpty) {
      await widget.repository.createReview('demo-customer', AssalReviewDraft(productId: widget.product.id, storeId: widget.product.storeId, rating: rating, body: body.text.trim()));
      if (mounted) setState(() => future = widget.repository.listReviews(widget.product.id));
    }
    body.dispose();
  }
}

'''
text = text[:start] + reviews + text[end:]
path.write_text(text, encoding='utf-8')
print('last customer sections fixed')
