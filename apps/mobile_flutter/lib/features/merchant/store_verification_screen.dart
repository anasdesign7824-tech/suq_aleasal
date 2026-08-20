import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_design/assal_tokens.dart';

import '../../core/assal_widgets.dart';

class StoreVerificationScreen extends StatefulWidget {
  const StoreVerificationScreen({
    super.key,
    required this.repository,
    required this.storeId,
  });

  final AssalRepository repository;
  final String storeId;

  @override
  State<StoreVerificationScreen> createState() =>
      _StoreVerificationScreenState();
}

class _StoreVerificationScreenState extends State<StoreVerificationScreen> {
  AssalStoreVerificationSummary? request;
  String? userId;
  String? message;
  bool loading = true;
  bool busy = false;
  final paymentReferenceController = TextEditingController();

  @override
  void dispose() {
    paymentReferenceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final session = await widget.repository.getSession();
    if (!mounted) return;
    if (session.isUnavailable) {
      setState(() {
        loading = false;
        message = session.errorMessageAr ?? 'تعذر مزامنة الحساب الآن.';
      });
      return;
    }
    if (!session.isAuthenticated || session.user == null) {
      setState(() {
        loading = false;
        message = 'سجّل الدخول أولًا لطلب توثيق Pro.';
      });
      return;
    }
    userId = session.user!.id;
    final state = await widget.repository
        .loadStoreVerification(userId!, widget.storeId);
    if (!mounted) return;
    setState(() {
      loading = false;
      if (state is AssalData<AssalStoreVerificationSummary?>) {
        request = state.value;
        message = null;
      } else if (state is AssalError<AssalStoreVerificationSummary?>) {
        message = state.messageAr;
      }
    });
  }

