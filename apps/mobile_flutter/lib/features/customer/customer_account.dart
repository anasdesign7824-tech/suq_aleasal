import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final confirmPasswordController = TextEditingController();
  final otpController = TextEditingController();
  bool registerMode = false;
  bool loading = false;
  String? _authNotice;
  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(registerMode ? 'إنشاء حساب' : 'تسجيل الدخول')),
      body: ListView(padding: const EdgeInsets.all(AssalSpacing.xl), children: [
        const AssalBrandMark(size: 66),
        const SizedBox(height: AssalSpacing.xl),
        Text(registerMode ? 'أنشئ حسابك في عسلكم' : 'أهلًا بك في عسلكم',
            style: AssalTypography.heading1
                .copyWith(color: AssalColors.deepBrown)),
        const SizedBox(height: AssalSpacing.sm),
        Text(
            'يمكنك التصفح كزائر، والحساب يفتح لك الحفظ والمتابعة والطلبات والمراسلة.',
            style: AssalTypography.bodyLarge
                .copyWith(color: AssalColors.textSecondary)),
        const SizedBox(height: AssalSpacing.xl),
        if (_authNotice != null) ...[
          Container(
            padding: const EdgeInsets.all(AssalSpacing.md),
            decoration: BoxDecoration(
              color: AssalColors.honeyLight,
              borderRadius: BorderRadius.circular(AssalRadius.medium),
              border: Border.all(color: AssalColors.primary.withAlpha(80)),
            ),
            child: Text(_authNotice!,
                style: AssalTypography.body.copyWith(
                    color: AssalColors.deepBrown, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: AssalSpacing.md),
        ],
        if (registerMode) ...[
          TextField(
              controller: nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'الاسم')),
          const SizedBox(height: AssalSpacing.md)
        ],
        TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
        const SizedBox(height: AssalSpacing.md),
        TextField(
            controller: passwordController,
            obscureText: true,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'[A-Za-z0-9!@#\$%^&*()_+\-=\[\]{};:"\\|,.<>/?]')),
            ],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'كلمة المرور',
              filled: registerMode,
              fillColor: registerMode
                  ? (_passwordIsStrong(passwordController.text)
                      ? AssalColors.success.withAlpha(18)
                      : AssalColors.error.withAlpha(12))
                  : null,
              enabledBorder: registerMode
                  ? OutlineInputBorder(
                      borderSide: BorderSide(
                          color: _passwordIsStrong(passwordController.text)
                              ? AssalColors.success
                              : AssalColors.error))
                  : null,
              focusedBorder: registerMode
                  ? OutlineInputBorder(
                      borderSide: BorderSide(
                          color: _passwordIsStrong(passwordController.text)
                              ? AssalColors.success
                              : AssalColors.error,
                          width: 2))
                  : null,
            )),
        if (registerMode) ...[
          const SizedBox(height: AssalSpacing.sm),
          _PasswordStrength(value: passwordController.text),
          const SizedBox(height: AssalSpacing.md),
          TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'))
        ],
        const SizedBox(height: AssalSpacing.lg),
        SizedBox(
            width: double.infinity,
            child: FilledButton(
                onPressed: loading ? null : _submit,
                child: loading
                    ? const SizedBox(
                        height: 44,
                        child: AssalGlassLoading(
                            height: 44, label: 'جارٍ تسجيل الدخول...'))
                    : Text(registerMode ? 'إنشاء الحساب' : 'تسجيل الدخول'))),
        if (!registerMode) ...[
          TextButton(
              onPressed: loading ? null : _requestPasswordReset,
              child: const Text('نسيت كلمة المرور؟')),
        ],
        TextButton(
            onPressed: loading
                ? null
                : () => setState(() {
                      registerMode = !registerMode;
                      otpController.clear();
                      _authNotice = null;
                    }),
            child: Text(registerMode
                ? 'لديك حساب؟ تسجيل الدخول'
                : 'ليس لديك حساب؟ إنشاء حساب'))
      ]));
  Future<void> _submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أدخل بريدًا إلكترونيًا صالحًا.')));
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(registerMode
              ? 'اختر كلمة مرور قوية أولًا.'
              : 'أدخل كلمة المرور للمتابعة.')));
      return;
    }
    if (registerMode && !_passwordIsStrong(password)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'اختر كلمة مرور أقوى: 8 أحرف على الأقل، بحروف إنجليزية وأرقام ورمز خاص.')));
      return;
    }
    if (registerMode && nameController.text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أدخل اسمًا لا يقل عن حرفين.')));
      return;
    }
    if (registerMode &&
        confirmPasswordController.text != passwordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('كلمتا المرور غير متطابقتين.')));
      return;
    }
    setState(() => loading = true);
    final result = registerMode
        ? await widget.repository.register(
            nameController.text, emailController.text, passwordController.text)
        : await widget.repository
            .signIn(emailController.text, passwordController.text);
    if (!mounted) return;
    setState(() => loading = false);
    if (result is AssalError<AssalSession> &&
        (result.code == 'email_confirmation_required' ||
            result.code == 'email_not_confirmed')) {
      setState(() {
        // The OTP dialog is the only next step. Clear all
        // credential fields so the password is never shown
        // again after registration has been submitted.
        registerMode = false;
        _authNotice = result.code == 'email_not_confirmed'
            ? 'أكد بريدك الإلكتروني لإكمال تسجيل الدخول.'
            : 'تم إنشاء الحساب. أدخل الرمز المرسل إلى بريدك الإلكتروني.';
        passwordController.clear();
        confirmPasswordController.clear();
      });
      await _showEmailOtpDialog();
      return;
    }
    if (result is AssalData<AssalSession>) {
      Navigator.pop(context, true);
    } else if (result is AssalError<AssalSession>) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.messageAr)));
    }
  }

  Future<void> _showEmailOtpDialog() async {
    final email = emailController.text.trim();
    otpController.clear();
    var dialogLoading = false;
    String? dialogError;
    String? dialogNotice;
    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('تأكيد البريد الإلكتروني'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AssalBrandMark(size: 54),
                const SizedBox(height: AssalSpacing.sm),
                Text('أرسلنا رمز التحقق إلى\\n$email',
                    textAlign: TextAlign.center, style: AssalTypography.body),
                const SizedBox(height: AssalSpacing.md),
                TextField(
                  controller: otpController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  maxLength: 9,
                  textInputAction: TextInputAction.done,
                  textAlign: TextAlign.center,
                  style: AssalTypography.heading2
                      .copyWith(color: AssalColors.deepBrown, letterSpacing: 5),
                  decoration: const InputDecoration(
                      labelText: 'رمز التحقق (6–9 أرقام)', counterText: ''),
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: AssalSpacing.sm),
                  Text(dialogError!,
                      textAlign: TextAlign.center,
                      style: AssalTypography.caption
                          .copyWith(color: AssalColors.error)),
                ],
                if (dialogNotice != null) ...[
                  const SizedBox(height: AssalSpacing.sm),
                  Text(dialogNotice!,
                      textAlign: TextAlign.center,
                      style: AssalTypography.caption
                          .copyWith(color: AssalColors.success)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: dialogLoading
                    ? null
                    : () async {
                        setDialogState(() {
                          dialogLoading = true;
                          dialogError = null;
                          dialogNotice = null;
                        });
                        final result = await widget.repository
                            .resendEmailConfirmation(email);
                        if (!mounted || !dialogContext.mounted) return;
                        setDialogState(() {
                          dialogLoading = false;
                          if (result is AssalData<void>) {
                            dialogNotice =
                                'تم إرسال رمز جديد. استخدم أحدث رمز فقط.';
                          } else if (result is AssalError<void>) {
                            dialogError = result.messageAr;
                          }
                        });
                      },
                child: const Text('إعادة إرسال الرمز'),
              ),
              FilledButton(
                onPressed: dialogLoading
                    ? null
                    : () async {
                        final token = otpController.text.trim();
                        if (!RegExp(r'^\d{6,9}$').hasMatch(token)) {
                          setDialogState(() => dialogError =
                              'أدخل رمز التحقق كاملًا (من 6 إلى 9 أرقام).');
                          return;
                        }
                        setDialogState(() {
                          dialogLoading = true;
                          dialogError = null;
                          dialogNotice = null;
                        });
                        final result = await widget.repository
                            .verifyEmailConfirmation(email, token);
                        if (!mounted || !dialogContext.mounted) return;
                        if (result is AssalData<AssalSession>) {
                          Navigator.of(dialogContext).pop(true);
                        } else if (result is AssalError<AssalSession>) {
                          setDialogState(() {
                            dialogLoading = false;
                            dialogError = result.messageAr;
                          });
                        }
                      },
                child: dialogLoading
                    ? const AssalGlassLoading(
                        height: 44, label: 'جارٍ التحقق...')
                    : const Text('تحقق من الرمز'),
              ),
            ],
          ),
        ),
      ),
    );
    if (verified == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _requestPasswordReset() async {
    final email = emailController.text.trim();
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('أدخل بريدك الإلكتروني أولًا لإرسال رابط إعادة التعيين.')));
      return;
    }
    setState(() => loading = true);
    final result = await widget.repository.requestPasswordReset(email);
    if (!mounted) return;
    setState(() => loading = false);
    if (result is AssalData<void>) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.')));
    } else if (result is AssalError<void>) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.messageAr)));
    }
  }
}

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    final checks = <({String label, bool valid})>[
      (label: '8 أحرف على الأقل', valid: value.length >= 8),
      (label: 'حرف إنجليزي', valid: RegExp(r'[A-Za-z]').hasMatch(value)),
      (label: 'رقم إنجليزي', valid: RegExp(r'[0-9]').hasMatch(value)),
      (
        label: 'رمز خاص إنجليزي',
        valid: RegExp(r'[!@#\$%^&*()_+\-=\[\]{};:"\\|,.<>/?]').hasMatch(value)
      ),
    ];
    final asciiOnly =
        value.isEmpty || RegExp(r'^[\x21-\x7E]+$').hasMatch(value);
    final strong = asciiOnly && checks.every((check) => check.valid);
    final color = strong ? AssalColors.success : AssalColors.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AssalSpacing.sm),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(AssalRadius.medium),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            !asciiOnly && value.isNotEmpty
                ? 'استخدم الحروف الإنجليزية والأرقام والرموز فقط'
                : (strong ? 'كلمة المرور قوية' : 'كلمة المرور تحتاج إلى تقوية'),
            style: AssalTypography.caption
                .copyWith(color: color, fontWeight: FontWeight.w700)),
        const SizedBox(height: AssalSpacing.xs),
        Wrap(
          spacing: AssalSpacing.sm,
          runSpacing: AssalSpacing.xs,
          children: checks
              .map((check) => Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(check.valid ? Icons.check_circle : Icons.cancel,
                        size: 15,
                        color: check.valid
                            ? AssalColors.success
                            : AssalColors.error),
                    const SizedBox(width: 3),
                    Text(check.label,
                        style: AssalTypography.caption.copyWith(
                            color: check.valid
                                ? AssalColors.success
                                : AssalColors.error)),
                  ]))
              .toList(),
        ),
      ]),
    );
  }
}

