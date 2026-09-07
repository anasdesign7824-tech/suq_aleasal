import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_data/demo_repository.dart';
import 'package:assalkom_design/assal_tokens.dart';
import '../core/demo_loader.dart';
import '../core/assal_widgets.dart';
import '../core/supabase_realtime_sync.dart';
import '../features/customer/customer_experience.dart';
import 'assal_theme.dart';
import 'assal_routes.dart';

class AssalApp extends StatefulWidget {
  const AssalApp({
    super.key,
    this.repository,
    this.startupError,
    this.realtimeSync,
    this.themeController,
  });

  final AssalRepository? repository;
  final String? startupError;
  final SupabaseRealtimeSync? realtimeSync;
  final AssalThemeController? themeController;

  @override
  State<AssalApp> createState() => _AssalAppState();
}

class _AssalAppState extends State<AssalApp> {
  late final AssalThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _themeController = widget.themeController ?? AssalThemeController();
  }

  @override
  void dispose() {
    if (widget.themeController == null) _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AssalThemeScope(
        controller: _themeController,
        child: ValueListenableBuilder<AssalThemeMode>(
          valueListenable: _themeController,
          builder: (context, mode, _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'عسلكم',
            theme: buildAssalTheme(mode: mode),
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness:
                    mode == AssalThemeMode.dark ? Brightness.light : Brightness.dark,
                statusBarBrightness:
                    mode == AssalThemeMode.dark ? Brightness.dark : Brightness.light,
                systemNavigationBarColor: mode == AssalThemeMode.dark
                    ? AssalColors.background
                    : AssalBeigeColors.background,
                systemNavigationBarIconBrightness:
                    mode == AssalThemeMode.dark ? Brightness.light : Brightness.dark,
                systemStatusBarContrastEnforced: false,
                systemNavigationBarContrastEnforced: false,
                systemNavigationBarDividerColor: Colors.transparent,
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
            home: widget.startupError == null
                ? AssalHomeShell(
                    repository: widget.repository,
                    realtimeSync: widget.realtimeSync,
                  )
                : AssalStartupErrorScreen(messageAr: widget.startupError!),
          ),
        ),
      );
}

class AssalStartupErrorScreen extends StatelessWidget {
  const AssalStartupErrorScreen({super.key, required this.messageAr});
  final String messageAr;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AssalAppBar(title: 'تعذر تشغيل عسلكم', showBrand: false),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cloud_off_outlined, size: 52),
                    const SizedBox(height: 16),
                    const Text('إعدادات التشغيل غير مكتملة',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Text(messageAr, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    const Text(
                        'لا تم إدخالك إلى Demo تلقائيًا حتى لا تختلط بيانات الاختبار ببيئة الإنتاج.',
                        textAlign: TextAlign.center),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}

class AssalHomeShell extends StatefulWidget {
  const AssalHomeShell({super.key, this.repository, this.realtimeSync});
  final AssalRepository? repository;
  final SupabaseRealtimeSync? realtimeSync;
  @override
  State<AssalHomeShell> createState() => _AssalHomeShellState();
}

class _AssalHomeShellState extends State<AssalHomeShell> {
  late final AssalRepository repository;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    repository = widget.repository ??
        DemoRepository(loader: const RootBundleDemoCatalogLoader());
    widget.realtimeSync?.start(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    widget.realtimeSync?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaffoldColor = theme.scaffoldBackgroundColor;
    final surfaceColor = theme.colorScheme.surface;
    final dividerColor = theme.dividerColor;

    final pages = [
      HomeScreen(
        repository: repository,
        onOpenSearch: _openSearch,
        onOpenNotifications: _openNotifications,
      ),
      StoresScreen(repository: repository, showAppBar: false),
      CategoriesScreen(repository: repository, showAppBar: false),
      MessagesScreen(repository: repository, showAppBar: false),
      ProfileScreen(repository: repository, showAppBar: false),
    ];
    const destinations = [
      NavigationDestination(
        icon: Icon(Icons.explore_outlined),
        selectedIcon: Icon(Icons.explore),
        label: 'اكتشف',
      ),
      NavigationDestination(
        icon: Icon(Icons.storefront_outlined),
        selectedIcon: Icon(Icons.storefront),
        label: 'المتاجر',
      ),
      NavigationDestination(
        icon: Icon(Icons.category_outlined),
        selectedIcon: Icon(Icons.category),
        label: 'التصنيفات',
      ),
      NavigationDestination(
        icon: Icon(Icons.forum_outlined),
        selectedIcon: Icon(Icons.forum),
        label: 'المراسلات',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'حسابي',
      ),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final content = SafeArea(
        top: false,
        bottom: false,
        child: ColoredBox(
          color: scaffoldColor,
          child: IndexedStack(index: selectedIndex, children: pages),
        ),
      );
      final pageTitle = switch (selectedIndex) {
        1 => 'المتاجر',
        2 => 'التصنيفات',
        3 => 'المراسلات',
        4 => 'حسابي',
        _ => 'عسلكم',
      };
      final wideContent = selectedIndex == 0
          ? content
          : Scaffold(
              backgroundColor: scaffoldColor,
              appBar: AssalAppBar(title: pageTitle),
              body: content,
            );
      if (wide) {
        return Scaffold(
            backgroundColor: scaffoldColor,
            body: Row(children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                left: BorderSide(color: dividerColor),
                right: BorderSide(color: dividerColor),
              ),
            ),
            child: NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => selectedIndex = index),
              labelType: NavigationRailLabelType.all,
              destinations: destinations
                  .map((item) => NavigationRailDestination(
                      icon: item.icon,
                      selectedIcon: item.selectedIcon ?? item.icon,
                      label: Text(item.label)))
                  .toList()),
          ),
          Expanded(child: wideContent)
        ]));
      }
      return Scaffold(
          backgroundColor: scaffoldColor,
          extendBody: false,
          appBar: selectedIndex == 0
              ? null
              : AssalAppBar(title: pageTitle),
          body: content,
          bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(top: BorderSide(color: dividerColor)),
            ),
            child: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) =>
                    setState(() => selectedIndex = index),
                destinations: destinations),
          ));
    });
  }

  void _openSearch() => Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: AssalRoutes.search),
      builder: (_) => SearchScreen(repository: repository),
    ));

  void _openNotifications() => Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: AssalRoutes.notifications),
      builder: (_) => NotificationsScreen(repository: repository),
    ));
}
