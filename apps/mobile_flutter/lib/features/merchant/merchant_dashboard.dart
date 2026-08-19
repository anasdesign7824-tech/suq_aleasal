import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_design/assal_tokens.dart';
import '../../core/assal_widgets.dart';
import 'merchant_product_editor.dart';
import 'store_verification_screen.dart';

class MerchantDashboard extends StatefulWidget {
  const MerchantDashboard({super.key, required this.repository});

  final AssalRepository repository;

  @override
  State<MerchantDashboard> createState() => _MerchantDashboardState();
}

class _MerchantDashboardState extends State<MerchantDashboard> {
  late Future<AssalLoadState<AssalMerchantWorkspaceSummary?>> workspaceFuture;
  late Future<AssalLoadState<List<AssalProductSummary>>> productsFuture;
  late Future<AssalLoadState<List<AssalRequestSummary>>> requestsFuture;
  late Future<AssalLoadState<List<AssalCommentSummary>>> commentsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    workspaceFuture = _loadWorkspace();
    productsFuture = _loadProducts();
    requestsFuture = _loadRequests();
    commentsFuture = _loadComments();
  }

  Future<AssalLoadState<AssalMerchantWorkspaceSummary?>>
      _loadWorkspace() async {
    final session = await widget.repository.getSession();
    if (!session.isAuthenticated || session.user == null) {
      return const AssalError(
        'سجّل الدخول لعرض مساحة التاجر.',
        code: 'merchant_auth_required',
      );
    }
    return widget.repository.loadMerchantWorkspace(session.user!.id);
  }

  Future<AssalLoadState<List<AssalProductSummary>>> _loadProducts() async {
    final session = await widget.repository.getSession();
    if (!session.isAuthenticated || session.user == null) {
      return const AssalError(
        'سجّل الدخول لعرض منتجات المتجر.',
        code: 'merchant_auth_required',
      );
    }
    return widget.repository.listMerchantProducts(session.user!.id);
  }

  Future<AssalLoadState<List<AssalRequestSummary>>> _loadRequests() async {
    final session = await widget.repository.getSession();
    if (!session.isAuthenticated || session.user == null) {
      return const AssalError(
        'سجّل الدخول لعرض طلبات المتجر.',
        code: 'merchant_auth_required',
      );
    }
    return widget.repository.listMerchantRequests(session.user!.id);
  }

  Future<AssalLoadState<List<AssalCommentSummary>>> _loadComments() async {
    final session = await widget.repository.getSession();
    if (!session.isAuthenticated || session.user == null) {
      return const AssalError(
        'سجّل الدخول لعرض تعليقات المتجر.',
        code: 'merchant_auth_required',
      );
    }
    final productsState =
        await widget.repository.listMerchantProducts(session.user!.id);
    if (productsState is AssalError<List<AssalProductSummary>>) {
      return AssalError(productsState.messageAr, code: productsState.code);
    }
    final products = productsState is AssalData<List<AssalProductSummary>>
        ? productsState.value
        : const <AssalProductSummary>[];
    if (products.isEmpty) return const AssalData(<AssalCommentSummary>[]);
    final states = await Future.wait(
        products.map((product) => widget.repository.listComments(product.id)));
    final comments = <AssalCommentSummary>[];
    for (final state in states) {
      if (state is AssalData<List<AssalCommentSummary>>) {
        comments.addAll(state.value);
      }
    }
    return AssalData(comments);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AssalAppBar(title: 'لوحة التاجر'),
        body: FutureBuilder<AssalLoadState<AssalMerchantWorkspaceSummary?>>(
          future: workspaceFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const AssalGlassLoading();
            final state = snapshot.data!;
            if (state is AssalError<AssalMerchantWorkspaceSummary?>) {
              return AssalMessageCard(
                icon: Icons.storefront_outlined,
                message: state.messageAr,
              );
            }
            final workspace = state is AssalData<AssalMerchantWorkspaceSummary?>
                ? state.value
                : null;
            if (workspace == null) {
              return const AssalMessageCard(
                icon: Icons.storefront_outlined,
                message:
                    'لم تُفتح مساحة متجر لهذا الحساب بعد. ابدأ من شاشة «كن تاجرًا».',
              );
            }
            return _content(workspace);
          },
        ),
      );

  Widget _content(AssalMerchantWorkspaceSummary workspace) {
    final store = workspace.store;
    final publicState = workspace.canPublish
        ? 'مفعّل ويظهر للعملاء عند نشر المنتجات'
        : 'معلّق حتى تفعيل الإدارة؛ يمكنك الإعداد والمعاينة الآن';
    return DefaultTabController(
      length: 6,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AssalSpacing.lg,
              AssalSpacing.lg,
              AssalSpacing.lg,
              AssalSpacing.sm,
            ),
            child: Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AssalColors.honeyLight,
                  child: Icon(
                    workspace.canPublish
                        ? Icons.verified_outlined
                        : Icons.pending_actions_outlined,
                    color: AssalColors.primaryDark,
                  ),
                ),
                title:
                    Text(store.nameAr.isEmpty ? 'مساحة المتجر' : store.nameAr),
                subtitle: Text(publicState),
                trailing: IconButton(
                  tooltip: 'تحديث',
                  onPressed: () => setState(_refresh),
                  icon: const Icon(Icons.refresh_outlined),
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AssalSpacing.lg),
            decoration: BoxDecoration(
              gradient: AssalColors.darkGradient,
              borderRadius: BorderRadius.circular(AssalRadius.medium),
            ),
            child: TabBar(
              isScrollable: true,
              padding: const EdgeInsets.symmetric(horizontal: AssalSpacing.xs),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: .72),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AssalColors.primaryDark,
                borderRadius: BorderRadius.circular(AssalRadius.small),
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'نظرة عامة'),
                Tab(text: 'المنتجات'),
                Tab(text: 'المسودات والمراجعة'),
                Tab(text: 'الإحصاءات'),
                Tab(text: 'التعليقات'),
                Tab(text: 'الطلبات'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _overview(workspace),
                _products(workspace),
                _drafts(workspace),
                _statistics(workspace),
                _comments(),
                _requests(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overview(AssalMerchantWorkspaceSummary workspace) {
    final store = workspace.store;
    return ListView(
      padding: const EdgeInsets.all(AssalSpacing.lg),
      children: [
        Text(
          'مساحة متجرك جاهزة للتحرير',
          style:
              AssalTypography.heading2.copyWith(color: AssalColors.deepBrown),
        ),
        const SizedBox(height: AssalSpacing.sm),
        Text(
          workspace.canPublish
              ? 'متجرك مفعّل. يمكنك إدارة بياناته ومنتجاته وتفاعل العملاء.'
              : 'أكمل البيانات وأضف المنتجات. ستظل مخفية عن العملاء حتى تفعيل الإدارة.',
          style:
              AssalTypography.body.copyWith(color: AssalColors.textSecondary),
        ),
        const SizedBox(height: AssalSpacing.lg),
        _infoCard(Icons.storefront_outlined, 'حالة المتجر', store.status.labelAr),
        _infoCard(
          Icons.verified_user_outlined,
          'توثيق Pro',
          _verificationLabel(workspace.verificationStatus),
        ),
        _infoCard(Icons.location_on_outlined, 'الموقع',
            store.regionNameAr ?? 'لم يُحدد بعد'),
        _infoCard(
            Icons.description_outlined,
            'الوصف',
            store.description?.isNotEmpty == true
                ? store.description!
                : 'لم يُضف وصف بعد'),
        const SizedBox(height: AssalSpacing.lg),
        const AssalMessageCard(
          icon: Icons.visibility_outlined,
          message:
              'ستستخدم المعاينة نفس مكونات عرض العميل. الإعداد هنا لا ينشر البيانات قبل التفعيل.',
        ),
        const SizedBox(height: AssalSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MerchantStoreEditorScreen(
                      repository: widget.repository,
                      workspace: workspace,
                    ),
                  ),
                );
                if (mounted) setState(_refresh);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('تعديل بيانات المتجر والصور'),
            ),
          ),
          const SizedBox(height: AssalSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StoreVerificationScreen(
                    repository: widget.repository,
                    storeId: store.id,
                  ),
                ),
              ),
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('طلب أو متابعة توثيق Pro'),
            ),
          ),
      ],
    );
  }

  Widget _products(AssalMerchantWorkspaceSummary workspace) =>
      FutureBuilder<AssalLoadState<List<AssalProductSummary>>>(
        future: productsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const AssalGlassLoading();
          final state = snapshot.data!;
          if (state is AssalError<List<AssalProductSummary>>) {
            return AssalMessageCard(
              icon: Icons.inventory_2_outlined,
              message: state.messageAr,
            );
          }
          final products = state is AssalData<List<AssalProductSummary>>
              ? state.value
              : const <AssalProductSummary>[];
          return ListView(
            padding: const EdgeInsets.all(AssalSpacing.lg),
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openProductEditor(workspace.store.id),
                  icon: const Icon(Icons.add_box_outlined),
                  label: const Text('إضافة منتج ومعاينته'),
                ),
              ),
              const SizedBox(height: AssalSpacing.md),
              if (products.isEmpty)
                const AssalMessageCard(
                  icon: Icons.inventory_2_outlined,
                  message:
                      'لا توجد منتجات بعد. أضف أول منتج؛ سيبقى معلقًا حتى تفعيل المتجر.',
                )
              else
                ...products.map(_productTile),
            ],
          );
        },
      );

  Widget _drafts(AssalMerchantWorkspaceSummary workspace) =>
      FutureBuilder<AssalLoadState<List<AssalProductSummary>>>(
        future: productsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const AssalGlassLoading();
          final state = snapshot.data!;
          if (state is AssalError<List<AssalProductSummary>>) {
            return AssalMessageCard(
                icon: Icons.pending_actions_outlined, message: state.messageAr);
          }
          final products = state is AssalData<List<AssalProductSummary>>
              ? state.value
                  .where((item) => item.status != ProductStatus.active)
                  .toList()
              : const <AssalProductSummary>[];
          if (products.isEmpty) {
            return const AssalMessageCard(
              icon: Icons.fact_check_outlined,
              message: 'لا توجد مسودات أو منتجات معلقة للمراجعة.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AssalSpacing.lg),
            children: products.map(_productTile).toList(),
          );
        },
      );

  Widget _comments() =>
      FutureBuilder<AssalLoadState<List<AssalCommentSummary>>>(
        future: commentsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const AssalGlassLoading();
          final state = snapshot.data!;
          if (state is AssalError<List<AssalCommentSummary>>) {
            return AssalMessageCard(
                icon: Icons.forum_outlined, message: state.messageAr);
          }
          final comments = state is AssalData<List<AssalCommentSummary>>
              ? state.value
              : const <AssalCommentSummary>[];
          if (comments.isEmpty) {
            return const AssalMessageCard(
              icon: Icons.forum_outlined,
              message: 'لا توجد تعليقات على منتجاتك بعد.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AssalSpacing.lg),
            itemCount: comments.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AssalSpacing.sm),
            itemBuilder: (_, index) {
              final comment = comments[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AssalColors.honeyLight,
                    child: Icon(Icons.person_outline,
                        color: AssalColors.primaryDark),
                  ),
                  title: Text(comment.authorName),
                  subtitle: Text(comment.body),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      );

  Widget _requests() =>
      FutureBuilder<AssalLoadState<List<AssalRequestSummary>>>(
        future: requestsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const AssalGlassLoading();
          final state = snapshot.data!;
          if (state is AssalError<List<AssalRequestSummary>>) {
            return AssalMessageCard(
                icon: Icons.assignment_outlined, message: state.messageAr);
          }
          final requests = state is AssalData<List<AssalRequestSummary>>
              ? state.value
              : const <AssalRequestSummary>[];
          if (requests.isEmpty) {
            return const AssalMessageCard(
              icon: Icons.assignment_outlined,
              message: 'لا توجد طلبات تواصل لهذا المتجر بعد.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AssalSpacing.lg),
            itemCount: requests.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AssalSpacing.sm),
            itemBuilder: (_, index) {
              final request = requests[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.assignment_outlined,
                      color: AssalColors.primaryDark),
                  title: Text(request.subject),
                  subtitle: Text(
                    '${request.status.name} · ${request.body ?? 'بدون تفاصيل'}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      );

  Widget _statistics(AssalMerchantWorkspaceSummary workspace) {
    final store = workspace.store;
    return ListView(
      padding: const EdgeInsets.all(AssalSpacing.lg),
      children: [
        _metricCard('المشاهدات', 'تُحسب من أحداث فتح المنتج بعد أول نشر.'),
        _metricCard('الإعجابات', '${store.followersCount} متابع للمتجر'),
        _metricCard('المراجعات', '${store.reviewCount} مراجعة'),
        _metricCard('سنوات الخبرة', '${store.yearsExperience} سنوات'),
        const SizedBox(height: AssalSpacing.md),
        const AssalMessageCard(
          icon: Icons.analytics_outlined,
          message:
              'تظهر الأرقام المتاحة من Production فقط، ولا يتم اختراع أرقام عند فراغ الجداول.',
        ),
      ],
    );
  }

  Widget _infoCard(IconData icon, String title, String value) => Card(
        child: ListTile(
          leading: Icon(icon, color: AssalColors.primaryDark),
          title: Text(title),
          subtitle: Text(value),
        ),
      );

  Widget _metricCard(String title, String value) => Card(
        child: ListTile(
          leading: const Icon(Icons.insights_outlined,
              color: AssalColors.primaryDark),
          title: Text(title),
          subtitle: Text(value),
        ),
      );

  Widget _productTile(AssalProductSummary product) => Card(
        child: ListTile(
          leading: const Icon(Icons.inventory_2_outlined,
              color: AssalColors.primaryDark),
          title: Text(product.nameAr),
          subtitle: Text(_productStatusLabel(product.status)),
          trailing: Wrap(
            spacing: 0,
            children: [
              IconButton(
                tooltip: 'تعديل',
                onPressed: () => _openProductEditor(
                  product.storeId,
                  product: product,
                ),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'حذف',
                onPressed: () => _deleteProduct(product),
                icon:
                    const Icon(Icons.delete_outline, color: AssalColors.error),
              ),
            ],
          ),
        ),
      );

  Future<void> _openProductEditor(
    String storeId, {
    AssalProductSummary? product,
  }) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MerchantProductEditorScreen(
          repository: widget.repository,
          storeId: storeId,
          product: product,
        ),
      ),
    );
    if (!mounted || changed != true) return;
    setState(() {
      productsFuture = _loadProducts();
      commentsFuture = _loadComments();
    });
  }

  Future<void> _deleteProduct(AssalProductSummary product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف المنتج؟'),
        content: const Text(
            'سيُحذف المنتج من مساحة التاجر. لا يمكن التراجع عن العملية.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final session = await widget.repository.getSession();
    if (!session.isAuthenticated || session.user == null) return;
    final state = await widget.repository
        .deleteMerchantProduct(session.user!.id, product.id);
    if (!mounted) return;
    setState(() => productsFuture = _loadProducts());
    if (state is AssalError<void>) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(state.messageAr)));
    }
  }

  String _verificationLabel(String status) => switch (status) {
        'approved' || 'verified' => 'موثق Pro',
        'draft' => 'مسودة طلب التوثيق',
        'payment_pending' => 'بانتظار إكمال الدفع',
        'submitted' => 'أُرسل للمراجعة',
        'under_review' => 'قيد المراجعة',
        'needs_more_info' => 'يلزم استكمال البيانات',
        'rejected' => 'لم تتم الموافقة',
        'expired' => 'انتهى التوثيق',
        'revoked' => 'سُحب التوثيق',
        _ => 'لم يُطلب توثيق Pro',
      };

  String _productStatusLabel(ProductStatus status) => switch (status) {
        ProductStatus.draft => 'مسودة محفوظة',
        ProductStatus.pending => 'معلّق حتى التفعيل أو المراجعة',
        ProductStatus.active => 'منشور للعملاء',
        ProductStatus.paused => 'موقوف مؤقتًا',
        ProductStatus.rejected => 'مرفوض ويحتاج تعديلًا',
      };
}

