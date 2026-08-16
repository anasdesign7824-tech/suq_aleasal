import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_data/demo_repository.dart';
import '../core/demo_loader.dart';
import '../features/customer/customer_experience.dart';
import 'assal_theme.dart';

class AssalApp extends StatelessWidget {
  const AssalApp({super.key, this.repository});
  final AssalRepository? repository;
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'عسلكم',
        theme: buildAssalTheme(),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child ?? const SizedBox.shrink()),
        home: AssalHomeShell(repository: repository),
      );
}

class AssalHomeShell extends StatefulWidget {
  const AssalHomeShell({super.key, this.repository});
  final AssalRepository? repository;
  @override
  State<AssalHomeShell> createState() => _AssalHomeShellState();
}

class _AssalHomeShellState extends State<AssalHomeShell> {
  late final AssalRepository repository;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? DemoRepository(loader: const RootBundleDemoCatalogLoader());
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(repository: repository, onOpenSearch: _openSearch, onOpenNotifications: _openNotifications),
      CategoriesScreen(repository: repository),
      MessagesScreen(repository: repository),
      ProfileScreen(repository: repository),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: selectedIndex, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => setState(() => selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'اكتشف'),
          NavigationDestination(icon: Icon(Icons.category_outlined), selectedIcon: Icon(Icons.category), label: 'التصنيفات'),
          NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum), label: 'المراسلات'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }

  void _openSearch() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SearchScreen(repository: repository)));
  void _openNotifications() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NotificationsScreen(repository: repository)));
}
