from pathlib import Path

path = Path('/home/ubuntu/suq_aleasal/apps/mobile_flutter/lib/features/customer/customer_experience.dart')
text = path.read_text(encoding='utf-8')

def replace_between(source: str, start: str, end: str, replacement: str) -> str:
    start_index = source.index(start)
    end_index = source.index(end, start_index)
    return source[:start_index] + replacement + source[end_index:]

request = r'''class _RequestSheetState extends State<RequestSheet> {
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
          DropdownButtonFormField<HandoffOption>(value: option, decoration: const InputDecoration(labelText: 'طريقة التسليم المفضلة'), items: HandoffOption.values.map<DropdownMenuItem<HandoffOption>>((item) => DropdownMenuItem(value: item, child: Text(item.labelAr))).toList(), onChanged: (value) { if (value != null) setState(() => option = value); }),
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

'''

comments = r'''class _CommentsSectionState extends State<_CommentsSection> {
  late Future<AssalLoadState<List<AssalCommentSummary>>> future;
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    future = widget.repository.listComments(widget.targetId);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'التعليقات'),
      FutureBuilder<AssalLoadState<List<AssalCommentSummary>>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return AssalStateView<List<AssalCommentSummary>>(
            state: snapshot.data!,
            builder: (comments) => Column(
              children: comments.map<Widget>((comment) => Card(child: ListTile(title: Text(comment.authorName), subtitle: Text(comment.body)))).toList(),
            ),
          );
        },
      ),
      const SizedBox(height: AssalSpacing.sm),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: TextField(controller: controller, maxLines: 2, decoration: const InputDecoration(hintText: 'اكتب تعليقًا مفيدًا'))),
        IconButton(onPressed: _add, icon: const Icon(Icons.send_rounded), tooltip: 'إرسال التعليق'),
      ]),
    ]);
  }

  Future<void> _add() async {
    final body = controller.text.trim();
    if (body.isEmpty) return;
    final allowed = await requireAuth(context, widget.repository);
    if (!allowed || !mounted) return;
    await widget.repository.createComment('demo-customer', 'عميل عسلكم', widget.targetId, body);
    controller.clear();
    setState(() => future = widget.repository.listComments(widget.targetId));
  }
}

'''

guest_start = "  Widget _guest(BuildContext context) =>"
guest_end = "  Widget _authenticated(BuildContext context, AssalSession session) =>"
guest = r'''  Widget _guest(BuildContext context) {
    return Card(
      color: AssalColors.cream,
      child: Padding(
        padding: const EdgeInsets.all(AssalSpacing.xl),
        child: Column(children: [
          const CircleAvatar(radius: 34, backgroundColor: AssalColors.honeyLight, child: Icon(Icons.person_outline, size: 36, color: AssalColors.primaryDark)),
          const SizedBox(height: AssalSpacing.md),
          Text('تصفح كزائر', style: AssalTypography.heading2.copyWith(color: AssalColors.deepBrown)),
          const SizedBox(height: AssalSpacing.sm),
          const Text('احفظ ما يعجبك وأرسل طلباتك عند إنشاء حساب مجاني.'),
          const SizedBox(height: AssalSpacing.lg),
          FilledButton(onPressed: () => openAuth(context, repository), child: const Text('تسجيل الدخول أو إنشاء حساب')),
        ]),
      ),
    );
  }

'''

text = replace_between(text, 'class _RequestSheetState extends State<RequestSheet> {', 'class _ReviewsSection', request)
text = replace_between(text, 'class _CommentsSectionState extends State<_CommentsSection> {', 'class AuthScreen', comments)
text = replace_between(text, guest_start, guest_end, guest)
path.write_text(text, encoding='utf-8')
print('remaining customer sections fixed')
