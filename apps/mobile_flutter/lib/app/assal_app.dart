import 'package:flutter/material.dart';

import '../../../../packages/data_dart/lib/assal_repository.dart';
import '../../../../packages/data_dart/lib/demo_repository.dart';
import '../core/demo_loader.dart';
import '../features/customer/home_screen.dart';
import '../features/merchant/merchant_dashboard.dart';
import 'assal_theme.dart';

class AssalApp extends StatelessWidget {
  const AssalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'عسلكم',
      theme: buildAssalTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const AssalHomeShell(),
    );
  }
}

class AssalHomeShell extends StatefulWidget {
  const AssalHomeShell({super.key});

  @override
  State<AssalHomeShell> createState() => _AssalHomeShellState();
}

class _AssalHomeShellState extends State<AssalHomeShell> {
  late final AssalRepository repository = DemoRepository(loader: const RootBundleDemoCatalogLoader());
  int selectedIndex = 0;
  bool merchantMode = false;

  @override
  Widget build(BuildContext context) {
    final pages = merchantMode
        ? [MerchantDashboard(repository: repository), const _MerchantProfilePlaceholder()]
        : [HomeScreen(repository: repository), const _CustomerProfilePlaceholder()];
    final labels = merchantMode ? ['لوحة التاجر', 'حسابي'] : ['اكتشف', 'حسابي'];
    return Scaffold(
      body: SafeArea(child: pages[selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => setState(() => selectedIndex = index),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: labels[0]),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: labels[1]),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() {
          merchantMode = !merchantMode;
          selectedIndex = 0;
        }),
        icon: Icon(merchantMode ? Icons.storefront : Icons.handshake_outlined),
        label: Text(merchantMode ? 'عرض العميل' : 'وضع التاجر'),
      ),
    );
  }
}

class _CustomerProfilePlaceholder extends StatelessWidget {
  const _CustomerProfilePlaceholder();

  @override
  Widget build(BuildContext context) => const Center(child: Text('حساب العميل — Demo Mode'));
}

class _MerchantProfilePlaceholder extends StatelessWidget {
  const _MerchantProfilePlaceholder();

  @override
  Widget build(BuildContext context) => const Center(child: Text('حساب التاجر — Demo Mode'));
}