bool _passwordIsStrong(String value) {
  if (value.length < 8 || !RegExp(r'^[\x21-\x7E]+$').hasMatch(value)) {
    return false;
  }
  return RegExp(r'[A-Za-z]').hasMatch(value) &&
      RegExp(r'[0-9]').hasMatch(value) &&
      RegExp(r'[!@#\$%^&*()_+\-=\[\]{};:"\\|,.<>/?]').hasMatch(value);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.repository});
  final AssalRepository repository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AssalRepository get repository => widget.repository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AssalSession>(
      future: repository.getSession(),
      builder: (context, snapshot) {
        final session = snapshot.data ?? AssalSession.guest;
        return ListView(
            padding: const EdgeInsets.all(AssalSpacing.lg),
            children: [
              const AssalBrandMark(),
              const SizedBox(height: AssalSpacing.xl),
              session.isAuthenticated
                  ? _authenticated(context, session)
                  : _guest(context),
              const SizedBox(height: AssalSpacing.lg),
              Card(
                  child: Column(children: [
                ListTile(
                    leading: const Icon(Icons.bookmarks_outlined),
                    title: const Text('المحفوظات والمتاجر المتابَعة'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            FavoritesScreen(repository: repository)))),
                ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('الإشعارات'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            NotificationsScreen(repository: repository)))),
                ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('الإعدادات'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const SettingsScreen()))),
                ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('الدعم والتعريف بعسلكم'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => showAboutDialog(
                            context: context,
                            applicationName: 'عسلكم',
                            applicationVersion: 'Demo',
                            children: [
                              const Text(
                                  'منصة اكتشاف وتواصل للعسل اليمني من مصدره.')
                            ]))
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
          const CircleAvatar(
              radius: 34,
              backgroundColor: AssalColors.honeyLight,
              child: Icon(Icons.person_outline,
                  size: 36, color: AssalColors.primaryDark)),
          const SizedBox(height: AssalSpacing.md),
          Text('تصفح كزائر',
              style: AssalTypography.heading2
                  .copyWith(color: AssalColors.deepBrown)),
          const SizedBox(height: AssalSpacing.sm),
          const Text('احفظ ما يعجبك وأرسل طلباتك عند إنشاء حساب مجاني.'),
          const SizedBox(height: AssalSpacing.lg),
          FilledButton(
              onPressed: () async {
                final authenticated = await openAuth(context, repository);
                if (mounted && authenticated) setState(() {});
              },
              child: const Text('تسجيل الدخول أو إنشاء حساب')),
        ]),
      ),
    );
  }

  Widget _authenticated(BuildContext context, AssalSession session) =>
      Column(children: [
        CircleAvatar(
            radius: 38,
            backgroundColor: AssalColors.honeyLight,
            child: Text((session.user?.nameAr ?? 'ع').substring(0, 1),
                style: AssalTypography.heading1
                    .copyWith(color: AssalColors.primaryDark))),
        const SizedBox(height: AssalSpacing.md),
        Text(session.user?.nameAr ?? 'عميل عسلكم',
            style: AssalTypography.heading2
                .copyWith(color: AssalColors.deepBrown)),
        Text(session.user?.email ?? '',
            style: AssalTypography.body
                .copyWith(color: AssalColors.textSecondary)),
        const SizedBox(height: AssalSpacing.lg),
        _ProfileStats(
            repository: repository,
            userId: session.user?.id ?? 'demo-customer'),
        const SizedBox(height: AssalSpacing.lg),
        Row(children: [
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => RequestsScreen(repository: repository))),
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text('طلباتي'))),
          const SizedBox(width: AssalSpacing.sm),
          Expanded(
              child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          BecomeMerchantScreen(repository: repository))),
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text('كن تاجرًا'))),
        ]),
        const SizedBox(height: AssalSpacing.sm),
        OutlinedButton.icon(
            onPressed: () async {
              final result = await repository.signOut();
              if (context.mounted) {
                if (result is AssalData<void>) {
                  setState(() {});
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(result is AssalError<void>
                        ? result.messageAr
                        : (repository.mode == AssalDataSourceMode.demo
                            ? 'تم تسجيل الخروج من Demo Mode'
                            : 'تم تسجيل الخروج.'))));
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('تسجيل الخروج')),
        const SizedBox(height: AssalSpacing.xs),
        TextButton.icon(
          onPressed: () => _deleteAccount(context),
          icon: const Icon(Icons.delete_outline, color: AssalColors.error),
          label: const Text('حذف الحساب',
              style: TextStyle(color: AssalColors.error)),
        ),
      ]);

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الحساب؟'),
        content: const Text(
            'سيتم حذف حسابك وبياناته المرتبطة نهائيًا. لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('حذف الحساب')),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await repository.deleteAccount();
    if (!context.mounted) return;
    if (result is AssalData<void>) {
      if (context.mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الحساب وتسجيل الخروج.')));
      }
    } else if (result is AssalError<void>) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.messageAr)));
    }
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.repository, required this.userId});
  final AssalRepository repository;
  final String userId;

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<AssalLoadState<Object?>>>(
        future: Future.wait<Object?>([
          repository.listFollowedStores(userId),
          repository.listFavoriteProducts(userId),
          repository.listRequests(userId)
        ]).then((states) => states.cast<AssalLoadState<Object?>>()),
        builder: (context, snapshot) {
          final values = snapshot.data ?? const <AssalLoadState<Object?>>[];
          int countAt(int index) {
            if (index >= values.length) return 0;
            final state = values[index];
            return state is AssalData && state.value is List
                ? (state.value as List).length
                : 0;
          }

          return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _metric('${countAt(0)}', 'المتابعات'),
                _metric('${countAt(1)}', 'المحفوظات'),
                _metric('${countAt(2)}', 'الطلبات')
              ]);
        },
      );

  Widget _metric(String value, String label) => Column(children: [
        Text(value,
            style: AssalTypography.heading3
                .copyWith(color: AssalColors.deepBrown)),
        Text(label,
            style:
                AssalTypography.caption.copyWith(color: AssalColors.textMuted))
      ]);
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
            return Center(
                child: FilledButton(
                    onPressed: () => openAuth(context, repository),
                    child: const Text('تسجيل الدخول لمتابعة الطلبات')));
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
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AssalSpacing.sm),
                  itemBuilder: (_, index) {
                    final request = requests[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                            backgroundColor: AssalColors.honeyLight,
                            child: Icon(Icons.assignment_outlined,
                                color: AssalColors.primaryDark)),
                        title: Text(request.subject),
                        subtitle: Text(
                            '${request.storeName ?? request.storeId} · ${request.preferredHandoffOption ?? 'تواصل مباشر'}'),
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
            return Center(
                child: FilledButton(
                    onPressed: () => openAuth(context, repository),
                    child: const Text('تسجيل الدخول لعرض إشعاراتك')));
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
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return ListTile(
                      tileColor: item.readAt == null ? AssalColors.cream : null,
                      leading: CircleAvatar(
                          backgroundColor: AssalColors.honeyLight,
                          child: Icon(
                              item.readAt == null
                                  ? Icons.notifications_active_outlined
                                  : Icons.notifications_none,
                              color: AssalColors.primaryDark)),
                      title: Text(item.titleAr,
                          style: item.readAt == null
                              ? const TextStyle(fontWeight: FontWeight.w700)
                              : null),
                      subtitle: Text(item.bodyAr ?? ''),
                      onTap: () async {
                        await repository.markNotificationRead(
                            session.user!.id, item.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('تم تعليم الإشعار كمقروء.')));
                        }
                      },
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

