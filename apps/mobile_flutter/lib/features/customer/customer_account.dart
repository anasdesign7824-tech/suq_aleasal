import 'package:flutter/material.dart';
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
  final emailController = TextEditingController(text: 'demo@assalkom.app');
  final passwordController = TextEditingController(text: 'demo123');
  bool registerMode = false;
  bool loading = false;
  @override
  void dispose() { nameController.dispose(); emailController.dispose(); passwordController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(registerMode ? 'إنشاء حساب' : 'تسجيل الدخول')), body: ListView(padding: const EdgeInsets.all(AssalSpacing.xl), children: [const AssalBrandMark(size: 66), const SizedBox(height: AssalSpacing.xl), Text(registerMode ? 'أنشئ حسابك في عسلكم' : 'أهلًا بك في عسلكم', style: AssalTypography.heading1.copyWith(color: AssalColors.deepBrown)), const SizedBox(height: AssalSpacing.sm), Text('يمكنك التصفح كزائر، والحساب يفتح لك الحفظ والمتابعة والطلبات والمراسلة.', style: AssalTypography.bodyLarge.copyWith(color: AssalColors.textSecondary)), const SizedBox(height: AssalSpacing.xl), if (registerMode) ...[TextField(controller: nameController, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'الاسم')) , const SizedBox(height: AssalSpacing.md)], TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')), const SizedBox(height: AssalSpacing.md), TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور')), const SizedBox(height: AssalSpacing.lg), SizedBox(width: double.infinity, child: FilledButton(onPressed: loading ? null : _submit, child: loading ? const CircularProgressIndicator() : Text(registerMode ? 'إنشاء الحساب' : 'تسجيل الدخول'))), TextButton(onPressed: () => setState(() => registerMode = !registerMode), child: Text(registerMode ? 'لديك حساب؟ تسجيل الدخول' : 'ليس لديك حساب؟ إنشاء حساب')), TextButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سنرسل رابط الاستعادة عند ربط مزود المصادقة الإنتاجي.'))), child: const Text('نسيت كلمة المرور؟'))]));
  Future<void> _submit() async { setState(() => loading = true); final result = registerMode ? await widget.repository.register(nameController.text, emailController.text, passwordController.text) : await widget.repository.signIn(emailController.text, passwordController.text); if (!mounted) return; setState(() => loading = false); if (result is AssalData<AssalSession>) { Navigator.pop(context); } else if (result is AssalError<AssalSession>) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.messageAr))); } }
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
      Expanded(child: FilledButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BecomeMerchantScreen())), icon: const Icon(Icons.storefront_outlined), label: const Text('كن تاجرًا'))),
    ]),
    const SizedBox(height: AssalSpacing.sm),
    OutlinedButton.icon(onPressed: () async { await repository.signOut(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الخروج من Demo Mode'))); }, icon: const Icon(Icons.logout), label: const Text('تسجيل الخروج')),
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
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
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
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return AssalStateView<List<AssalNotificationSummary>>(
                state: snapshot.data!,
                builder: (items) => ListView.separated(
                  padding: const EdgeInsets.all(AssalSpacing.lg),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, index) => ListTile(
                    leading: const CircleAvatar(backgroundColor: AssalColors.honeyLight, child: Icon(Icons.notifications_none, color: AssalColors.primaryDark)),
                    title: Text(items[index].titleAr),
                    subtitle: Text(items[index].bodyAr ?? ''),
                  ),
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
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
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
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
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

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(padding: const EdgeInsets.all(AssalSpacing.lg), children: [
        Card(child: Column(children: [
          SwitchListTile(value: true, onChanged: (value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value ? 'تم تفعيل الإشعارات في Demo Mode' : 'تم إيقاف الإشعارات في Demo Mode'))), title: const Text('الإشعارات'), secondary: const Icon(Icons.notifications_outlined)),
          const ListTile(leading: Icon(Icons.language), title: Text('اللغة'), subtitle: Text('العربية — RTL')),
          const ListTile(leading: Icon(Icons.palette_outlined), title: Text('المظهر'), subtitle: Text('هوية عسلكم الفاتحة')),
          const ListTile(leading: Icon(Icons.lock_outline), title: Text('الخصوصية والأمان'), subtitle: Text('إعدادات الحساب والصلاحيات')),
          const ListTile(leading: Icon(Icons.info_outline), title: Text('عن عسلكم'), subtitle: Text('منصة اكتشاف وتواصل للعسل اليمني')),
        ])),
      ]),
    );
  }
}

class BecomeMerchantScreen extends StatelessWidget {
  const BecomeMerchantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const steps = ['التعريف بنشاطك وخبرتك', 'إضافة بيانات المتجر وموقعه', 'إرفاق الشهادات ومعلومات المصدر', 'مراجعة التحقق ثم فتح لوحة التاجر'];
    return Scaffold(
      appBar: AppBar(title: const Text('كن تاجرًا')),
      body: ListView(padding: const EdgeInsets.all(AssalSpacing.xl), children: [
        const AssalImageTile(height: 180, icon: Icons.storefront_outlined),
        const SizedBox(height: AssalSpacing.xl),
        Text('حوّل خبرتك إلى متجر موثوق', style: AssalTypography.heading1.copyWith(color: AssalColors.deepBrown)),
        const SizedBox(height: AssalSpacing.sm),
        Text('مسار واضح من التعريف بك إلى إنشاء المتجر ثم التحقق، دون خلطه بتجربة التصفح.', style: AssalTypography.bodyLarge.copyWith(color: AssalColors.textSecondary)),
        const SizedBox(height: AssalSpacing.xl),
        ...steps.asMap().entries.map<Widget>((entry) => ListTile(leading: CircleAvatar(backgroundColor: AssalColors.honeyLight, child: Text('${entry.key + 1}')), title: Text(entry.value), subtitle: const Text('خطوة محفوظة في Demo Mode'))),
        const SizedBox(height: AssalSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('تم بدء مسار التاجر'),
                content: const Text('في Demo Mode تم حفظ الخطوات. في Production ستنتقل البيانات إلى مراجعة التحقق.'),
                actions: [FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('حسنًا'))],
              ),
            ),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('ابدأ طلب التحول إلى تاجر'),
          ),
        ),
      ]),
    );
  }
}
