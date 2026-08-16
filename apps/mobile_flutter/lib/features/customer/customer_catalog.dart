import 'package:flutter/material.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_design/assal_tokens.dart';
import '../../core/assal_widgets.dart';
import 'customer_core.dart';
import 'customer_account.dart';
import 'customer_social.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.repository, required this.productId});
  final AssalRepository repository;
  final String productId;
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<AssalLoadState<AssalProductSummary>> productFuture;
  bool liked = false;
  bool favorite = false;
  @override
  void initState() { super.initState(); productFuture = widget.repository.getProduct(widget.productId); }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('تفاصيل المنتج'), actions: [IconButton(onPressed: () => _share(), icon: const Icon(Icons.share_outlined), tooltip: 'مشاركة')]), body: FutureBuilder<AssalLoadState<AssalProductSummary>>(future: productFuture, builder: (context, snapshot) { if (!snapshot.hasData) return const Center(child: CircularProgressIndicator()); return AssalStateView<AssalProductSummary>(state: snapshot.data!, onRetry: () => setState(() => productFuture = widget.repository.getProduct(widget.productId)), builder: (product) => _content(product)); }));

  Widget _content(AssalProductSummary product) => FutureBuilder<AssalLoadState<AssalStoreSummary>>(future: widget.repository.getStore(product.storeId), builder: (context, storeSnapshot) {
    final store = storeSnapshot.data is AssalData<AssalStoreSummary> ? (storeSnapshot.data! as AssalData<AssalStoreSummary>).value : null;
    return ListView(padding: const EdgeInsets.all(AssalSpacing.lg), children: [
      SizedBox(height: 260, child: PageView(children: [AssalImageTile(imageUrl: product.primaryImageUrl, height: 260), AssalImageTile(imageUrl: product.primaryImageUrl, height: 260, icon: Icons.wb_sunny_outlined), AssalImageTile(imageUrl: product.primaryImageUrl, height: 260, icon: Icons.hive_outlined)])),
      const SizedBox(height: AssalSpacing.md),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (index) => Container(width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(color: index == 0 ? AssalColors.primaryDark : AssalColors.border, shape: BoxShape.circle)))),
      const SizedBox(height: AssalSpacing.lg),
      Text(product.nameAr, style: AssalTypography.heading1.copyWith(color: AssalColors.deepBrown)),
      const SizedBox(height: AssalSpacing.sm),
      Wrap(spacing: AssalSpacing.sm, runSpacing: AssalSpacing.sm, children: [if (product.subcategoryNameAr != null) InfoChip(label: product.subcategoryNameAr!), if (product.regionNameAr != null) InfoChip(label: product.regionNameAr!), if (product.gradeLevel != null) InfoChip(label: 'الجودة: درجة ${product.gradeLevel}', icon: Icons.verified_outlined)]),
      const SizedBox(height: AssalSpacing.lg),
      if (product.description != null) Text(product.description!, style: AssalTypography.bodyLarge),
      if (product.tags.isNotEmpty) ...[const SizedBox(height: AssalSpacing.lg), Text('لماذا قد يناسبك؟', style: AssalTypography.heading3.copyWith(color: AssalColors.deepBrown)), const SizedBox(height: AssalSpacing.sm), Wrap(spacing: AssalSpacing.sm, runSpacing: AssalSpacing.sm, children: product.tags.map((tag) => InfoChip(label: tag)).toList())],
      const SizedBox(height: AssalSpacing.lg),
      _MetadataCard(product: product),
      const SizedBox(height: AssalSpacing.lg),
      if (store != null) Card(child: ListTile(leading: const CircleAvatar(backgroundColor: AssalColors.honeyLight, child: Icon(Icons.storefront_outlined, color: AssalColors.primaryDark)), title: Text(store.nameAr), subtitle: Text(store.isVerified ? 'متجر موثق · ${store.regionNameAr ?? ''}' : 'متجر على منصة عسلكم'), trailing: TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoreProfileScreen(repository: widget.repository, storeId: store.id))), child: const Text('فتح المتجر')))),
      const SizedBox(height: AssalSpacing.lg),
      Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () async { final session = await requireAuth(context, widget.repository); if (!session || !mounted) return; final result = await widget.repository.toggleLike('demo-customer', product.id); if (result is AssalData<bool>) setState(() => liked = result.value); }, icon: Icon(liked ? Icons.thumb_up : Icons.thumb_up_outlined), label: Text(liked ? 'أعجبتني' : 'إعجاب'))), const SizedBox(width: AssalSpacing.sm), Expanded(child: OutlinedButton.icon(onPressed: () async { final session = await requireAuth(context, widget.repository); if (!session || !mounted) return; final result = await widget.repository.toggleFavorite('demo-customer', product.id); if (result is AssalData<bool>) setState(() => favorite = result.value); }, icon: Icon(favorite ? Icons.bookmark : Icons.bookmark_border), label: Text(favorite ? 'محفوظ' : 'حفظ')))]),
      const SizedBox(height: AssalSpacing.md),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => _request(product, store), icon: const Icon(Icons.chat_bubble_outline), label: const Text('إرسال طلب تواصل'))),
      const SizedBox(height: AssalSpacing.xl),
      ReviewsSection(repository: widget.repository, product: product),
      const SizedBox(height: AssalSpacing.xl),
      CommentsSection(repository: widget.repository, targetId: product.id),
      const SizedBox(height: AssalSpacing.xl),
    ]);
  });

  Future<void> _request(AssalProductSummary product, AssalStoreSummary? store) async { if (store == null) return; final session = await requireAuth(context, widget.repository); if (!session || !mounted) return; await showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => RequestSheet(repository: widget.repository, product: product, store: store)); }
  void _share() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تجهيز رابط المشاركة في Demo Mode')));
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.product});
  final AssalProductSummary product;
  @override
  Widget build(BuildContext context) => Card(color: AssalColors.cream, child: Padding(padding: const EdgeInsets.all(AssalSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('بيانات المصدر والجودة', style: AssalTypography.heading3.copyWith(color: AssalColors.deepBrown)), const SizedBox(height: AssalSpacing.md), _row('نوع المنتج', _productTypeLabel(product.productType)), _row('المنطقة', product.regionNameAr ?? 'غير محددة'), _row('التصنيف', product.subcategoryNameAr ?? 'غير محدد'), _row('التوفر', product.availability), if (product.weightLabel != null) _row('الوزن', product.weightLabel!), if (product.harvestLabel != null) _row('الإنتاج', product.harvestLabel!)])));
  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: AssalSpacing.xs), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 92, child: Text(label, style: AssalTypography.bodySmall.copyWith(color: AssalColors.textMuted))), Expanded(child: Text(value, style: AssalTypography.body.copyWith(color: AssalColors.textPrimary)))]));
}