class ConversationScreen extends StatefulWidget {
  const ConversationScreen(
      {super.key, required this.repository, required this.conversation});
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
                      alignment: message.isMine
                          ? AlignmentDirectional.centerStart
                          : AlignmentDirectional.centerEnd,
                      child: Card(
                        color: message.isMine
                            ? AssalColors.honeyLight
                            : AssalColors.surfaceVariant,
                        child: Padding(
                            padding: const EdgeInsets.all(AssalSpacing.md),
                            child: Text(message.body)),
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
              Expanded(
                  child: TextField(
                      controller: controller,
                      maxLines: 3,
                      minLines: 1,
                      decoration:
                          const InputDecoration(hintText: 'اكتب رسالتك'))),
              IconButton(
                  onPressed: _send,
                  icon: const Icon(Icons.send_rounded),
                  tooltip: 'إرسال'),
            ]),
          ),
        ),
      ]),
    );
  }

  Future<void> _send() async {
    final body = controller.text.trim();
    if (body.isEmpty) return;
    await widget.repository.sendMessage('demo-customer',
        AssalMessageDraft(conversationId: widget.conversation.id, body: body));
    controller.clear();
    setState(
        () => future = widget.repository.listMessages(widget.conversation.id));
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
          if (!session.isAuthenticated) {
            return Center(
                child: FilledButton(
                    onPressed: () => openAuth(context, repository),
                    child: const Text('تسجيل الدخول لعرض المراسلات')));
          }
          return FutureBuilder<AssalLoadState<List<AssalConversationSummary>>>(
            future: repository.listConversations(session.user!.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const AssalGlassLoading();
              return AssalStateView<List<AssalConversationSummary>>(
                state: snapshot.data!,
                builder: (items) => ListView.separated(
                  padding: const EdgeInsets.all(AssalSpacing.lg),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AssalSpacing.sm),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                            backgroundColor: AssalColors.honeyLight,
                            child: Icon(Icons.storefront_outlined,
                                color: AssalColors.primaryDark)),
                        title: Text(item.storeName),
                        subtitle: Text(item.lastMessage),
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => ConversationScreen(
                                    repository: repository,
                                    conversation: item))),
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
        body:
            ListView(padding: const EdgeInsets.all(AssalSpacing.lg), children: [
          Card(
              child: Column(children: [
            SwitchListTile(
                value: notificationsEnabled,
                onChanged: (value) {
                  setState(() => notificationsEnabled = value);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(value
                          ? 'تم تفعيل الإشعارات في هذه الجلسة.'
                          : 'تم إيقاف الإشعارات في هذه الجلسة.')));
                },
                title: const Text('الإشعارات'),
                subtitle: const Text('تفضيل محفوظ في Demo Mode للجلسة الحالية'),
                secondary: const Icon(Icons.notifications_outlined)),
            const ListTile(
                leading: Icon(Icons.language),
                title: Text('اللغة'),
                subtitle: Text('العربية — RTL (اللغة الأساسية)')),
            const ListTile(
                leading: Icon(Icons.palette_outlined),
                title: Text('المظهر'),
                subtitle: Text(
                    'هوية عسلكم الفاتحة — تخصيص السمات يحتاج إعداد الإنتاج')),
            ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('الخصوصية والأمان'),
                subtitle: const Text('صلاحيات الحساب وبيانات التواصل'),
                onTap: () => showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                            title: const Text('الخصوصية والأمان'),
                            content: const Text(
                                'في Demo لا تُرسل بياناتك إلى خادم. في Production ستُفرض الصلاحيات من Auth وRLS.'),
                            actions: [
                              FilledButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('حسنًا'))
                            ]))),
            ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('عن عسلكم'),
                subtitle: const Text('منصة اكتشاف وتواصل للعسل اليمني'),
                onTap: () => showAboutDialog(
                        context: context,
                        applicationName: 'عسلكم',
                        applicationVersion: 'Customer App',
                        children: [
                          const Text(
                              'اكتشاف وتواصل وطلبات مباشرة، وليس Checkout تقليديًا.')
                        ]))
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
        body:
            ListView(padding: const EdgeInsets.all(AssalSpacing.xl), children: [
          const AssalImageTile(height: 180, icon: Icons.storefront_outlined),
          const SizedBox(height: AssalSpacing.xl),
          Text('حوّل خبرتك إلى متجر موثوق',
              style: AssalTypography.heading1
                  .copyWith(color: AssalColors.deepBrown)),
          const SizedBox(height: AssalSpacing.sm),
          Text(
              'قدّم معلومات نشاطك ومصدر منتجاتك. لا يوجد Checkout؛ الطلب ينتقل إلى مراجعة التحقق والتواصل.',
              style: AssalTypography.bodyLarge
                  .copyWith(color: AssalColors.textSecondary)),
          const SizedBox(height: AssalSpacing.xl),
          TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: 'اسم النشاط أو المتجر')),
          const SizedBox(height: AssalSpacing.md),
          TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'رقم التواصل')),
          const SizedBox(height: AssalSpacing.md),
          TextField(
              controller: experienceController,
              maxLines: 2,
              decoration:
                  const InputDecoration(labelText: 'الخبرة في العسل ومصدره')),
          const SizedBox(height: AssalSpacing.md),
          TextField(
              controller: locationController,
              decoration:
                  const InputDecoration(labelText: 'المحافظة / الموقع')),
          const SizedBox(height: AssalSpacing.md),
          TextField(
              controller: specialtiesController,
              decoration:
                  const InputDecoration(labelText: 'التخصصات والأنواع')),
          const SizedBox(height: AssalSpacing.md),
          TextField(
              controller: certificateController,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'الشهادات أو معلومات المصدر (اختياري)')),
          const SizedBox(height: AssalSpacing.xl),
          SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                  onPressed: loading ? null : _submit,
                  icon: const Icon(Icons.send_outlined),
                  label: Text(loading ? 'جارٍ الإرسال…' : 'إرسال طلب التحقق'))),
        ]),
      );

  Future<void> _submit() async {
    final session = await widget.repository.getSession();
    if (!session.isAuthenticated || session.user == null) {
      if (mounted) await openAuth(context, widget.repository);
      return;
    }
    setState(() => loading = true);
    final result = await widget.repository.submitMerchantApplication(
        session.user!.id,
        AssalMerchantApplicationDraft(
            displayName: nameController.text,
            phone: phoneController.text,
            experience: experienceController.text,
            location: locationController.text,
            specialties: specialtiesController.text,
            certificateNote: certificateController.text.trim().isEmpty
                ? null
                : certificateController.text.trim()));
    if (!mounted) return;
    setState(() => loading = false);
    if (result is AssalData<AssalMerchantApplicationSummary>) {
      await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
                  title: const Text('تم استلام طلبك'),
                  content: Text(
                      'رقم الطلب: ${result.value.id}\nالحالة: قيد المراجعة'),
                  actions: [
                    FilledButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('حسنًا'))
                  ]));
    } else if (result is AssalError<AssalMerchantApplicationSummary>) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.messageAr)));
    }
  }
}
