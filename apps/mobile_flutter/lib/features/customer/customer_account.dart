import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_design/assal_tokens.dart';
import '../../core/assal_widgets.dart';
import 'customer_core.dart';
import 'customer_favorites.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.repository});
  final AssalRepository repository;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}
class _AuthScreenState extends State<AuthScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool registerMode = false;
  bool loading = false;
  @override
  void dispose() { nameController.dispose(); emailController.dispose(); passwordController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(registerMode ? 'إنشاء حساب' : 'تسجيل الدخول')), body: ListView(padding: const EdgeInsets.all(AssalSpacing.xl), children: [const AssalBrandMark(size: 66), const SizedBox(height: AssalSpacing.xl), Text(registerMode ? 'أنشئ حسابك في عسلكم' : 'أهلًا بك في عسلكم', style: AssalTypography.heading1.copyWith(color: AssalColors.deepBrown)), const SizedBox(height: AssalSpacing.sm), Text('يمكنك التصفح كزائر، والحساب يفتح لك الحفظ والمتابعة والطلبات والمراسلة.', style: AssalTypography.bodyLarge.copyWith(color: AssalColors.textSecondary)), const SizedBox(height: AssalSpacing.xl), if (registerMode) ...[TextField(controller: nameController, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'الاسم')) , const SizedBox(height: AssalSpacing.md)], TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')), const SizedBox(height: AssalSpacing.md), TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور')), const SizedBox(height: AssalSpacing.lg), SizedBox(width: double.infinity, child: FilledButton(onPressed: loading ? null : _submit, child: loading ? const SizedBox(height: 44, child: AssalGlassLoading(height: 44, label: 'جارٍ تسجيل الدخول...')) : Text(registerMode ? 'إنشاء الحساب' : 'تسجيل الدخول'))), Column(children: [
        Tooltip(message: widget.repository.mode == AssalDataSourceMode.demo ? 'يتطلب ربط مزود OAuth الإنتاجي' : 'تسجيل الدخول عبر Google', child: OutlinedButton.icon(onPressed: widget.repository.mode == AssalDataSourceMode.production && !loading ? _googleSignIn : null, icon: const Icon(Icons.account_circle_outlined), label: Text(widget.repository.mode == AssalDataSourceMode.demo ? 'Google — غير متاح في Demo' : 'المتابعة عبر Google'))),
        if (kIsWeb || defaultTargetPlatform != TargetPlatform.android)
          Tooltip(message: widget.repository.mode == AssalDataSourceMode.demo ? 'يتطلب ربط مزود OAuth الإنتاجي' : 'تسجيل الدخول عبر Facebook', child: OutlinedButton.icon(onPressed: widget.repository.mode == AssalDataSourceMode.production && !loading ? _facebookSignIn : null, icon: const Icon(Icons.facebook), label: Text(widget.repository.mode == AssalDataSourceMode.demo ? 'Facebook — غير متاح في Demo' : 'المتابعة عبر Facebook'))),
      ]), TextButton(onPressed: () => setState(() => registerMode = !registerMode), child: Text(registerMode ? 'لديك حساب؟ تسجيل الدخول' : 'ليس لديك حساب؟ إنشاء حساب'))]));
  Future<void> _submit() async { setState(() => loading = true); final result = registerMode ? await widget.repository.register(nameController.text, emailController.text, passwordController.text) : await widget.repository.signIn(emailController.text, passwordController.text); if (!mounted) return; setState(() => loading = false); if (result is AssalData<AssalSession>) { Navigator.pop(context); } else if (result is AssalError<AssalSession>) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.messageAr))); } }
  Future<void> _googleSignIn() => _authAction(widget.repository.signInWithGoogle, 'Google');
  Future<void> _facebookSignIn() => _authAction(widget.repository.signInWithFacebook, 'Facebook');

  Future<void> _authAction(Future<AssalLoadState<AssalSession>> Function() action, String providerName) async {
    setState(() => loading = true);
    final result = await action();
    if (!mounted) return;
    setState(() => loading = false);
    if (result is AssalData<AssalSession>) {
      Navigator.pop(context);
    } else if (result is AssalError<AssalSession>) {
      if (result.code == 'oauth_started') {
        setState(() => loading = true);
        final restored = await _waitForOAuthSession();
        if (!mounted) return;
        setState(() => loading = false);
        if (restored) {
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('أكمل تسجيل الدخول عبر $providerName ثم حاول المتابعة مرة أخرى.')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.messageAr)));
      }
    }
  }

  Future<bool> _waitForOAuthSession() async {
    for (var attempt = 0; attempt < 60; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      final session = await widget.repository.getSession();
      if (session.isAuthenticated) return true;
    }
    return false;
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.repository});
  final AssalRepository repository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AssalSession>(
      future: repository.getSession(),
      builder: (context, snapshot) {
        final session = snapshot.data ?? AssalSession.guest;
        return ListView(padding: const EdgeInsets.all(AssalSpacing.lg), children: [
          const AssalBrandMark(),
          const SizedBox(height: AssalSpacing.xl),
          session.isAuthenticated ? _authenticated(context, session) : _guest(context),
          const SizedBox(height: AssalSpacing.lg),
          Card(child: Column(children: [
            ListTile(leading: const Icon(Icons.bookmarks_outlined), title: const Text('المحفوظات والمتاجر المتابَعة'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FavoritesScreen(repository: repository)))),
            ListTile(leading: const Icon(Icons.notifications_outlined), title: const Text('الإشعارات'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NotificationsScreen(repository: repository)))),
            ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('الإعدادات'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()))),
            ListTile(leading: const Icon(Icons.help_outline), title: const Text('الدعم والتعريف بعسلكم'), trailing: const Icon(Icons.chevron_left), onTap: () => showAboutDialog(context: context, applicationName: 'عسلكم', applicationVersion: 'Demo', children: [const Text('منصة اكتشاف وتواصل للعسل اليمني من مصدره.')]))
          ])),
        ]);
      },
    );
  }

  Widget _guest(BuildContext context) {
    return Card(
      color: AssalColors.cream,
      child: Padding(
        padding: const EdgeInsets.all(AssalSpacing.xl),
        child: Column(children: [
          const CircleAvatar(radius: 34, backgroundColor: AssalColors.honeyLight, child: Icon(Icons.person_outline, size: 36, color: AssalColors.primaryDark)),
          const SizedBox(height: AssalSpacing.md),
          Text('تصفح كزائر', style: AssalTypography.heading2.copyWith(color: AssalColors.deepBrown)),
          const SizedBox(height: AssalSpacing.sm),
          const Text('احفظ ما يعجبك وأرسل طلباتك عند إنشاء حساب مجاني.'),
          const SizedBox(height: AssalSpacing.lg),
          FilledButton(onPressed: () => openAuth(context, repository), child: const Text('تسجيل الدخول أو إنشاء حساب')),
        ]),
      ),
    );
  }

  Widget _authenticated(BuildContext context, AssalSession session) => Column(children: [
    CircleAvatar(radius: 38, backgroundColor: AssalColors.honeyLight, child: Text((session.user?.nameAr ?? 'ع').substring(0, 1), style: AssalTypography.heading1.copyWith(color: AssalColors.primaryDark))),
    const SizedBox(height: AssalSpacing.md),
    Text(session.user?.nameAr ?? 'عميل عسلكم', style: AssalTypography.heading2.copyWith(color: AssalColors.deepBrown)),
    Text(session.user?.email ?? '', style: AssalTypography.body.copyWith(color: AssalColors.textSecondary)),
    const SizedBox(height: AssalSpacing.lg),
    _ProfileStats(repository: repository, userId: session.user?.id ?? 'demo-customer'),
    const SizedBox(height: AssalSpacing.lg),
    Row(children: [
      Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RequestsScreen(repository: repository))), icon: const Icon(Icons.assignment_outlined), label: const Text('طلباتي'))),
      const SizedBox(width: AssalSpacing.sm),
      Expanded(child: FilledButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BecomeMerchantScreen(repository: repository))), icon: const Icon(Icons.storefront_outlined), label: const Text('كن تاجرًا'))),
    ]),
    const SizedBox(height: AssalSpacing.sm),
    OutlinedButton.icon(onPressed: () async { await repository.signOut(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(repository.mode == AssalDataSourceMode.demo ? 'تم تسجيل الخروج من Demo Mode' : 'تم تسجيل الخروج.'))); }, icon: const Icon(Icons.logout), label: const Text('تسجيل الخروج')),
  ]);

}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.repository, required this.userId});
  final AssalRepository repository;
  final String userId;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<AssalLoadState<Object?>>>(
        future: Future.wait<Object?>([repository.listFollowedStores(userId), repository.listFavoriteProducts(userId), repository.listRequests(userId)]).then((states) => states.cast<AssalLoadState<Object?>>()),
        builder: (context, snapshot) {
          final values = snapshot.data ?? const <AssalLoadState<Object?>>[];
          int countAt(int index) {
            if (index >= values.length) return 0;
            final state = values[index];
            return state is AssalData && state.value is List ? (state.value as List).length : 0;
          }
          return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_metric('${countAt(0)}', 'المتابعات'), _metric('${countAt(1)}', 'المحفوظات'), _metric('${countAt(2)}', 'الطلبات')]);
        },
      );

  Widget _metric(String value, String label) => Column(children: [Text(value, style: AssalTypography.heading3.copyWith(color: AssalColors.deepBrown)), Text(label, style: AssalTypography.caption.copyWith(color: AssalColors.textMuted))]);
}

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key, required this.repository});
  final AssalRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلباتي')),
      body: FutureBuilder<AssalSession>(
        future: repository.getSession(),
        builder: (context, sessionSnapshot) {
          final session = sessionSnapshot.data ?? AssalSession.guest;
          if (!session.isAuthenticated) {
            return Center(child: FilledButton(onPressed: () => openAuth(context, repository), child: const Text('تسجيل الدخول لمتابعة الطلبات')));
          }
          return FutureBuilder<AssalLoadState<List<AssalRequestSummary>>>(
            future: repository.listRequests(session.user!.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const AssalGlassLoading();
              return AssalStateView<List<AssalRequestSummary>>(
                state: snapshot.data!,
                builder: (requests) => ListView.separated(
                  padding: const EdgeInsets.all(AssalSpacing.lg),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AssalSpacing.sm),
                  itemBuilder: (_, index) {
                    final request = requests[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: AssalColors.honeyLight, child: Icon(Icons.assignment_outlined, color: AssalColors.primaryDark)),
                        title: Text(request.subject),
                        subtitle: Text('${request.storeName ?? request.storeId} · ${request.preferredHandoffOption ?? 'تواصل مباشر'}'),
                        trailing: Chip(label: Text(request.status.labelAr)),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.repository});
  final AssalRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: FutureBuilder<AssalSession>(
        future: repository.getSession(),
        builder: (context, sessionSnapshot) {
          final session = sessionSnapshot.data ?? AssalSession.guest;
          if (!session.isAuthenticated) {
            return Center(child: FilledButton(onPressed: () => openAuth(context, repository), child: const Text('تسجيل الدخول لعرض إشعاراتك')));
          }
          return FutureBuilder<AssalLoadState<List<AssalNotificationSummary>>>(
            future: repository.listNotifications(session.user!.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const AssalGlassLoading();
              return AssalStateView<List<AssalNotificationSummary>>(
                state: snapshot.data!,
                builder: (items) => ListView.separated(
                  padding: const EdgeInsets.all(AssalSpacing.lg),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, index) { final item = items[index]; return ListTile(
                    tileColor: item.readAt == null ? AssalColors.cream : null,
                    leading: CircleAvatar(backgroundColor: AssalColors.honeyLight, child: Icon(item.readAt == null ? Icons.notifications_active_outlined : Icons.notifications_none, color: AssalColors.primaryDark)),
                    title: Text(item.titleAr, style: item.readAt == null ? const TextStyle(fontWeight: FontWeight.w700) : null),
                    subtitle: Text(item.bodyAr ?? ''),
                    onTap: () async { await repository.markNotificationRead(session.user!.id, item.id); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعليم الإشعار كمقروء.'))); },
                  ); },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, required this.repository, required this.conversation});
  final AssalRepository repository;
  final AssalConversationSummary conversation;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final controller = TextEditingController();
  late Future<AssalLoadState<List<AssalMessageSummary>>> future;

  @override
  void initState() {
    super.initState();
    future = widget.repository.listMessages(widget.conversation.id);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.conversation.storeName)),
      body: Column(children: [
        Expanded(
          child: FutureBuilder<AssalLoadState<List<AssalMessageSummary>>>(
            future: future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const AssalGlassLoading();
              return AssalStateView<List<AssalMessageSummary>>(
                state: snapshot.data!,
                builder: (messages) => ListView(
                  padding: const EdgeInsets.all(AssalSpacing.lg),
                  children: messages.map<Widget>((message) {
                    return Align(
                      alignment: message.isMine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
                      child: Card(
                        color: message.isMine ? AssalColors.honeyLight : AssalColors.surfaceVariant,
                        child: Padding(padding: const EdgeInsets.all(AssalSpacing.md), child: Text(message.body)),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AssalSpacing.sm),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: TextField(controller: controller, maxLines: 3, minLines: 1, decoration: const InputDecoration(hintText: 'اكتب رسالتك'))),
              IconButton(onPressed: _send, icon: const Icon(Icons.send_rounded), tooltip: 'إرسال'),
            ]),
          ),
        ),
      ]),
    );
  }

  Future<void> _send() async {
    final body = controller.text.trim();
    if (body.isEmpty) return;
    await widget.repository.sendMessage('demo-customer', AssalMessageDraft(conversationId: widget.conversation.id, body: body));
    controller.clear();
    setState(() => future = widget.repository.listMessages(widget.conversation.id));
  }
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key, required this.repository});
  final AssalRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المراسلات')),
      body: FutureBuilder<AssalSession>(
        future: repository.getSession(),
        builder: (context, sessionSnapshot) {
          final session = sessionSnapshot.data ?? AssalSession.guest;
          if (!session.isAuthenticated) return Center(child: FilledButton(onPressed: () => openAuth(context, repository), child: const Text('تسجيل الدخول لعرض المراسلات')));
          return FutureBuilder<AssalLoadState<List<AssalConversationSummary>>>(
            future: repository.listConversations(session.user!.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const AssalGlassLoading();
              return AssalStateView<List<AssalConversationSummary>>(
                state: snapshot.data!,
                builder: (items) => ListView.separated(
                  padding: const EdgeInsets.all(AssalSpacing.lg),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AssalSpacing.sm),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: AssalColors.honeyLight, child: Icon(Icons.storefront_outlined, color: AssalColors.primaryDark)),
                        title: Text(item.storeName),
                        subtitle: Text(item.lastMessage),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConversationScreen(repository: repository, conversation: item))),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الإعدادات')),
        body: ListView(padding: const EdgeInsets.all(AssalSpacing.lg), children: [
          Card(child: Column(children: [
            SwitchListTile(value: notificationsEnabled, onChanged: (value) { setState(() => notificationsEnabled = value); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value ? 'تم تفعيل الإشعارات في هذه الجلسة.' : 'تم إيقاف الإشعارات في هذه الجلسة.'))); }, title: const Text('الإشعارات'), subtitle: const Text('تفضيل محفوظ في Demo Mode للجلسة الحالية'), secondary: const Icon(Icons.notifications_outlined)),
            const ListTile(leading: Icon(Icons.language), title: Text('اللغة'), subtitle: Text('العربية — RTL (اللغة الأساسية)')),
            const ListTile(leading: Icon(Icons.palette_outlined), title: Text('المظهر'), subtitle: Text('هوية عسلكم الفاتحة — تخصيص السمات يحتاج إعداد الإنتاج')),
            ListTile(leading: const Icon(Icons.lock_outline), title: const Text('الخصوصية والأمان'), subtitle: const Text('صلاحيات الحساب وبيانات التواصل'), onTap: () => showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('الخصوصية والأمان'), content: const Text('في Demo لا تُرسل بياناتك إلى خادم. في Production ستُفرض الصلاحيات من Auth وRLS.'), actions: [FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('حسنًا'))]))),
            ListTile(leading: const Icon(Icons.info_outline), title: const Text('عن عسلكم'), subtitle: const Text('منصة اكتشاف وتواصل للعسل اليمني'), onTap: () => showAboutDialog(context: context, applicationName: 'عسلكم', applicationVersion: 'Customer App', children: [const Text('اكتشاف وتواصل وطلبات مباشرة، وليس Checkout تقليديًا.')]))
          ])),
        ]),
      );
}

