import 'package:flutter/material.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_design/assal_tokens.dart';

import '../../core/assal_widgets.dart';

class SupportCenterScreen extends StatelessWidget {
  const SupportCenterScreen({
    super.key,
    required this.repository,
    this.storeId,
    this.designRequestsRemaining = 0,
  });

  final AssalRepository repository;
  final String? storeId;
  final int designRequestsRemaining;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AssalAppBar(title: 'المساعدة والدعم'),
        body: ListView(
          padding: const EdgeInsets.all(AssalSpacing.lg),
          children: [
            const AssalBrandMark(showName: true),
            const SizedBox(height: AssalSpacing.lg),
            const SectionHeader(title: 'مركز المساعدة'),
            const SizedBox(height: AssalSpacing.sm),
            _faq(
              'كيف أتابع المتجر أو أحفظ المنتج؟',
              'افتح بطاقة المتجر أو المنتج واضغط زر المتابعة أو الحفظ. ستظهر العناصر في تبويبها المنفصل داخل المحفوظات والمتابعات.',
            ),
            _faq(
              'متى يظهر المتجر أو المنتج للعملاء؟',
              'يمكن للتاجر تجهيز متجره ومنتجاته مباشرة، لكن الظهور العام يتبع حالة التفعيل والمراجعة في لوحة الإدارة.',
            ),
            _faq(
              'ماذا أفعل إذا لم تتزامن البيانات؟',
              'استخدم زر إعادة المحاولة في الحالة الظاهرة، وتأكد من الاتصال. لا تُكرر العملية إذا كانت قيد الإرسال؛ ستظهر نتيجة النجاح أو الفشل بوضوح.',
            ),
            const SizedBox(height: AssalSpacing.lg),
            const SectionHeader(title: 'التواصل مع الدعم'),
            const SizedBox(height: AssalSpacing.sm),
            AssalActionTile(
              icon: Icons.support_agent_outlined,
              title: 'الدعم الفني',
              subtitle: 'تواصل مع فريق عسلكم عبر بريد الدعم الرسمي',
              onTap: () => _showSupportContact(context),
            ),
            const SizedBox(height: AssalSpacing.sm),
            AssalActionTile(
              icon: Icons.help_outline,
              title: 'المساعدة العامة',
              subtitle: 'شرح مختصر للتصفح والمتابعة والشراء وإدارة المتجر',
              onTap: () => _showHelpSummary(context),
            ),
            if (storeId != null) ...[
              const SizedBox(height: AssalSpacing.lg),
              const SectionHeader(title: 'خدمات الهوية والتصميم'),
              const SizedBox(height: AssalSpacing.sm),
              AssalActionTile(
                icon: Icons.design_services_outlined,
                title: 'طلب تصميم إضافي',
                subtitle: designRequestsRemaining > 0
                    ? 'متاح ضمن خطتك — المتبقي: $designRequestsRemaining'
                    : 'هذه الميزة تحتاج إلى خطة تتضمن خدمة التصميم',
                trailing: designRequestsRemaining > 0
                    ? const AssalPremiumBadge(label: 'ميزة مدفوعة', compact: true)
                    : const Icon(Icons.lock_outline),
                onTap: designRequestsRemaining > 0
                    ? () async {
                        await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => DesignRequestScreen(
                            repository: repository,
                            storeId: storeId!,
                          ),
                        ));
                      }
                    : () => _showUpgradeMessage(context),
              ),
            ],
          ],
        ),
      );

  Widget _faq(String title, String body) => Card(
        margin: const EdgeInsets.only(bottom: AssalSpacing.sm),
        child: ExpansionTile(
          leading: const Icon(Icons.question_mark_outlined,
              color: AssalColors.primaryDark),
          title: Text(title),
          childrenPadding: const EdgeInsets.fromLTRB(
            AssalSpacing.lg,
            0,
            AssalSpacing.lg,
            AssalSpacing.lg,
          ),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                body,
                style: AssalTypography.body.copyWith(
                  color: AssalColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );

  void _showSupportContact(BuildContext context) => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('الدعم الفني'),
          content: const SelectableText(
            'للمساعدة في الحساب أو المزامنة أو المتجر، تواصل مع خدمة دعم عسلكم عبر:\n\ninfo.assalkom@gmail.com',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );

  void _showHelpSummary(BuildContext context) => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('المساعدة العامة'),
          content: const Text(
            'تصفح المنتجات والمتاجر من الاكتشاف، واحفظ ما يعجبك، وتابع المتاجر المفضلة، ثم افتح المراسلات من صفحة الحساب. التاجر يدير متجره ومنتجاته من نفس قوالب العرض مع أدوات التحرير الخاصة به.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('فهمت'),
            ),
          ],
        ),
      );

  void _showUpgradeMessage(BuildContext context) => ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(
        content: Text('خدمة التصميم الإضافية متاحة في الخطط التي تتضمنها.'),
      ));
}