  Future<void> _createRequest() async {
    if (userId == null) {
      setState(() => message = 'تعذر تحديد حسابك. أعد تحميل الصفحة ثم حاول مرة أخرى.');
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    final state = await widget.repository.createStoreVerificationRequest(
      userId!,
      AssalStoreVerificationDraft(storeId: widget.storeId),
    );
    if (!mounted) return;
    setState(() {
      busy = false;
      if (state is AssalData<AssalStoreVerificationSummary>) {
        request = state.value;
        message = 'أُنشئت مسودة الطلب. أكمل الرسوم والمستندات قبل الإرسال.';
      } else if (state is AssalError<AssalStoreVerificationSummary>) {
        message = state.messageAr;
      }
    });
  }

  Future<void> _pickDocument(VerificationDocumentType type) async {
    final current = request;
    if (userId == null || current == null) {
      setState(() => message = 'ابدأ طلب التوثيق قبل رفع المستندات.');
      return;
    }
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      setState(() => message = 'تعذر قراءة الملف. اختره مرة أخرى بصيغة مدعومة.');
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    final extension = (file.extension ?? 'jpg').toLowerCase();
    final uploaded = await widget.repository.uploadVerificationDocument(
      userId!,
      current.id,
      bytes,
      extension,
    );
    if (!mounted) return;
    if (uploaded is AssalError<String>) {
      setState(() {
        busy = false;
        message = uploaded.messageAr;
      });
      return;
    }
    final path = uploaded is AssalData<String> ? uploaded.value : null;
    if (path == null) {
      setState(() {
        busy = false;
        message = 'تعذر حفظ الملف. حاول مرة أخرى.';
      });
      return;
    }
    final saved = await widget.repository.addVerificationDocument(
      userId!,
      current.id,
      AssalVerificationDocumentDraft(
        documentType: type,
        filePath: path,
        fileName: file.name,
        mimeType: _mimeType(extension),
        byteSize: bytes.length,
      ),
    );
    if (!mounted) return;
    setState(() {
      busy = false;
      if (saved is AssalData<AssalStoreVerificationSummary>) {
        request = saved.value;
        message = 'تم حفظ المستند داخل المسار الخاص. لن يظهر للعامة.';
      } else if (saved is AssalError<AssalStoreVerificationSummary>) {
        message = saved.messageAr;
      }
    });
  }

  Future<void> _submitPaymentReference() async {
    final current = request;
    final reference = paymentReferenceController.text.trim();
    if (userId == null || current == null) return;
    if (reference.length < 3) {
      setState(() => message = 'أدخل رقم العملية أو مرجع التحويل أولًا.');
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    final state = await widget.repository.submitVerificationPaymentReference(
      userId!,
      current.id,
      reference,
    );
    if (!mounted) return;
    setState(() {
      busy = false;
      if (state is AssalData<AssalStoreVerificationSummary>) {
        request = state.value;
        message = 'تم إرسال مرجع الدفع. بانتظار تأكيد الإدارة، ولم يُعتبر الدفع معتمدًا بعد.';
      } else if (state is AssalError<AssalStoreVerificationSummary>) {
        message = state.messageAr;
      }
    });
  }

  Future<void> _submit() async {
    final current = request;
    if (userId == null || current == null) return;
    const requiredTypes = {'identity', 'business_registration'};
    if (!requiredTypes.every(current.documentTypes.contains)) {
      setState(() => message = 'أرفق الهوية وإثبات تسجيل النشاط قبل الإرسال.');
      return;
    }
    if (current.paymentStatus != VerificationPaymentStatus.paid &&
        current.paymentStatus != VerificationPaymentStatus.waived) {
      setState(() => message = 'أكمل رسوم توثيق Pro قبل إرسال الطلب.');
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    final state = await widget.repository
        .submitStoreVerification(userId!, current.id);
    if (!mounted) return;
    setState(() {
      busy = false;
      if (state is AssalData<AssalStoreVerificationSummary>) {
        request = state.value;
        message = 'تم إرسال طلبك للمراجعة. ستصلك النتيجة عبر الإشعارات.';
      } else if (state is AssalError<AssalStoreVerificationSummary>) {
        message = state.messageAr;
      }
    });
  }

  String _mimeType(String extension) => switch (extension) {
        'pdf' => 'application/pdf',
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

  String _documentLabel(VerificationDocumentType type) => switch (type) {
        VerificationDocumentType.identity => 'الهوية الشخصية',
        VerificationDocumentType.businessRegistration => 'إثبات تسجيل النشاط',
        VerificationDocumentType.taxOrLicense => 'الرخصة أو البطاقة الضريبية',
        VerificationDocumentType.originCertificate => 'شهادة مصدر العسل',
        VerificationDocumentType.qualityCertificate => 'شهادة الجودة',
        VerificationDocumentType.addressProof => 'إثبات العنوان',
        VerificationDocumentType.other => 'مستند إضافي',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AssalAppBar(title: 'توثيق المتجر Pro'),
      body: loading
          ? const AssalGlassLoading()
          : ListView(
              padding: const EdgeInsets.all(AssalSpacing.lg),
              children: [
                _intro(),
                const SizedBox(height: AssalSpacing.md),
                if (message != null) ...[
                  AssalMessageCard(
                    icon: Icons.info_outline,
                    message: message!,
                  ),
                  const SizedBox(height: AssalSpacing.md),
                ],
                if (request == null)
                  _startCard()
                else ...[
                  _statusCard(request!),
                  const SizedBox(height: AssalSpacing.md),
                  _paymentCard(request!),
                  const SizedBox(height: AssalSpacing.md),
                  _documentsCard(request!),
                  const SizedBox(height: AssalSpacing.md),
                  _submitCard(request!),
                ],
              ],
            ),
    );
  }

  Widget _intro() => Card(
        child: Padding(
          padding: const EdgeInsets.all(AssalSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user_outlined,
                      color: AssalColors.primaryDark),
                  const SizedBox(width: AssalSpacing.sm),
                  Text('شارة ثقة مبنية على مراجعة',
                      style: AssalTypography.heading3
                          .copyWith(color: AssalColors.deepBrown)),
                ],
              ),
              const SizedBox(height: AssalSpacing.sm),
              const Text(
                'فتح المتجر وتفعيل ظهوره لا يعني التوثيق. توثيق Pro خدمة مستقلة تتطلب رسومًا ومستندات ومراجعة إدارية، وقد تُرفض أو تطلب معلومات إضافية.',
              ),
            ],
          ),
        ),
      );

  Widget _startCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(AssalSpacing.lg),
          child: Column(
            children: [
              const Icon(Icons.assignment_outlined,
                  size: 42, color: AssalColors.primaryDark),
              const SizedBox(height: AssalSpacing.sm),
              const Text('لم يبدأ طلب التوثيق لهذا المتجر.'),
              const SizedBox(height: AssalSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : _createRequest,
                  icon: const Icon(Icons.add_task_outlined),
                  label: const Text('بدء طلب توثيق Pro'),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _statusCard(AssalStoreVerificationSummary current) => Card(
        child: ListTile(
          leading: const Icon(Icons.timeline_outlined,
              color: AssalColors.primaryDark),
          title: Text(current.status.labelAr),
          subtitle: Text(current.paymentStatus.labelAr),
          trailing: current.documentCount == 0
              ? const Icon(Icons.warning_amber_outlined,
                  color: AssalColors.warning)
              : Text('${current.documentCount} مستند'),
        ),
      );

  Widget _paymentCard(AssalStoreVerificationSummary current) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AssalSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('رسوم توثيق Pro',
                  style: AssalTypography.heading3
                      .copyWith(color: AssalColors.deepBrown)),
              const SizedBox(height: AssalSpacing.xs),
              const Text(
                'أرسل رقم العملية أو مرجع التحويل بالطريقة التي تعتمدها الإدارة. لا يتحول الطلب إلى مدفوع إلا بعد التحقق الإداري.',
              ),
              const SizedBox(height: AssalSpacing.md),
              TextField(
                controller: paymentReferenceController,
                enabled: !busy &&
                    current.paymentStatus != VerificationPaymentStatus.paid &&
                    current.paymentStatus != VerificationPaymentStatus.waived,
                decoration: const InputDecoration(
                  labelText: 'رقم العملية أو مرجع التحويل',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                ),
              ),
              const SizedBox(height: AssalSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: busy ||
                          current.paymentStatus == VerificationPaymentStatus.paid ||
                          current.paymentStatus == VerificationPaymentStatus.waived
                      ? null
                      : _submitPaymentReference,
                  icon: const Icon(Icons.send_to_mobile_outlined),
                  label: Text(current.paymentStatus == VerificationPaymentStatus.pending
                      ? 'تحديث مرجع الدفع'
                      : 'إرسال مرجع الدفع للتأكيد'),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _documentsCard(AssalStoreVerificationSummary current) {
    const types = [
      VerificationDocumentType.identity,
      VerificationDocumentType.businessRegistration,
      VerificationDocumentType.taxOrLicense,
      VerificationDocumentType.originCertificate,
      VerificationDocumentType.qualityCertificate,
      VerificationDocumentType.addressProof,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AssalSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المستندات المطلوبة',
                style: AssalTypography.heading3
                    .copyWith(color: AssalColors.deepBrown)),
            const SizedBox(height: AssalSpacing.xs),
            const Text('المطلوب الأساسي: الهوية وإثبات تسجيل النشاط. بقية المستندات تدعم المراجعة حسب طبيعة المتجر.'),
            const SizedBox(height: AssalSpacing.sm),
            ...types.map(
              (type) {
                final wire = _wireType(type);
                final uploaded = current.documentTypes.contains(wire);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    uploaded ? Icons.check_circle : Icons.description_outlined,
                    color: uploaded
                        ? AssalColors.success
                        : AssalColors.textSecondary,
                  ),
                  title: Text(_documentLabel(type)),
                  subtitle: Text(uploaded ? 'مرفق' : 'لم يُرفق بعد'),
                  trailing: OutlinedButton(
                    onPressed: busy || current.status == StoreVerificationStatus.submitted
                        ? null
                        : () => _pickDocument(type),
                    child: Text(uploaded ? 'استبدال' : 'إرفاق'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _submitCard(AssalStoreVerificationSummary current) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AssalSpacing.lg),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ||
                      current.status == StoreVerificationStatus.submitted ||
                      current.status == StoreVerificationStatus.underReview ||
                      current.status == StoreVerificationStatus.approved
                  ? null
                  : _submit,
              icon: const Icon(Icons.send_outlined),
              label: Text(
                current.status == StoreVerificationStatus.approved
                    ? 'تم اعتماد التوثيق'
                    : 'إرسال الطلب للمراجعة',
              ),
            ),
          ),
        ),
      );

  String _wireType(VerificationDocumentType type) => switch (type) {
        VerificationDocumentType.identity => 'identity',
        VerificationDocumentType.businessRegistration => 'business_registration',
        VerificationDocumentType.taxOrLicense => 'tax_or_license',
        VerificationDocumentType.originCertificate => 'origin_certificate',
        VerificationDocumentType.qualityCertificate => 'quality_certificate',
        VerificationDocumentType.addressProof => 'address_proof',
        VerificationDocumentType.other => 'other',
      };
}