class StoreProfileScreen extends StatefulWidget {
  const StoreProfileScreen({super.key, required this.repository, required this.storeId});
  final AssalRepository repository;
  final String storeId;
  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
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

class RequestSheet extends StatefulWidget {
  const RequestSheet({super.key, required this.repository, required this.product, required this.store});
  final AssalRepository repository;
  final AssalProductSummary product;
  final AssalStoreSummary store;
  @override
  State<RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<RequestSheet> {
  final bodyController = TextEditingController(text: 'أرغب في معرفة تفاصيل المنتج والتوفر الحالي.');
  final phoneController = TextEditingController();
  int quantity = 1;
  HandoffOption option = HandoffOption.contact;
  bool saving = false;

  @override
  void dispose() {
    bodyController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: AssalSpacing.xl, right: AssalSpacing.xl, top: AssalSpacing.xl, bottom: MediaQuery.viewInsetsOf(context).bottom + AssalSpacing.xl),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('طلب تواصل مع ${widget.store.nameAr}', style: AssalTypography.heading2.copyWith(color: AssalColors.deepBrown)),
          const SizedBox(height: AssalSpacing.sm),
          Text(widget.product.nameAr, style: AssalTypography.subtitle),
          const SizedBox(height: AssalSpacing.lg),
          TextField(controller: bodyController, maxLines: 3, decoration: const InputDecoration(labelText: 'رسالتك', hintText: 'اكتب ما تريد معرفته')),
          const SizedBox(height: AssalSpacing.md),
          TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم للتواصل (اختياري)')),
          const SizedBox(height: AssalSpacing.md),
          DropdownButtonFormField<HandoffOption>(initialValue: option, decoration: const InputDecoration(labelText: 'طريقة التسليم المفضلة'), items: HandoffOption.values.map<DropdownMenuItem<HandoffOption>>((item) => DropdownMenuItem(value: item, child: Text(item.labelAr))).toList(), onChanged: (value) { if (value != null) setState(() => option = value); }),
          const SizedBox(height: AssalSpacing.md),
          Row(children: [
            const Text('الكمية'),
            IconButton(onPressed: () => setState(() { if (quantity > 1) quantity--; }), icon: const Icon(Icons.remove_circle_outline)),
            Text('$quantity', style: AssalTypography.title),
            IconButton(onPressed: () => setState(() => quantity++), icon: const Icon(Icons.add_circle_outline)),
          ]),
          const SizedBox(height: AssalSpacing.lg),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: saving ? null : _submit, child: saving ? const CircularProgressIndicator() : const Text('حفظ وإرسال الطلب'))),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    final body = bodyController.text.trim();
    if (body.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب رسالة أوضح للتاجر.')));
      return;
    }
    setState(() => saving = true);
    final result = await widget.repository.createRequest('demo-customer', AssalRequestDraft(storeId: widget.store.id, productId: widget.product.id, subject: 'استفسار عن ${widget.product.nameAr}', body: body, quantity: quantity, phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(), handoffOption: option));
    if (!mounted) return;
    setState(() => saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result is AssalData<AssalRequestSummary> ? 'تم حفظ الطلب ويمكنك متابعته من ملفك.' : 'تعذر حفظ الطلب، حاول مرة أخرى.')));
  }
}

