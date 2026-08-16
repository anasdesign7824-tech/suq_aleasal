from pathlib import Path

path = Path('/home/ubuntu/suq_aleasal/apps/mobile_flutter/lib/features/customer/customer_experience.dart')
text = path.read_text(encoding='utf-8')

def replace_between(source: str, start: str, end: str, replacement: str) -> str:
    start_index = source.index(start)
    end_index = source.index(end, start_index)
    return source[:start_index] + replacement + source[end_index:]

search = r'''class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.repository, this.initialQuery, this.initialSubcategoryId});
  final AssalRepository repository;
  final String? initialQuery;
  final String? initialSubcategoryId;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController controller = TextEditingController(text: widget.initialQuery);
  String? subcategoryId;
  int? gradeLevel;
  ProductType? productType;
  bool verifiedOnly = false;
  AssalSort sort = AssalSort.featured;
  late Future<AssalLoadState<List<AssalProductSummary>>> productsFuture;
  late Future<AssalLoadState<List<AssalStoreSummary>>> storesFuture;

  @override
  void initState() {
    super.initState();
    subcategoryId = widget.initialSubcategoryId;
    _search();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _search() {
    final query = AssalProductQuery(search: controller.text, subcategoryId: subcategoryId, gradeLevel: gradeLevel, productType: productType, verifiedStoresOnly: verifiedOnly, sort: sort);
    productsFuture = widget.repository.listProducts(query: query);
    storesFuture = widget.repository.listStores();
  }

  void _applySearch() => setState(_search);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('البحث')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AssalSpacing.lg, AssalSpacing.md, AssalSpacing.lg, 0),
          child: TextField(
            controller: controller,
            autofocus: true,
            onSubmitted: (_) => _applySearch(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'اكتب اسم المنتج أو المنطقة',
              suffixIcon: IconButton(onPressed: () { controller.clear(); _applySearch(); }, icon: const Icon(Icons.clear), tooltip: 'مسح'),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.lg, vertical: AssalSpacing.sm),
          child: Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: _showFilters, icon: const Icon(Icons.tune_rounded), label: const Text('الفلاتر'))),
            const SizedBox(width: AssalSpacing.sm),
            PopupMenuButton<AssalSort>(
              initialValue: sort,
              onSelected: (value) => setState(() { sort = value; _search(); }),
              itemBuilder: (_) => const [
                PopupMenuItem(value: AssalSort.featured, child: Text('المميزة أولًا')),
                PopupMenuItem(value: AssalSort.newest, child: Text('الأحدث')),
                PopupMenuItem(value: AssalSort.popular, child: Text('الأكثر شعبية')),
                PopupMenuItem(value: AssalSort.rating, child: Text('الأعلى تقييمًا')),
              ],
              child: const Chip(avatar: Icon(Icons.sort, size: 18), label: Text('ترتيب')),
            ),
          ]),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _applySearch(),
            child: ListView(padding: const EdgeInsets.fromLTRB(AssalSpacing.lg, 0, AssalSpacing.lg, AssalSpacing.xl), children: [
              const SectionHeader(title: 'المنتجات'),
              FutureBuilder<AssalLoadState<List<AssalProductSummary>>>(
                future: productsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
                  return AssalStateView<List<AssalProductSummary>>(
                    state: snapshot.data!,
                    onRetry: _applySearch,
                    builder: (products) => GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: AssalSpacing.md, mainAxisSpacing: AssalSpacing.md, childAspectRatio: .68),
                      itemCount: products.length,
                      itemBuilder: (_, index) => ProductCard(product: products[index], onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(repository: widget.repository, productId: products[index].id))),
                    ),
                  );
                },
              ),
              const SizedBox(height: AssalSpacing.xl),
              const SectionHeader(title: 'المتاجر'),
              FutureBuilder<AssalLoadState<List<AssalStoreSummary>>>(
                future: storesFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
                  return AssalStateView<List<AssalStoreSummary>>(
                    state: snapshot.data!,
                    builder: (stores) => Column(children: stores.map<Widget>((store) => StoreCard(store: store, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoreProfileScreen(repository: widget.repository, storeId: store.id)))).toList()),
                  );
                },
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Future<void> _showFilters() async {
    var draftGrade = gradeLevel;
    var draftType = productType;
    var draftVerified = verifiedOnly;
    final typeItems = <DropdownMenuItem<ProductType?>>[
      const DropdownMenuItem<ProductType?>(value: null, child: Text('كل الأنواع')),
      ...ProductType.values.map<DropdownMenuItem<ProductType?>>((type) => DropdownMenuItem<ProductType?>(value: type, child: Text(_productTypeLabel(type)))),
    ];
    final gradeItems = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(value: null, child: Text('كل الدرجات')),
      ...[1, 2, 3, 4].map<DropdownMenuItem<int?>>((grade) => DropdownMenuItem<int?>(value: grade, child: Text('درجة $grade'))),
    ];
    final apply = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, setModalState) => Padding(
        padding: const EdgeInsets.all(AssalSpacing.xl),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('تصفية النتائج', style: AssalTypography.heading2.copyWith(color: AssalColors.deepBrown)),
          const SizedBox(height: AssalSpacing.md),
          DropdownButtonFormField<ProductType?>(value: draftType, decoration: const InputDecoration(labelText: 'نوع المنتج'), items: typeItems, onChanged: (value) => setModalState(() => draftType = value)),
          DropdownButtonFormField<int?>(value: draftGrade, decoration: const InputDecoration(labelText: 'درجة الجودة'), items: gradeItems, onChanged: (value) => setModalState(() => draftGrade = value)),
          SwitchListTile(value: draftVerified, onChanged: (value) => setModalState(() => draftVerified = value), title: const Text('المتاجر الموثقة فقط')),
          const SizedBox(height: AssalSpacing.md),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () { gradeLevel = draftGrade; productType = draftType; verifiedOnly = draftVerified; Navigator.pop(sheetContext, true); }, child: const Text('تطبيق الفلاتر'))),
        ]),
      )),
    );
    if (apply == true) _applySearch();
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
            builder: (comments) => Column(children: comments.map<Widget>((comment) => Card(child: ListTile(title: Text(comment.authorName), subtitle: Text(comment.body))).toList()),
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

profile = r'''class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.repository});
  final AssalRepository repository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AssalSession>(
      future: repository.getSession(),
      builder: (context, snapshot) {
        final session = snapshot.data ?? AssalSession.guest;
        return ListView(padding: const EdgeInsets.all(AssalSpacing.lg), children: [
          const AssalBrandMark(),
          const SizedBox(height: AssalSpacing.xl),
          session.isAuthenticated ? _authenticated(context, session) : _guest(context),
          const SizedBox(height: AssalSpacing.lg),
          Card(child: Column(children: [
            ListTile(leading: const Icon(Icons.notifications_outlined), title: const Text('الإشعارات'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NotificationsScreen(repository: repository)))),
            ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('الإعدادات'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()))),
            ListTile(leading: const Icon(Icons.help_outline), title: const Text('الدعم والتعريف بعسلكم'), trailing: const Icon(Icons.chevron_left), onTap: () => showAboutDialog(context: context, applicationName: 'عسلكم', applicationVersion: 'Demo', children: [const Text('منصة اكتشاف وتواصل للعسل اليمني من مصدره.')]))
          ])),
        ]);
      },
    );
  }

  Widget _guest(BuildContext context) => Card(color: AssalColors.cream, child: Padding(padding: const EdgeInsets.all(AssalSpacing.xl), child: Column(children: [
    const CircleAvatar(radius: 34, backgroundColor: AssalColors.honeyLight, child: Icon(Icons.person_outline, size: 36, color: AssalColors.primaryDark)),
    const SizedBox(height: AssalSpacing.md),
    Text('تصفح كزائر', style: AssalTypography.heading2.copyWith(color: AssalColors.deepBrown)),
    const SizedBox(height: AssalSpacing.sm),
    const Text('احفظ ما يعجبك وأرسل طلباتك عند إنشاء حساب مجاني.'),
    const SizedBox(height: AssalSpacing.lg),
    FilledButton(onPressed: () => openAuth(context, repository), child: const Text('تسجيل الدخول أو إنشاء حساب')),
  ]));

  Widget _authenticated(BuildContext context, AssalSession session) => Column(children: [
    CircleAvatar(radius: 38, backgroundColor: AssalColors.honeyLight, child: Text((session.user?.nameAr ?? 'ع').substring(0, 1), style: AssalTypography.heading1.copyWith(color: AssalColors.primaryDark))),
    const SizedBox(height: AssalSpacing.md),
    Text(session.user?.nameAr ?? 'عميل عسلكم', style: AssalTypography.heading2.copyWith(color: AssalColors.deepBrown)),
    Text(session.user?.email ?? '', style: AssalTypography.body.copyWith(color: AssalColors.textSecondary)),
    const SizedBox(height: AssalSpacing.lg),
    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_metric('0', 'المتابعات'), _metric('0', 'المحفوظات'), _metric('0', 'الطلبات')]),
    const SizedBox(height: AssalSpacing.lg),
    Row(children: [
      Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RequestsScreen(repository: repository))), icon: const Icon(Icons.assignment_outlined), label: const Text('طلباتي'))),
      const SizedBox(width: AssalSpacing.sm),
      Expanded(child: FilledButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BecomeMerchantScreen())), icon: const Icon(Icons.storefront_outlined), label: const Text('كن تاجرًا'))),
    ]),
    const SizedBox(height: AssalSpacing.sm),
    OutlinedButton.icon(onPressed: () async { await repository.signOut(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الخروج من Demo Mode'))); }, icon: const Icon(Icons.logout), label: const Text('تسجيل الخروج')),
  ]);

  Widget _metric(String value, String label) => Column(children: [Text(value, style: AssalTypography.heading3.copyWith(color: AssalColors.deepBrown)), Text(label, style: AssalTypography.caption.copyWith(color: AssalColors.textMuted))]);
}

'''

text = replace_between(text, 'class SearchScreen extends StatefulWidget {', 'String _productTypeLabel', search)
text = replace_between(text, 'class _CommentsSectionState extends State<_CommentsSection> {', 'class AuthScreen', comments)
text = replace_between(text, 'class ProfileScreen extends StatelessWidget {', 'class RequestsScreen', profile)
path.write_text(text, encoding='utf-8')
print('customer sections replaced')
