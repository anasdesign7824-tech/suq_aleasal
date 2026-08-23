import 'package:flutter/material.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_design/assal_tokens.dart';

import '../../core/assal_widgets.dart';

class CustomerRequestDetailScreen extends StatefulWidget {
  const CustomerRequestDetailScreen({
    super.key,
    required this.repository,
    required this.request,
    required this.merchantMode,
    this.onOpenStore,
    this.onMessageMerchant,
  });

  final AssalRepository repository;
  final AssalRequestSummary request;
  final bool merchantMode;
  final Future<void> Function()? onOpenStore;
  final Future<void> Function()? onMessageMerchant;

  @override
  State<CustomerRequestDetailScreen> createState() =>
      _CustomerRequestDetailScreenState();
}

class _CustomerRequestDetailScreenState
    extends State<CustomerRequestDetailScreen> {
  late Future<AssalLoadState<List<AssalRequestMessageSummary>>> messagesFuture;
  final replyController = TextEditingController();
  RequestResponseCode responseCode = RequestResponseCode.contactRequired;
  late RequestStatus currentStatus;
  bool replying = false;

  @override
  void initState() {
    super.initState();
    currentStatus = widget.request.status;
    messagesFuture = widget.repository.listRequestMessages(widget.request.id);
  }

  @override
  void dispose() {
    replyController.dispose();
    super.dispose();
  }

  void _reloadMessages() {
    if (!mounted) return;
    setState(() {
      messagesFuture = widget.repository.listRequestMessages(widget.request.id);
    });
  }

  String _handoffLabel(String? value) => switch (value) {
        'pickup' => 'استلام من المتجر',
        'delivery' => 'توصيل التاجر',
        'office' => 'استلام من مكتب',
        'courier' => 'شركة شحن',
        'contact' => 'تواصل مباشر',
        _ => value?.trim().isNotEmpty == true ? value! : 'تواصل مباشر',
      };

  String _dateLabel(DateTime? value) {
    if (value == null) return 'غير محدد';
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} · $hour:$minute';
  }

  Future<void> _reply() async {
    final body = replyController.text.trim();
    if (body.isEmpty) {
      _showMessage('اكتب ردًا قبل الإرسال.');
      return;
    }
    if (body.length > 5000) {
      _showMessage('اختصر الرد إلى 5000 حرف أو أقل.');
      return;
    }
    if (replying) return;
    setState(() => replying = true);
    try {
      final session = await widget.repository.getSession();
      if (!mounted) return;
      if (session.isUnavailable) {
        _showMessage(session.errorMessageAr ?? 'تعذر مزامنة الحساب الآن.');
        return;
      }
      if (!session.isAuthenticated || session.user == null) {
        _showMessage('سجّل الدخول بحساب التاجر قبل الرد.');
        return;
      }
      final result = await widget.repository.replyToRequest(
        session.user!.id,
        widget.request.id,
        AssalRequestReplyDraft(body: body, responseCode: responseCode),
      );
      if (!mounted) return;
      if (result is AssalData<AssalRequestMessageSummary>) {
        replyController.clear();
        setState(() {
          currentStatus = RequestStatus.answered;
          messagesFuture =
              widget.repository.listRequestMessages(widget.request.id);
        });
        _showMessage('تم إرسال الرد وتحديث حالة الطلب.');
      } else if (result is AssalError<AssalRequestMessageSummary>) {
        _showMessage(result.messageAr);
      }
    } finally {
      if (mounted) setState(() => replying = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AssalAppBar(
          title: widget.merchantMode ? 'الرد على الطلب' : 'تفاصيل الطلب',
        ),
        body: ListView(
          padding: const EdgeInsets.all(AssalSpacing.lg),
          children: [
            _requestSummary(),
            const SizedBox(height: AssalSpacing.lg),
            Text(
              'سجل الطلب والردود',
              style: AssalTypography.heading2.copyWith(
                color: AssalColors.deepBrown,
              ),
            ),
            const SizedBox(height: AssalSpacing.sm),
            _messages(),
            if (!widget.merchantMode) ...[
              const SizedBox(height: AssalSpacing.lg),
              _customerActions(),
            ],
            if (widget.merchantMode) ...[
              const SizedBox(height: AssalSpacing.lg),
              _replyComposer(),
            ],
          ],
        ),
      );

  Widget _requestSummary() => Card(
        child: Padding(
          padding: const EdgeInsets.all(AssalSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: AssalColors.honeyLight,
                    child: Icon(
                      Icons.assignment_outlined,
                      color: AssalColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: AssalSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.request.subject,
                          style: AssalTypography.title.copyWith(
                            color: AssalColors.deepBrown,
                          ),
                        ),
                        const SizedBox(height: AssalSpacing.xs),
                        Text(
                          widget.request.productName ?? 'طلب تواصل مع المتجر',
                          style: AssalTypography.bodySmall.copyWith(
                            color: AssalColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(label: Text(currentStatus.labelAr)),
                ],
              ),
              const Divider(height: AssalSpacing.xl),
              _detailRow('المتجر', widget.request.storeName ?? 'متجر عسلكم'),
              if (widget.request.requesterName?.trim().isNotEmpty == true)
                _detailRow('العميل', widget.request.requesterName!),
              if (widget.request.quantity != null)
                _detailRow('الكمية', '${widget.request.quantity}'),
              _detailRow(
                'طريقة التسليم',
                _handoffLabel(widget.request.preferredHandoffOption),
              ),
              if (widget.request.body?.trim().isNotEmpty == true)
                _detailRow('تفاصيل العميل', widget.request.body!),
              if (widget.request.priceNote?.trim().isNotEmpty == true)
                _detailRow('ملاحظة السعر', widget.request.priceNote!),
              if (widget.request.deliveryNote?.trim().isNotEmpty == true)
                _detailRow('ملاحظة التسليم', widget.request.deliveryNote!),
              if (widget.request.phone?.trim().isNotEmpty == true)
                _detailRow('هاتف التواصل', widget.request.phone!),
              _detailRow('تاريخ الطلب', _dateLabel(widget.request.createdAt)),
              if (widget.request.updatedAt != null)
                _detailRow('آخر تحديث', _dateLabel(widget.request.updatedAt)),
            ],
          ),
        ),
      );

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: AssalSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: AssalTypography.caption.copyWith(
                  color: AssalColors.textMuted,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: AssalTypography.bodySmall.copyWith(
                  color: AssalColors.deepBrown,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _customerActions() => Card(
        child: Padding(
          padding: const EdgeInsets.all(AssalSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ماذا تريد أن تفعل؟',
                style: AssalTypography.title.copyWith(
                  color: AssalColors.deepBrown,
                ),
              ),
              const SizedBox(height: AssalSpacing.sm),
              OutlinedButton.icon(
                onPressed: widget.onMessageMerchant,
                icon: const Icon(Icons.forum_outlined),
                label: const Text('مراسلة التاجر'),
              ),
              const SizedBox(height: AssalSpacing.sm),
              FilledButton.icon(
                onPressed: widget.onOpenStore,
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('فتح المتجر'),
              ),
            ],
          ),
        ),
      );

  Widget _messages() =>
      FutureBuilder<AssalLoadState<List<AssalRequestMessageSummary>>>(
        future: messagesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AssalGlassLoading(height: 120);
          }
          final state = snapshot.data!;
          if (state is AssalError<List<AssalRequestMessageSummary>>) {
            return AssalMessageCard(
              icon: Icons.sync_problem_outlined,
              message: state.messageAr,
              onRetry: _reloadMessages,
            );
          }
          final messages = state is AssalData<List<AssalRequestMessageSummary>>
              ? state.value
              : const <AssalRequestMessageSummary>[];
          if (messages.isEmpty) {
            return const AssalMessageCard(
              icon: Icons.forum_outlined,
              message: 'لم يصل رد على الطلب بعد.',
            );
          }
          return Column(
            children: messages.map(_messageCard).toList(growable: false),
          );
        },
      );

  Widget _messageCard(AssalRequestMessageSummary message) {
    final mine = message.isMine;
    final senderLabel = mine
        ? 'أنت'
        : widget.merchantMode
            ? 'العميل'
            : 'التاجر';
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: Card(
        color: mine ? AssalColors.honeyLight : AssalColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(AssalSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    senderLabel,
                    style: AssalTypography.caption.copyWith(
                      color: AssalColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AssalSpacing.sm),
                  Text(
                    _dateLabel(message.createdAt),
                    style: AssalTypography.caption.copyWith(
                      color: AssalColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AssalSpacing.xs),
              Text(message.body, style: AssalTypography.body),
              if (message.responseCode != null) ...[
                const SizedBox(height: AssalSpacing.xs),
                Chip(
                  label: Text(message.responseCode!.labelAr),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _replyComposer() => Card(
        child: Padding(
          padding: const EdgeInsets.all(AssalSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إجابة التاجر',
                style: AssalTypography.title.copyWith(
                  color: AssalColors.deepBrown,
                ),
              ),
              const SizedBox(height: AssalSpacing.sm),
              DropdownButtonFormField<RequestResponseCode>(
                initialValue: responseCode,
                decoration: const InputDecoration(
                  labelText: 'حالة التوفر',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                items: RequestResponseCode.values
                    .map(
                      (value) => DropdownMenuItem<RequestResponseCode>(
                        value: value,
                        child: Text(value.labelAr),
                      ),
                    )
                    .toList(growable: false),
                onChanged: replying
                    ? null
                    : (value) => setState(
                          () => responseCode = value ?? responseCode,
                        ),
              ),
              const SizedBox(height: AssalSpacing.md),
              TextField(
                controller: replyController,
                maxLines: 5,
                enabled: !replying,
                decoration: const InputDecoration(
                  labelText: 'رسالة التاجر للعميل',
                  hintText: 'اذكر التوفر والتفاصيل المطلوبة للتنسيق.',
                ),
              ),
              const SizedBox(height: AssalSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: replying ? null : _reply,
                  icon: replying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(replying ? 'جارٍ إرسال الرد...' : 'إرسال الرد'),
                ),
              ),
            ],
          ),
        ),
      );
}
