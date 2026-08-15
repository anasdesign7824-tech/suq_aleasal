import 'package:flutter/material.dart';

import '../../../../../packages/contracts_dart/lib/assal_domain.dart';
import '../../../../../packages/data_dart/lib/assal_repository.dart';
import '../../../../../packages/design_system/dart/lib/assal_tokens.dart';
import '../../core/assal_widgets.dart';

class MerchantDashboard extends StatefulWidget {
  const MerchantDashboard({super.key, required this.repository});

  final AssalRepository repository;

  @override
  State<MerchantDashboard> createState() => _MerchantDashboardState();
}

class _MerchantDashboardState extends State<MerchantDashboard> {
  late Future<AssalLoadState<List<AssalProductSummary>>> productsFuture;
  late Future<AssalLoadState<List<AssalRequestSummary>>> requestsFuture;

  @override
  void initState() {
    super.initState();
    productsFuture = widget.repository.listProducts(query: const AssalProductQuery(storeId: 'demo-store-doani'));
    requestsFuture = widget.repository.listRequests('demo-user-001');
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(AssalSpacing.lg), children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('لوحة التاجر', style: AssalTypography.heading1.copyWith(color: AssalColors.deepBrown)), const SizedBox(height: 4), Text('مناحل دوعن الأصيلة', style: AssalTypography.bodyLarge.copyWith(color: AssalColors.textSecondary))]),
          const DemoModePill(),
        ]),
        const SizedBox(height: AssalSpacing.xl),
        Row(children: [
          Expanded(child: _MetricCard(icon: Icons.inventory_2_outlined, label: 'المنتجات', value: '12')),
          const SizedBox(width: AssalSpacing.md),
          Expanded(child: _MetricCard(icon: Icons.mail_outline, label: 'طلبات جديدة', value: '1')),
        ]),
        const SizedBox(height: AssalSpacing.xl),
        Text('طلبات التواصل', style: AssalTypography.heading2.copyWith(color: AssalColors.deepBrown)),
        const SizedBox(height: AssalSpacing.md),
        FutureBuilder<AssalLoadState<List<AssalRequestSummary>>>(future: requestsFuture, builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox(height: 110, child: Center(child: CircularProgressIndicator()));
          return AssalStateView<List<AssalRequestSummary>>(state: snapshot.data!, builder: (requests) => Column(children: requests.map((request) => Card(child: ListTile(leading: const CircleAvatar(backgroundColor: AssalColors.honeyLight, child: Icon(Icons.mail_outline, color: AssalColors.deepBrown)), title: Text(request.subject), subtitle: Text(request.body ?? 'بدون تفاصيل'), trailing: const Icon(Icons.chevron_left))).toList()));
        }),
        const SizedBox(height: AssalSpacing.xl),
        Text('منتجاتك', style: AssalTypography.heading2.copyWith(color: AssalColors.deepBrown)),
        const SizedBox(height: AssalSpacing.md),
        FutureBuilder<AssalLoadState<List<AssalProductSummary>>>(future: productsFuture, builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox(height: 110, child: Center(child: CircularProgressIndicator()));
          return AssalStateView<List<AssalProductSummary>>(state: snapshot.data!, builder: (products) => Column(children: products.take(5).map((product) => Card(child: ListTile(title: Text(product.nameAr), subtitle: Text('حالة المنتج: ${product.status.name}'), trailing: const Icon(Icons.edit_outlined))).toList()));
        }),
        const SizedBox(height: 96),
      ]);
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(AssalSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: AssalColors.primaryDark), const SizedBox(height: AssalSpacing.md), Text(value, style: AssalTypography.heading2), Text(label, style: AssalTypography.bodySmall.copyWith(color: AssalColors.textSecondary))])));
}
