import 'package:flutter/material.dart';
import 'dart:async';

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
      appBar: AssalAppBar(
          title: registerMode ? 'إنشاء حساب' : 'تسجيل الدخول',
          showBrand: false),
      body: ListView(padding: const EdgeInsets.all(AssalSpacing.xl), children: [
        const Center(
          child: AssalBrandMark(size: 92, showName: false),
        ),
        const SizedBox(height: AssalSpacing.xl),
        Text(
          registerMode ? 'ابدأ تجربتك مع العسل' : 'مرحبًا بك من جديد',
          textAlign: TextAlign.center,
          style: AssalTypography.heading1.copyWith(
            color: AssalColors.deepBrown,
          ),
        ),
        const SizedBox(height: AssalSpacing.sm),
        Text(
          registerMode
              ? 'أنشئ حسابك للوصول إلى الحفظ والمتابعة والطلبات والمراسلة.'
              : 'سجّل دخولك بالبريد الإلكتروني، وسنرسل لك رمز التحقق.',
          textAlign: TextAlign.center,
          style: AssalTypography.bodyLarge.copyWith(
            color: AssalColors.textSecondary,
          ),
        ),
        const SizedBox(height: AssalSpacing.xl),
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
            textInputAction:
                registerMode ? TextInputAction.next : TextInputAction.done,
            decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
        if (registerMode) ...[
          const SizedBox(height: AssalSpacing.md),
          TextField(
              controller: passwordController,
              obscureText: true,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[A-Za-z0-9!@#\$%^&*()_+\-=[]{};:"\\|,.<>/?]')),
              ],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                filled: true,
                fillColor: _passwordIsStrong(passwordController.text)
                    ? AssalColors.success.withAlpha(18)
                    : AssalColors.error.withAlpha(12),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: _passwordIsStrong(passwordController.text)
                            ? AssalColors.success
                            : AssalColors.error)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: _passwordIsStrong(passwordController.text)
                            ? AssalColors.success
                            : AssalColors.error,
                        width: 2)),
              )),
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
                            height: 44, label: 'جارٍ تجهيز الطلب...'))
                    : Text(
                        registerMode ? 'إنشاء الحساب' : 'إرسال رمز الدخول'))),
        const SizedBox(height: AssalSpacing.sm),
        TextButton(
            onPressed: loading
                ? null
                : () => setState(() {
                      registerMode = !registerMode;
                      otpController.clear();
                    }),
            child: Text(registerMode
                ? 'لديك حساب؟ سجّل الدخول إلى حسابك الموجود'
                : 'ليس لديك حساب؟ أنشئ حسابًا جديدًا'))
      ]));
  Future<void> _submit() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أدخل بريدًا إلكترونيًا صالحًا.')));
      return;
    }
    if (registerMode) {
      final password = passwordController.text;
      if (!_passwordIsStrong(password)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'اختر كلمة مرور أقوى: 8 أحرف على الأقل، بحروف إنجليزية وأرقام ورمز خاص.')));
        return;
      }
      if (nameController.text.trim().length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('أدخل اسمًا لا يقل عن حرفين.')));
        return;
      }
      if (confirmPasswordController.text != password) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('كلمتا المرور غير متطابقتين.')));
        return;
      }
      setState(() => loading = true);
      final result = await widget.repository
          .register(nameController.text, emailController.text, password);
      if (!mounted) return;
      setState(() => loading = false);
      if (result is AssalError<AssalSession> &&
          (result.code == 'email_confirmation_required' ||
              result.code == 'email_not_confirmed')) {
        setState(() {
          registerMode = false;
          passwordController.clear();
          confirmPasswordController.clear();
        });
        await _showEmailOtpDialog(loginMode: false);
      } else if (result is AssalData<AssalSession>) {
        Navigator.pop(context, true);
      } else if (result is AssalError<AssalSession>) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result.messageAr)));
      }
      return;
    }

    // Existing-account login is passwordless by design: request the OTP
    // before showing the mandatory verification dialog.
    setState(() => loading = true);
    final result = await widget.repository.requestEmailOtp(email);
    if (!mounted) return;
    setState(() => loading = false);
    if (result is AssalData<void>) {
      await _showEmailOtpDialog(loginMode: true);
    } else if (result is AssalError<void>) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.messageAr)));
    }
  }

  Future<void> _showEmailOtpDialog({required bool loginMode}) async {
    final dialogEmailController =
        TextEditingController(text: emailController.text.trim());
    otpController.clear();
    var dialogLoading = false;
    var resendSeconds = 30;
    var countdownStarted = false;
    Timer? resendTimer;
    String? dialogError;
    String? dialogNotice;

    void startCountdown(void Function(void Function()) setDialogState) {
      resendTimer?.cancel();
      setDialogState(() => resendSeconds = 30);
      resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (resendSeconds <= 1) {
          timer.cancel();
          resendTimer = null;
          setDialogState(() => resendSeconds = 0);
        } else {
          setDialogState(() => resendSeconds -= 1);
        }
      });
    }

    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          if (!countdownStarted) {
            countdownStarted = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (dialogContext.mounted) startCountdown(setDialogState);
            });
          }
          return PopScope(
            canPop: false,
            child: AlertDialog(
              title: Text(loginMode ? 'رمز الدخول' : 'تأكيد البريد الإلكتروني'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AssalBrandMark(size: 54, showName: false),
                    const SizedBox(height: AssalSpacing.sm),
                    Text(
                        loginMode
                            ? 'أرسلنا رمز الدخول إلى'
                            : 'أرسلنا رمز التحقق إلى',
                        textAlign: TextAlign.center,
                        style: AssalTypography.body),
                    const SizedBox(height: AssalSpacing.sm),
                    TextField(
                      controller: dialogEmailController,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        helperText: 'يمكنك تعديل البريد قبل التحقق',
                      ),
                      onChanged: (_) => setDialogState(() {
                        dialogError = null;
                        dialogNotice = null;
                      }),
                    ),
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
                      textDirection: TextDirection.ltr,
                      style: AssalTypography.heading2.copyWith(
                          color: AssalColors.deepBrown, letterSpacing: 5),
                      decoration: const InputDecoration(
                          labelText: 'رمز التحقق (6–9 أرقام)', counterText: ''),
                    ),
                    Text(
                      resendSeconds > 0
                          ? 'يمكنك طلب رمز جديد بعد $resendSeconds ثانية'
                          : 'يمكنك طلب رمز جديد الآن',
                      textAlign: TextAlign.center,
                      style: AssalTypography.caption
                          .copyWith(color: AssalColors.textMuted),
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
              ),
              actions: [
                TextButton(
                  onPressed: dialogLoading || resendSeconds > 0
                      ? null
                      : () async {
                          final email = dialogEmailController.text.trim();
                          if (!email.contains('@')) {
                            setDialogState(() =>
                                dialogError = 'أدخل بريدًا إلكترونيًا صالحًا.');
                            return;
                          }
                          setDialogState(() {
                            dialogLoading = true;
                            dialogError = null;
                            dialogNotice = null;
                          });
                          final result = loginMode
                              ? await widget.repository.requestEmailOtp(email)
                              : await widget.repository
                                  .resendEmailConfirmation(email);
                          if (!mounted || !dialogContext.mounted) return;
                          setDialogState(() {
                            dialogLoading = false;
                            if (result is AssalData<void>) {
                              dialogNotice = loginMode
                                  ? 'تم إرسال رمز دخول جديد. استخدم أحدث رمز فقط.'
                                  : 'تم إرسال رمز تحقق جديد. استخدم أحدث رمز فقط.';
                            } else if (result is AssalError<void>) {
                              dialogError = result.messageAr;
                            }
                          });
                          if (result is AssalData<void>) {
                            startCountdown(setDialogState);
                          }
                        },
                  child: const Text('إعادة إرسال الرمز'),
                ),
                FilledButton(
                  onPressed: dialogLoading
                      ? null
                      : () async {
                          final token = otpController.text.trim();
                          final email = dialogEmailController.text.trim();
                          if (!email.contains('@')) {
                            setDialogState(() =>
                                dialogError = 'أدخل بريدًا إلكترونيًا صالحًا.');
                            return;
                          }
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
                          final result = loginMode
                              ? await widget.repository
                                  .verifyEmailOtp(email, token)
                              : await widget.repository
                                  .verifyEmailConfirmation(email, token);
                          if (!mounted || !dialogContext.mounted) return;
                          if (result is AssalData<AssalSession>) {
                            emailController.text = email;
                            resendTimer?.cancel();
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
                      : Text(loginMode ? 'دخول بالرمز' : 'تحقق من الرمز'),
                ),
              ],
            ),
          );
        },
      ),
    );
    resendTimer?.cancel();
    dialogEmailController.dispose();
    if (verified == true && mounted) {
      Navigator.pop(context, true);
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
      appBar: const AssalAppBar(title: 'طلباتي'),
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
      appBar: const AssalAppBar(title: 'الإشعارات'),
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
      appBar: AssalAppBar(title: widget.conversation.storeName),
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
      appBar: const AssalAppBar(title: 'المراسلات'),
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
        appBar: const AssalAppBar(title: 'الإعدادات'),
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
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final experienceController = TextEditingController();
  final locationController = TextEditingController();
  final specialtiesController = TextEditingController();
  final certificateController = TextEditingController();
  bool loading = false;
  bool draftLoading = true;
  String? draftUserId;
  AssalMerchantApplicationSummary? application;
  String? applicationLoadMessage;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

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
        appBar: const AssalAppBar(title: 'كن تاجرًا'),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(AssalSpacing.xl),
            children: [
              const AssalImageTile(
                  height: 180, icon: Icons.storefront_outlined),
              const SizedBox(height: AssalSpacing.xl),
              Text('حوّل خبرتك إلى متجر موثوق',
                  style: AssalTypography.heading1
                      .copyWith(color: AssalColors.deepBrown)),
              const SizedBox(height: AssalSpacing.sm),
              Text(
                  'قدّم معلومات نشاطك ومصدر منتجاتك. لا يوجد Checkout؛ الطلب ينتقل إلى مراجعة التحقق والتواصل.',
                  style: AssalTypography.bodyLarge
                      .copyWith(color: AssalColors.textSecondary)),
              const SizedBox(height: AssalSpacing.md),
              _VerificationStatusCard(
                status: application?.status,
                unavailableMessage: applicationLoadMessage,
              ),
              const SizedBox(height: AssalSpacing.md),
              Container(
                padding: const EdgeInsets.all(AssalSpacing.md),
                decoration: BoxDecoration(
                  color: AssalColors.cream,
                  borderRadius: BorderRadius.circular(AssalRadius.medium),
                  border: Border.all(color: AssalColors.border),
                ),
                child: Text(
                  'رفع المستندات غير متاح في هذه المرحلة. يمكنك إضافة معلومات المصدر أو الشهادات في الحقل الاختياري، وسيُفتح الرفع الحقيقي بعد تهيئة التخزين والمراجعة الإدارية.',
                  style: AssalTypography.caption
                      .copyWith(color: AssalColors.textSecondary),
                ),
              ),
              const SizedBox(height: AssalSpacing.sm),
              Text(
                draftLoading
                    ? 'جارٍ استعادة المسودة…'
                    : 'يمكنك حفظ المسودة أثناء جلسة التطبيق وإكمالها لاحقًا.',
                style: AssalTypography.caption
                    .copyWith(color: AssalColors.textSecondary),
              ),
              const SizedBox(height: AssalSpacing.xl),
              TextFormField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration:
                      const InputDecoration(labelText: 'اسم النشاط أو المتجر'),
                  validator: (value) => value == null || value.trim().length < 2
                      ? 'اكتب اسم النشاط أو المتجر (حرفان على الأقل).'
                      : null),
              const SizedBox(height: AssalSpacing.md),
              TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'رقم التواصل'),
                  validator: (value) => value == null || value.trim().length < 6
                      ? 'اكتب رقم تواصل صحيحًا (6 أرقام على الأقل).'
                      : null),
              const SizedBox(height: AssalSpacing.md),
              TextFormField(
                  controller: experienceController,
                  maxLines: 2,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                      labelText: 'الخبرة في العسل ومصدره'),
                  validator: (value) => value == null || value.trim().length < 4
                      ? 'اذكر خبرتك ومصدر منتجاتك باختصار.'
                      : null),
              const SizedBox(height: AssalSpacing.md),
              TextFormField(
                  controller: locationController,
                  textInputAction: TextInputAction.next,
                  decoration:
                      const InputDecoration(labelText: 'المحافظة / الموقع'),
                  validator: (value) => value == null || value.trim().length < 2
                      ? 'اكتب المحافظة أو الموقع.'
                      : null),
              const SizedBox(height: AssalSpacing.md),
              TextFormField(
                  controller: specialtiesController,
                  decoration:
                      const InputDecoration(labelText: 'التخصصات والأنواع'),
                  validator: (value) => value == null || value.trim().length < 2
                      ? 'اكتب تخصصًا واحدًا على الأقل.'
                      : null),
              const SizedBox(height: AssalSpacing.md),
              TextFormField(
                  controller: certificateController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'الشهادات أو معلومات المصدر (اختياري)')),
              const SizedBox(height: AssalSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: loading ? null : _saveDraft,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('حفظ المسودة الآن'),
                ),
              ),
              const SizedBox(height: AssalSpacing.xl),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                      onPressed: loading ? null : _submit,
                      icon: const Icon(Icons.send_outlined),
                      label: Text(
                          loading ? 'جارٍ الإرسال…' : 'إرسال طلب التحقق'))),
            ],
          ),
        ),
      );

  AssalMerchantApplicationDraft _draftFromForm() =>
      AssalMerchantApplicationDraft(
        displayName: nameController.text.trim(),
        phone: phoneController.text.trim(),
        experience: experienceController.text.trim(),
        location: locationController.text.trim(),
        specialties: specialtiesController.text.trim(),
        certificateNote: certificateController.text.trim().isEmpty
            ? null
            : certificateController.text.trim(),
      );

  Future<void> _restoreDraft() async {
    final session = await widget.repository.getSession();
    if (!session.isAuthenticated || session.user == null) {
      if (mounted) setState(() => draftLoading = false);
      return;
    }
    draftUserId = session.user!.id;
    final applicationResult = await widget.repository.loadMerchantApplication(
      draftUserId!,
    );
    if (!mounted) return;
    if (applicationResult is AssalData<AssalMerchantApplicationSummary?>) {
      application = applicationResult.value;
    } else if (applicationResult
        is AssalError<AssalMerchantApplicationSummary?>) {
      applicationLoadMessage = applicationResult.messageAr;
    }
    final result = await widget.repository.loadMerchantApplicationDraft(
      draftUserId!,
    );
    if (!mounted) return;
    if (result is AssalData<AssalMerchantApplicationDraft?> &&
        result.value != null) {
      final draft = result.value!;
      nameController.text = draft.displayName;
      phoneController.text = draft.phone;
      experienceController.text = draft.experience;
      locationController.text = draft.location;
      specialtiesController.text = draft.specialties;
      certificateController.text = draft.certificateNote ?? '';
    }
    setState(() => draftLoading = false);
  }

  Future<bool> _saveDraft({bool showFeedback = true}) async {
    final session = await widget.repository.getSession();
    if (!session.isAuthenticated || session.user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('سجّل الدخول أولًا لحفظ مسودة طلب التاجر.'),
        ));
      }
      return false;
    }
    draftUserId = session.user!.id;
    final result = await widget.repository.saveMerchantApplicationDraft(
      draftUserId!,
      _draftFromForm(),
    );
    if (!mounted) return result is AssalData<void>;
    if (showFeedback) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result is AssalData<void>
            ? 'تم حفظ المسودة ويمكنك إكمالها لاحقًا.'
            : result is AssalError<void>
                ? result.messageAr
                : 'تعذر حفظ المسودة الآن.'),
      ));
    }
    return result is AssalData<void>;
  }

  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('راجع الحقول الموضحة قبل إرسال الطلب.'),
      ));
      return;
    }
    final session = await widget.repository.getSession();
    if (!session.isAuthenticated || session.user == null) {
      if (mounted) await openAuth(context, widget.repository);
      return;
    }
    setState(() => loading = true);
    final draft = _draftFromForm();
    final result = await widget.repository.submitMerchantApplication(
      session.user!.id,
      draft,
    );
    if (!mounted) return;
    setState(() => loading = false);
    if (result is AssalData<AssalMerchantApplicationSummary>) {
      setState(() {
        application = result.value;
        applicationLoadMessage = null;
      });
      await widget.repository.clearMerchantApplicationDraft(session.user!.id);
      if (!mounted) return;
      await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
                  title: const Text('تم استلام طلبك'),
                  content: Text(
                      'رقم الطلب: ${result.value.id}\nالحالة: ${result.value.status}'),
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

class _VerificationStatusCard extends StatelessWidget {
  const _VerificationStatusCard({this.status, this.unavailableMessage});

  final String? status;
  final String? unavailableMessage;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'submitted' => 'تم الإرسال',
      'under_review' => 'قيد المراجعة',
      'verified' => 'موثق',
      'rejected' => 'مرفوض — يحتاج إلى تعديل',
      _ => 'لم يبدأ بعد',
    };
    final description = switch (status) {
      'submitted' => 'استلمنا الطلب وينتظر انتقاله إلى المراجعة.',
      'under_review' => 'يجري فريق التحقق مراجعة بيانات النشاط والمصدر.',
      'verified' => 'تم اعتماد النشاط كمتجر موثق.',
      'rejected' => 'راجع ملاحظات المراجعة ثم أرسل البيانات بعد تعديلها.',
      _ => 'أكمل البيانات ثم أرسل طلب فتح المتجر للبدء.',
    };
    return Container(
      padding: const EdgeInsets.all(AssalSpacing.md),
      decoration: BoxDecoration(
        color: AssalColors.surface,
        borderRadius: BorderRadius.circular(AssalRadius.medium),
        border: Border.all(color: AssalColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_outlined, color: AssalColors.honey),
          const SizedBox(width: AssalSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('حالة التوثيق', style: AssalTypography.caption),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AssalTypography.heading3
                      .copyWith(color: AssalColors.deepBrown),
                ),
                const SizedBox(height: 2),
                Text(
                  unavailableMessage ?? description,
                  style: AssalTypography.caption
                      .copyWith(color: AssalColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