class MerchantStoreEditorScreen extends StatefulWidget {
  const MerchantStoreEditorScreen({
    super.key,
    required this.repository,
    required this.workspace,
  });

  final AssalRepository repository;
  final AssalMerchantWorkspaceSummary workspace;

  @override
  State<MerchantStoreEditorScreen> createState() =>
      _MerchantStoreEditorScreenState();
}

class _MerchantStoreEditorScreenState extends State<MerchantStoreEditorScreen> {
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController phoneController;
  String? regionId;
  String? logoUrl;
  String? coverUrl;
  final galleryUrls = <String>[];
  bool saving = false;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    final store = widget.workspace.store;
    nameController = TextEditingController(text: store.nameAr);
    descriptionController =
        TextEditingController(text: store.description ?? '');
    phoneController = TextEditingController(text: store.contactPhone ?? '');
    regionId = store.regionId;
    logoUrl = store.logoUrl;
    coverUrl = store.coverUrl;
    galleryUrls.addAll(store.galleryUrls);
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  String _extension(XFile file) {
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'png';
    if (name.endsWith('.webp')) return 'webp';
    return 'jpg';
  }

  Future<void> _pickBrandImage({required bool cover}) async {
    final session = await widget.repository.getSession();
    if (!session.isAuthenticated || session.user == null) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      imageQuality: 88,
    );
    if (picked == null) return;
    if (mounted) setState(() => uploading = true);
    final result = await widget.repository.uploadMerchantImage(
      session.user!.id,
      cover ? 'cover' : 'logo',
      await picked.readAsBytes(),
      _extension(picked),
    );
    if (!mounted) return;
    setState(() => uploading = false);
    if (result is AssalData<String>) {
      setState(() {
        if (cover) {
          coverUrl = result.value;
        } else {
          logoUrl = result.value;
        }
      });
    } else if (result is AssalError<String>) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.messageAr)));
    }
  }

  Future<void> _pickGalleryImage() async {
    final session = await widget.repository.getSession();
    if (!session.isAuthenticated || session.user == null) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      imageQuality: 88,
    );
    if (picked == null) return;
    if (mounted) setState(() => uploading = true);
    final result = await widget.repository.uploadStoreGalleryImage(
      session.user!.id,
      widget.workspace.store.id,
      await picked.readAsBytes(),
      _extension(picked),
    );
    if (!mounted) return;
    setState(() => uploading = false);
    if (result is AssalData<String>) {
      setState(() => galleryUrls.insert(0, result.value));
    } else if (result is AssalError<String>) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.messageAr)));
    }
  }

  Future<void> _save() async {
    final session = await widget.repository.getSession();
    if (!session.isAuthenticated || session.user == null) return;
    setState(() => saving = true);
    final result = await widget.repository.updateMerchantWorkspace(
      session.user!.id,
      widget.workspace.store.id,
      AssalMerchantWorkspaceDraft(
        businessName: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        phone: phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        logoUrl: logoUrl,
        coverUrl: coverUrl,
        regionId: regionId,
      ),
    );
    if (!mounted) return;
    setState(() => saving = false);
    if (result is AssalData<void>) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ بيانات المتجر.')),
      );
      Navigator.of(context).pop();
    } else if (result is AssalError<void>) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.messageAr)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AssalAppBar(title: 'تعديل مساحة المتجر'),
        body: ListView(
          padding: const EdgeInsets.all(AssalSpacing.lg),
          children: [
            AssalImageUploadSlot(
              label: 'غلاف المتجر',
              icon: Icons.photo_size_select_actual_outlined,
              imageUrl: coverUrl,
              bytes: null,
              onPick: saving || uploading
                  ? null
                  : () => _pickBrandImage(cover: true),
              height: 160,
            ),
            const SizedBox(height: AssalSpacing.lg),
            AssalImageUploadSlot(
              label: 'شعار المتجر',
              icon: Icons.storefront_outlined,
              imageUrl: logoUrl,
              bytes: null,
              onPick: saving || uploading
                  ? null
                  : () => _pickBrandImage(cover: false),
              height: 150,
            ),
            const SizedBox(height: AssalSpacing.lg),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المتجر',
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
            ),
            const SizedBox(height: AssalSpacing.md),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'وصف المتجر',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: AssalSpacing.md),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم التواصل',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: AssalSpacing.md),
            FutureBuilder<AssalLoadState<List<AssalRegion>>>(
              future: widget.repository.listRegions(),
              builder: (context, snapshot) {
                final state = snapshot.data;
                final regions = state is AssalData<List<AssalRegion>>
                    ? state.value
                    : const <AssalRegion>[];
                return DropdownButtonFormField<String>(
                  initialValue: regions.any((region) => region.id == regionId)
                      ? regionId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'المحافظة أو المنطقة',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  items: regions
                      .map(
                        (region) => DropdownMenuItem<String>(
                          value: region.id,
                          child: Text(region.nameAr),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: saving
                      ? null
                      : (value) => setState(() => regionId = value),
                  hint: const Text('اختر المنطقة'),
                );
              },
            ),
            const SizedBox(height: AssalSpacing.lg),
            const Text('صور المعرض', style: AssalTypography.subtitle),
            const SizedBox(height: AssalSpacing.sm),
            if (galleryUrls.isEmpty)
              const AssalMessageCard(
                icon: Icons.photo_library_outlined,
                message: 'لا توجد صور في معرض المتجر بعد.',
              )
            else
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: galleryUrls.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AssalSpacing.sm),
                  itemBuilder: (_, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(AssalRadius.medium),
                    child: Image.network(
                      galleryUrls[index],
                      width: 132,
                      height: 104,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AssalSpacing.sm),
            OutlinedButton.icon(
              onPressed: saving || uploading ? null : _pickGalleryImage,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('إضافة صورة للمعرض'),
            ),
            const SizedBox(height: AssalSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: saving || uploading ? null : _save,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(saving ? 'جارٍ الحفظ...' : 'حفظ تغييرات المتجر'),
              ),
            ),
          ],
        ),
      );
}
