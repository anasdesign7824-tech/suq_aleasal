import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_design/assal_tokens.dart';

import '../../core/assal_widgets.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key, required this.repository});

  final AssalRepository repository;

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  late Future<void> _loadFuture;
  List<AssalSubscriptionPlan> allPlans = const <AssalSubscriptionPlan>[];
  List<AssalSubscriptionPlan> plans = const <AssalSubscriptionPlan>[];
  AssalSubscriptionCampaign? campaign;
  bool _isYearly = false;
  AssalLocalTransferSettings? transfer;
  AssalPaymentRequest? payment;
  String? proofPath;
  String? proofName;
  String? proofMime;
  int proofSize = 0;
  bool busy = false;
  String? message;
  final referenceController = TextEditingController();
  final senderNameController = TextEditingController();
  final senderPhoneController = TextEditingController();
  final amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  @override
  void dispose() {
    referenceController.dispose();
    senderNameController.dispose();
    senderPhoneController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final planState = await widget.repository.listSubscriptionPlans();
    final campaignState = await widget.repository.loadSubscriptionCampaign();
    final transferState = await widget.repository.loadLocalTransferSettings();
    if (planState is AssalData<List<AssalSubscriptionPlan>>) {
      allPlans = planState.value;
      plans = allPlans.where((plan) => plan.billingInterval == (_isYearly ? 'year' : 'month')).toList(growable: false);
    }
    if (campaignState is AssalData<AssalSubscriptionCampaign?>) campaign = campaignState.value;
    if (transferState is AssalData<AssalLocalTransferSettings?>) transfer = transferState.value;
    if (planState is AssalError<List<AssalSubscriptionPlan>>) message = planState.messageAr;
    if (transferState is AssalError<AssalLocalTransferSettings?>) message = transferState.messageAr;
  }

  void _setInterval(bool yearly) {
    if (_isYearly == yearly) return;
    setState(() {
      _isYearly = yearly;
      plans = allPlans.where((plan) => plan.billingInterval == (_isYearly ? 'year' : 'month')).toList(growable: false);
      payment = null;
      proofPath = null;
      proofName = null;
      message = null;
    });
  }

  Future<AssalSession?> _requireSession() async {
    final session = await widget.repository.getSession();
    if (!mounted) return null;
    if (session.isUnavailable) {
      setState(() => message = session.errorMessageAr ?? 'تعذر مزامنة الحساب الآن.');
      return null;
    }
    if (!session.isAuthenticated || session.user == null) {
      setState(() => message = 'سجّل الدخول أولًا لاختيار خطة.');
      return null;
    }
    return session;
  }

  Future<void> _choosePlan(AssalSubscriptionPlan plan) async {
    final session = await _requireSession();
    if (session == null) return;
    if (plan.priceAmount == 0) {
      setState(() => message = 'الخطة الأساسية مجانية ولا تحتاج حوالة.');
      return;
    }
    setState(() { busy = true; message = null; });
    final state = await widget.repository.createSubscriptionPaymentRequest(session.user!.id, plan.id);
    if (!mounted) return;
    setState(() {
      busy = false;
      if (state is AssalData<AssalPaymentRequest>) {
        payment = state.value;
        amountController.text = state.value.finalAmount.toStringAsFixed(2);
        message = 'تم إنشاء طلب دفع. حوّل المبلغ الظاهر ثم ارفع بيان الحوالة.';
      } else if (state is AssalError<AssalPaymentRequest>) {
        message = state.messageAr;
      }
    });
  }

  Future<void> _pickProof() async {
    if (payment == null) {
      setState(() => message = 'اختر خطة وأنشئ طلب الحوالة أولًا.');
      return;
    }
    final session = await _requireSession();
    if (session == null) return;
    final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'], withData: true);
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      setState(() => message = 'تعذر قراءة مستند الحوالة.');
      return;
    }
    final extension = (file.extension ?? 'jpg').toLowerCase();
    setState(() { busy = true; message = null; });
    final uploaded = await widget.repository.uploadPaymentProof(session.user!.id, payment!.id, bytes, extension);
    if (!mounted) return;
    if (uploaded is AssalData<String>) {
      setState(() {
        busy = false;
        proofPath = uploaded.value;
        proofName = file.name;
        proofSize = bytes.length;
        proofMime = extension == 'pdf' ? 'application/pdf' : extension == 'png' ? 'image/png' : 'image/jpeg';
        message = 'تم تجهيز المستند الخاص. أكمل بيانات الحوالة ثم أرسل للمراجعة.';
      });
    } else if (uploaded is AssalError<String>) {
      setState(() { busy = false; message = uploaded.messageAr; });
    }
  }

  Future<void> _submitProof() async {
    final current = payment;
    final path = proofPath;
    if (current == null || path == null || proofName == null || proofMime == null) {
      setState(() => message = 'اختر خطة وارفع مستند الحوالة أولًا.');
      return;
    }
    final reference = referenceController.text.trim();
    final senderName = senderNameController.text.trim();
    final senderPhone = senderPhoneController.text.trim();
    final amount = double.tryParse(amountController.text.trim());
    if (reference.length < 3 || senderName.length < 2 || senderPhone.length < 6 || amount == null || amount <= 0) {
      setState(() => message = 'أكمل مرجع العملية وبيانات المحول والمبلغ بصورة صحيحة.');
      return;
    }
    final session = await _requireSession();
    if (session == null) return;
    setState(() { busy = true; message = null; });
    final state = await widget.repository.submitPaymentProof(session.user!.id, current.id, reference, path, proofName!, proofMime!, proofSize, DateTime.now(), amount, senderName, senderPhone);
    if (!mounted) return;
    setState(() {
      busy = false;
      if (state is AssalData<AssalPaymentRequest>) {
        payment = state.value;
        message = 'تم استلام مستند الحوالة. لن تُفعل الخطة قبل مراجعة الإدارة وتأكيد المبلغ.';
      } else if (state is AssalError<AssalPaymentRequest>) {
        message = state.messageAr;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AssalAppBar(title: 'خطط التاجر والخصم'),
        body: FutureBuilder<void>(
          future: _loadFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData && snapshot.connectionState != ConnectionState.done) return const AssalGlassLoading();
            return ListView(padding: const EdgeInsets.all(AssalSpacing.lg), children: [
              _intro(),
              if (message != null) ...[const SizedBox(height: AssalSpacing.md), AssalMessageCard(icon: Icons.info_outline, message: message!)],
              const SizedBox(height: AssalSpacing.md),
              ...plans.map(_planCard),
              if (payment != null) ...[const SizedBox(height: AssalSpacing.lg), _paymentCard()],
            ]);
          },
        ),
      );

  Widget _intro() => Card(child: Padding(padding: const EdgeInsets.all(AssalSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.auto_awesome_outlined, color: AssalColors.primaryDark), const SizedBox(width: AssalSpacing.sm), Text('خطط واضحة، مزايا حقيقية', style: AssalTypography.heading3.copyWith(color: AssalColors.deepBrown))]),
        const SizedBox(height: AssalSpacing.sm),
        Text(campaign?.isActive == true ? 'خصم الافتتاح فعال حاليًا حسب كل خطة. يظهر السعر قبل الخصم وبعده، ويعاد حساب المبلغ من الخادم.' : 'اختر الخطة التي تناسب عدد متاجرك ومنتجاتك. الدفع المتاح حاليًا بالحوالة المحلية فقط.'),
        const SizedBox(height: AssalSpacing.md),
        Row(children: [Expanded(child: ChoiceChip(label: const Text('شهري'), selected: !_isYearly, onSelected: (_) => _setInterval(false))), const SizedBox(width: AssalSpacing.sm), Expanded(child: ChoiceChip(label: const Text('سنوي — عشرة أشهر'), selected: _isYearly, onSelected: (_) => _setInterval(true)))]),
        const SizedBox(height: AssalSpacing.sm),
        Text(_isYearly ? 'السعر السنوي يعادل عشرة أشهر مدفوعة، ولا يضاف عليه خصم سنوي تراكمي.' : 'يمكنك التبديل إلى السنوي للحصول على شهرين مجانيين ضمن السعر الأساسي.'),
      ])));

  Widget _planCard(AssalSubscriptionPlan plan) {
    final discount = campaign?.isActive == true && (campaign!.appliesTo.isEmpty || campaign!.appliesTo.contains('subscription')) ? (campaign!.discountByPlanCode[plan.code] ?? campaign!.discountPercent) : 0;
    final finalAmount = double.parse((plan.priceAmount * (1 - discount / 100)).toStringAsFixed(2));
    final intervalLabel = plan.billingInterval == 'year' ? 'سنة' : 'شهر';
    final isGold = plan.code == 'gold';
    return Card(child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: isGold ? [const Color(0xfffff0b8), const Color(0xffd79a2b)] : [const Color(0xfffff8e8), const Color(0xffe6b667)]), borderRadius: BorderRadius.circular(AssalRadius.medium)), padding: const EdgeInsets.all(AssalSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(plan.nameAr, style: AssalTypography.heading3.copyWith(color: AssalColors.deepBrown))), if (discount > 0) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .75), borderRadius: BorderRadius.circular(20)), child: Text('خصم ${discount.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AssalColors.primaryDark)))]),
      const SizedBox(height: AssalSpacing.sm),
      if (plan.priceAmount > 0) Text.rich(TextSpan(children: [TextSpan(text: '${plan.priceAmount.toStringAsFixed(2)} ر.س  ', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.black54)), TextSpan(text: '${finalAmount.toStringAsFixed(2)} ر.س / $intervalLabel', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AssalColors.deepBrown))])),
      if (plan.priceAmount == 0) const Text('مجانية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AssalColors.deepBrown)),
      const SizedBox(height: AssalSpacing.sm),
      if (plan.billingInterval == 'year') const Text('السعر السنوي محسوب على عشرة أشهر — شهران مجانيان ضمن السعر الأساسي', style: TextStyle(fontWeight: FontWeight.w700, color: AssalColors.primaryDark)),
      Text('${plan.storeLimit} متاجر · ${plan.productLimit} منتجًا نشطًا لكل متجر'),
      Text(plan.verificationIncluded > 0 ? 'يشمل مراجعة توثيق لعدد ${plan.verificationIncluded} من المتاجر' : 'التوثيق يطلب منفصلًا'),
      if ((plan.entitlements['design_requests_per_cycle'] as num?)?.toInt() case final designCount? when designCount > 0) Text('يشمل طلب تصميم مخصص بعد التفعيل: $designCount'),
      const SizedBox(height: AssalSpacing.md),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy ? null : () => _choosePlan(plan), icon: const Icon(Icons.arrow_forward_outlined), label: Text(plan.priceAmount == 0 ? 'استخدام الخطة الأساسية' : 'اختيار الخطة وبدء الحوالة'))),
    ])));
  }

  Widget _paymentCard() => Card(child: Padding(padding: const EdgeInsets.all(AssalSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('الحوالة المحلية', style: AssalTypography.heading3.copyWith(color: AssalColors.deepBrown)),
        const SizedBox(height: AssalSpacing.sm),
        if (transfer == null || !transfer!.isActive) const Text('بيانات الحوالة لم تُفعّل من الإدارة بعد.') else ...[
          if (transfer!.logoUrl?.isNotEmpty == true) Center(child: Image.network(transfer!.logoUrl!, height: 44, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
          if (transfer!.bankName != null) _paymentLine('البنك', transfer!.bankName!),
          if (transfer!.beneficiaryName != null) _paymentLine('اسم المستفيد', transfer!.beneficiaryName!),
          if (transfer!.accountNumber != null) _paymentLine('رقم الحساب', transfer!.accountNumber!),
          if (transfer!.iban != null) _paymentLine('الآيبان', transfer!.iban!),
          if (transfer!.phone != null) _paymentLine('الهاتف', transfer!.phone!),
          if (transfer!.instructionsAr?.isNotEmpty == true) Text(transfer!.instructionsAr!),
          const SizedBox(height: AssalSpacing.md),
          Text('المبلغ المطلوب: ${payment!.finalAmount.toStringAsFixed(2)} ${payment!.currency}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: AssalSpacing.md),
          TextField(controller: referenceController, decoration: const InputDecoration(labelText: 'مرجع الحوالة أو رقم العملية')),
          const SizedBox(height: AssalSpacing.sm),
          TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ المحول')),
          const SizedBox(height: AssalSpacing.sm),
          TextField(controller: senderNameController, decoration: const InputDecoration(labelText: 'اسم المحول')),
          const SizedBox(height: AssalSpacing.sm),
          TextField(controller: senderPhoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'هاتف المحول')),
          const SizedBox(height: AssalSpacing.md),
          OutlinedButton.icon(onPressed: busy ? null : _pickProof, icon: const Icon(Icons.upload_file_outlined), label: Text(proofName == null ? 'رفع مستند الحوالة' : 'تم اختيار: $proofName')),
          const SizedBox(height: AssalSpacing.sm),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy ? null : _submitProof, icon: const Icon(Icons.send_outlined), label: const Text('إرسال للمراجعة'))),
        ],
      ])));

  Widget _paymentLine(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))), Expanded(flex: 2, child: SelectableText(value, textDirection: TextDirection.ltr))]));
}
