import 'package:flutter/material.dart';

import '../../../../../packages/design_system/dart/lib/assal_tokens.dart';

class MerchantDashboard extends StatelessWidget {
  const MerchantDashboard({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('لوحة التاجر')),
        body: ListView(padding: const EdgeInsets.all(AssalSpacing.lg), children: [
          Text('لوحة التاجر التجريبية', style: AssalTypography.heading1.copyWith(color: AssalColors.deepBrown)),
          const SizedBox(height: AssalSpacing.sm),
          const Text('تظهر بعد اكتمال مسار التحول إلى تاجر والتحقق من المتجر.'),
          const SizedBox(height: AssalSpacing.xl),
          const Card(child: ListTile(leading: Icon(Icons.pending_actions), title: Text('حالة التحقق'), subtitle: Text('قيد المراجعة في Demo Mode'))),
          const Card(child: ListTile(leading: Icon(Icons.inventory_2_outlined), title: Text('المنتجات'), subtitle: Text('يمكنك تجهيز كتالوج المتجر بعد التحقق'))),
        ]),
      );
}
