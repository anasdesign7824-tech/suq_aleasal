import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_design/assal_tokens.dart';
import '../core/assal_widgets.dart';
import '../core/supabase_realtime_sync.dart';
import '../features/customer/customer_experience.dart';
import 'assal_theme.dart';
import 'assal_startup.dart';

class AssalApp extends StatelessWidget {
  const AssalApp({super.key, this.repository, this.startupError, this.realtimeSync});
  final AssalRepository? repository;
  final String? startupError;
  final SupabaseRealtimeSync? realtimeSync;
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'عسلكم',
        theme: buildAssalTheme(),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
              systemNavigationBarColor: AssalColors.primaryDark,
              systemNavigationBarIconBrightness: Brightness.light,
              systemStatusBarContrastEnforced: false,
              systemNavigationBarContrastEnforced: false,
              systemNavigationBarDividerColor: Colors.transparent,
            ),
            child: Directionality(
                textDirection: TextDirection.rtl,
                child: child ?? const SizedBox.shrink())),
        home: startupError != null
            ? AssalStartupErrorScreen(messageAr: startupError!)
            : repository == null
                ? const AssalStartupErrorScreen(
                    messageAr:
                        'لم يتم تزويد التطبيق بمصدر بيانات Production صالح.')
                : AssalStartupGate(
                    child: AssalHomeShell(
                      repository: repository!,
                      realtimeSync: realtimeSync,
                    ),
                  ),
      );
}

class AssalStartupErrorScreen extends StatelessWidget {
  const AssalStartupErrorScreen({
    super.key,
    required this.messageAr,
    this.onRetry,
  });
  final String messageAr;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AssalColors.cream,
        appBar: const AssalAppBar(title: 'خطأ بدء التشغيل'),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AssalSpacing.lg,
              AssalSpacing.md,
              AssalSpacing.lg,
              AssalSpacing.x4l,
            ),
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AssalSpacing.md,
                      vertical: AssalSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AssalColors.error.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(AssalRadius.pill),
                    ),
                    child: Text(
                      'غير متصل',
                      style: AssalTypography.bodySmall.copyWith(
                        color: AssalColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('تحديث'),
                  ),
                ],
              ),
              const SizedBox(height: AssalSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AssalSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'تعذر تشغيل التطبيق',
                        style: AssalTypography.heading2.copyWith(
                          color: AssalColors.deepBrown,
                        ),
                      ),
                      const SizedBox(height: AssalSpacing.sm),
                      Text(
                        messageAr,
                        style: AssalTypography.body.copyWith(
                          color: AssalColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AssalSpacing.lg),
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              AssalColors.primaryLight,
                              AssalColors.primaryDark,
                            ],
                          ),
                          borderRadius: BorderRadius.all(
                            Radius.circular(AssalRadius.medium),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AssalSpacing.x2l,
                          ),
                          child: Text(
                            'عسلكم',
                            textAlign: TextAlign.center,
                            style: AssalTypography.heading1.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AssalSpacing.md),
              const Wrap(
                spacing: AssalSpacing.sm,
                runSpacing: AssalSpacing.sm,
                children: <Widget>[
                  Chip(
                    avatar: Icon(Icons.error_outline, size: 18),
                    label: Text('تعذر تشغيل التطبيق'),
                  ),
                  Chip(
                    avatar: Icon(Icons.translate_rounded, size: 18),
                    label: Text('شرح الخطأ بالعربية'),
                  ),
                ],
              ),
              if (onRetry != null) ...<Widget>[
                const SizedBox(height: AssalSpacing.lg),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ],
          ),
        ),
      );
}

class AssalHomeShell extends StatefulWidget {
  const AssalHomeShell(
      {super.key, required this.repository, this.realtimeSync});
  final AssalRepository repository;
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
    repository = widget.repository;
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
          color: AssalColors.cream,
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
      // Desktop keeps its own framed column; mobile uses the single outer
      // Scaffold below so an AppBar is never mounted twice.
      final wideContent = selectedIndex == 0
          ? content
          : Scaffold(
              backgroundColor: AssalColors.cream,
              appBar: AssalAppBar(title: pageTitle),
              body: content,
            );
      if (wide) {
        return Scaffold(
            backgroundColor: AssalColors.cream,
            body: Row(children: [
          DecoratedBox(
            decoration: const BoxDecoration(gradient: assalDarkGradient),
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
          backgroundColor: AssalColors.cream,
          // Keep the scrollable page above the navigation bar. Extending the
          // body here made the profile actions look clipped at the bottom.
          extendBody: false,
          appBar: selectedIndex == 0
              ? null
              : AssalAppBar(title: pageTitle),
          body: content,
          bottomNavigationBar: DecoratedBox(
            decoration: const BoxDecoration(gradient: assalDarkGradient),
            child: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) =>
                    setState(() => selectedIndex = index),
                destinations: destinations),
          ));
    });
  }

  void _openSearch() => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SearchScreen(repository: repository)));

  void _openNotifications() => Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => NotificationsScreen(repository: repository)));
}
