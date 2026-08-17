import 'package:flutter/material.dart';

import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_design/assal_tokens.dart';
import '../../core/assal_widgets.dart';

class MerchantDashboard extends StatefulWidget {
  const MerchantDashboard({super.key, required this.repository});

  final AssalRepository repository;

  @override
  State<MerchantDashboard> createState() => _MerchantDashboardState();
}

class _MerchantDashboardState extends State<MerchantDashboard> {
  late Future<AssalLoadState<AssalMerchantApplicationSummary?>>
      applicationFuture;

  @override
  void initState() {
    super.initState();
    applicationFuture = _loadApplication();
  }

  Future<AssalLoadState<AssalMerchantApplicationSummary?>>
      _loadApplication() async {
    final session = await widget.repository.getSession();
    if (!session.isAuthenticated || session.user == null) {
      return const AssalError(
        'سجّل الدخول لعرض حالة طلب التاجر.',
        code: 'merchant_auth_required',
      );
    }
    return widget.repository.loadMerchantApplication(session.user!.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AssalAppBar(title: 'لوحة التاجر'),
        body: FutureBuilder<AssalLoadState<AssalMerchantApplicationSummary?>>(
          future: applicationFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const AssalGlassLoading();
            final state = snapshot.data!;
            if (state is AssalError<AssalMerchantApplicationSummary?>) {
              return AssalMessageCard(
                icon: Icons.pending_actions_outlined,
                message: state.messageAr,
              );
            }
            final application =
                state is AssalData<AssalMerchantApplicationSummary?>
                    ? state.value
                    : null;
            return _content(application);
          },
        ),
      );

  Widget _content(AssalMerchantApplicationSummary? application) {
    final status = application?.status;
    final statusLabel = switch (status) {
      'submitted' => 'تم الإرسال',
      'under_review' => 'قيد المراجعة',
      'verified' => 'موثق',
      'rejected' => 'مرفوض — يحتاج إلى تعديل',
      _ => 'لم يبدأ طلب التاجر بعد',
    };
    final statusDescription = switch (status) {
      'submitted' => 'تم استلام طلبك وينتظر المراجعة.',
      'under_review' => 'يراجع الفريق بيانات النشاط والمصدر.',
      'verified' => 'تم اعتماد المتجر كمتجر موثق.',
      'rejected' => 'راجع بياناتك وملاحظات المراجعة قبل إعادة الإرسال.',
      _ => 'ابدأ من شاشة «كن تاجرًا» لإرسال بيانات نشاطك.',
    };
    return ListView(
      padding: const EdgeInsets.all(AssalSpacing.lg),
      children: [
        Text(
          'لوحة التاجر',
          style:
              AssalTypography.heading1.copyWith(color: AssalColors.deepBrown),
        ),
        const SizedBox(height: AssalSpacing.sm),
        const Text('تعرض هذه الصفحة الحالة القادمة من Repository فقط.'),
        const SizedBox(height: AssalSpacing.xl),
        Card(
          child: ListTile(
            leading: const Icon(Icons.verified_outlined),
            title: Text(statusLabel),
            subtitle: Text(statusDescription),
          ),
        ),
        const SizedBox(height: AssalSpacing.md),
        Card(
          child: ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('المنتجات'),
            subtitle: Text(application == null
                ? 'يتاح تجهيز الكتالوج بعد إنشاء طلب التاجر واعتماده.'
                : 'يتاح تجهيز الكتالوج بعد اكتمال التحقق.'),
          ),
        ),
      ],
    );
  }
}