class BecomeMerchantScreen extends StatefulWidget {
  const BecomeMerchantScreen({super.key, required this.repository});
  final AssalRepository repository;

  @override
  State<BecomeMerchantScreen> createState() => _BecomeMerchantScreenState();
}

class _BecomeMerchantScreenState extends State<BecomeMerchantScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final experienceController = TextEditingController();
  final locationController = TextEditingController();
  final specialtiesController = TextEditingController();
  final certificateController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    experienceController.dispose();
    locationController.dispose();
    specialtiesController.dispose();
    certificateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('كن تاجرًا')),
        body: ListView(padding: const EdgeInsets.all(AssalSpacing.xl), children: [
          const AssalImageTile(height: 180, icon: Icons.storefront_outlined),
          const SizedBox(height: AssalSpacing.xl),
          Text('حوّل خبرتك إلى متجر موثوق', style: AssalTypography.heading1.copyWith(color: AssalColors.deepBrown)),
          const SizedBox(height: AssalSpacing.sm),
          Text('قدّم معلومات نشاطك ومصدر منتجاتك. لا يوجد Checkout؛ الطلب ينتقل إلى مراجعة التحقق والتواصل.', style: AssalTypography.bodyLarge.copyWith(color: AssalColors.textSecondary)),
          const SizedBox(height: AssalSpacing.xl),
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم النشاط أو المتجر')),
          const SizedBox(height: AssalSpacing.md),
          TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم التواصل')),
          const SizedBox(height: AssalSpacing.md),
          TextField(controller: experienceController, maxLines: 2, decoration: const InputDecoration(labelText: 'الخبرة في العسل ومصدره')),
          const SizedBox(height: AssalSpacing.md),
          TextField(controller: locationController, decoration: const InputDecoration(labelText: 'المحافظة / الموقع')),
          const SizedBox(height: AssalSpacing.md),
          TextField(controller: specialtiesController, decoration: const InputDecoration(labelText: 'التخصصات والأنواع')),
          const SizedBox(height: AssalSpacing.md),
          TextField(controller: certificateController, maxLines: 2, decoration: const InputDecoration(labelText: 'الشهادات أو معلومات المصدر (اختياري)')),
          const SizedBox(height: AssalSpacing.xl),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: loading ? null : _submit, icon: const Icon(Icons.send_outlined), label: Text(loading ? 'جارٍ الإرسال…' : 'إرسال طلب التحقق'))),
        ]),
      );

  Future<void> _submit() async {
    final session = await widget.repository.getSession();
    if (!session.isAuthenticated || session.user == null) {
      if (mounted) await openAuth(context, widget.repository);
      return;
    }
    setState(() => loading = true);
    final result = await widget.repository.submitMerchantApplication(session.user!.id, AssalMerchantApplicationDraft(displayName: nameController.text, phone: phoneController.text, experience: experienceController.text, location: locationController.text, specialties: specialtiesController.text, certificateNote: certificateController.text.trim().isEmpty ? null : certificateController.text.trim()));
    if (!mounted) return;
    setState(() => loading = false);
    if (result is AssalData<AssalMerchantApplicationSummary>) {
      await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('تم استلام طلبك'), content: Text('رقم الطلب: ${result.value.id}\nالحالة: قيد المراجعة'), actions: [FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('حسنًا'))]));
    } else if (result is AssalError<AssalMerchantApplicationSummary>) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.messageAr)));
    }
  }
}