class DesignRequestScreen extends StatefulWidget {
  const DesignRequestScreen({
    super.key,
    required this.repository,
    required this.storeId,
  });

  final AssalRepository repository;
  final String storeId;

  @override
  State<DesignRequestScreen> createState() => _DesignRequestScreenState();
}

class _DesignRequestScreenState extends State<DesignRequestScreen> {
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController brandNameController;
  late final TextEditingController colorsController;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    descriptionController = TextEditingController();
    brandNameController = TextEditingController();
    colorsController = TextEditingController();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    brandNameController.dispose();
    colorsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AssalAppBar(title: 'طلب تصميم إضافي'),
        body: ListView(
          padding: const EdgeInsets.all(AssalSpacing.lg),
          children: [
            const AssalPremiumBadge(label: 'خدمة تصميم ضمن الخطة'),
            const SizedBox(height: AssalSpacing.md),
            const Text(
              'اكتب تفاصيل الهوية أو تصميم المنتج المطلوب، وسيصل الطلب للمراجعة والتنفيذ.',
              style: AssalTypography.bodyLarge,
            ),
            const SizedBox(height: AssalSpacing.lg),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'عنوان الطلب',
                prefixIcon: Icon(Icons.title_outlined),
              ),
            ),
            const SizedBox(height: AssalSpacing.md),
            TextField(
              controller: descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'تفاصيل التصميم',
                hintText: 'صف الشعار أو العبوة أو الهوية المطلوبة',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: AssalSpacing.md),
            TextField(
              controller: brandNameController,
              decoration: const InputDecoration(
                labelText: 'اسم العلامة التجارية (اختياري)',
                prefixIcon: Icon(Icons.business_outlined),
              ),
            ),
            const SizedBox(height: AssalSpacing.md),
            TextField(
              controller: colorsController,
              decoration: const InputDecoration(
                labelText: 'الألوان المفضلة (اختياري)',
                hintText: 'مثال: ذهبي، كريمي، بني',
                prefixIcon: Icon(Icons.palette_outlined),
              ),
            ),
            const SizedBox(height: AssalSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: submitting ? null : _submit,
                icon: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(submitting ? 'جارٍ إرسال الطلب...' : 'إرسال طلب التصميم'),
              ),
            ),
          ],
        ),
      );

  Future<void> _submit() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    if (title.length < 2 || description.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('أدخل عنوانًا واضحًا وتفاصيل لا تقل عن عشرة أحرف.'),
      ));
      return;
    }
    final session = await widget.repository.getSession();
    if (!mounted) return;
    if (session.isUnavailable) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(session.errorMessageAr ?? 'تعذر مزامنة الحساب الآن.'),
      ));
      return;
    }
    if (!session.isAuthenticated || session.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('سجّل الدخول قبل إرسال طلب التصميم.'),
      ));
      return;
    }
    setState(() => submitting = true);
    final result = await widget.repository.createDesignRequest(
      session.user!.id,
      widget.storeId,
      AssalDesignRequestDraft(
        title: title,
        description: description,
        brandName: brandNameController.text.trim().isEmpty
            ? null
            : brandNameController.text.trim(),
        brandColors: colorsController.text
            .split(RegExp(r'[,،]'))
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false),
      ),
    );
    if (!mounted) return;
    setState(() => submitting = false);
    if (result is AssalData<AssalDesignRequest>) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تم إرسال طلب التصميم، وسيظهر لك بعد مراجعته.'),
      ));
      Navigator.of(context).pop(true);
    } else if (result is AssalError<AssalDesignRequest>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.messageAr)),
      );
    }
  }
}
