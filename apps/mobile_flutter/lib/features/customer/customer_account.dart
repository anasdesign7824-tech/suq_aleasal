import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_design/assal_tokens.dart';
import '../../core/assal_assets.dart';
import '../../core/assal_widgets.dart';

import 'customer_core.dart';
import 'customer_favorites.dart';
import 'customer_discovery.dart';
import 'customer_catalog.dart';
import 'customer_request_detail.dart';
import 'customer_support.dart';
import '../merchant/merchant_dashboard.dart';

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
        backgroundColor: AssalColors.cream,
        appBar: null,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AssalSpacing.xl,
              AssalSpacing.x2l,
              AssalSpacing.xl,
              AssalSpacing.x4l,
            ),
            children: [
              const Center(
                child: AssalBrandMark(
                  size: 116,
                  assetPath: AssalAssets.logoExternal,
                ),
              ),
              const SizedBox(height: AssalSpacing.sm),
              Text(
                'عسلكم',
                textAlign: TextAlign.center,
                style: AssalTypography.display.copyWith(
                  color: AssalColors.deepBrown,
                  fontSize: 34,
                ),
              ),
              const SizedBox(height: AssalSpacing.xs),
              Text(
                'من اليمن .. طبيعة أصيلة',
                textAlign: TextAlign.center,
                style: AssalTypography.body.copyWith(
                  color: AssalColors.textSecondary,
                ),
              ),
              const SizedBox(height: AssalSpacing.x3l),
              Text(
                registerMode
                    ? 'إنشاء وتأكيد كلمة المرور'
                    : 'مرحبًا بك في عسلكم',
                textAlign: TextAlign.center,
                style: AssalTypography.heading1.copyWith(
                  color: AssalColors.deepBrown,
                ),
              ),
              const SizedBox(height: AssalSpacing.sm),
              Text(
                registerMode
                    ? 'أنشئ كلمة مرورك. ستستخدمها لتأمين حسابك.'
                    : 'أدخل بريدك الإلكتروني للمتابعة',
                textAlign: TextAlign.center,
                style: AssalTypography.bodyLarge.copyWith(
                  color: AssalColors.textSecondary,
                ),
              ),
              const SizedBox(height: AssalSpacing.xl),
              if (registerMode) ...[
                TextField(
                    key: const ValueKey('auth-name'),
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'الاسم')),
                const SizedBox(height: AssalSpacing.md)
              ],
              TextField(
                  key: const ValueKey('auth-email'),
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: registerMode
                      ? TextInputAction.next
                      : TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    hintText: 'name@example.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  )),
              if (registerMode) ...[
                const SizedBox(height: AssalSpacing.md),
                TextField(
                    key: const ValueKey('auth-password'),
                    controller: passwordController,
                    obscureText: true,
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
                    key: const ValueKey('auth-password-confirm'),
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'تأكيد كلمة المرور'))
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
                          : Text(registerMode
                              ? 'حفظ ومتابعة'
                              : 'إرسال رمز التحقق'))),
              const SizedBox(height: AssalSpacing.sm),
              TextButton(
                onPressed: loading
                    ? null
                    : () => setState(() {
                          registerMode = !registerMode;
                          otpController.clear();
                        }),
                child: Text(registerMode ? 'تسجيل الدخول' : 'إنشاء حساب'),
              ),
              TextButton.icon(
                onPressed: loading
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => SupportCenterScreen(
                            repository: widget.repository,
                          ),
                        )),
                icon: const Icon(Icons.help_outline_rounded),
                label: const Text('المساعدة'),
              ),
            ],
          ),
        ),
      );

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
    var dialogEmail = emailController.text.trim();
    final dialogEmailController = TextEditingController(text: dialogEmail);
    otpController.clear();
    var editingEmail = false;
    var dialogLoading = false;

    var resendSeconds = 30;
    var countdownStarted = false;
    Timer? resendTimer;
    String? dialogError;
    String? dialogNotice;

    String maskEmail(String email) {
      final parts = email.split('@');
      if (parts.length != 2 || parts.first.isEmpty) return email;
      final visible = parts.first.characters.first;
      return '$visible••••••••@${parts.last}';
    }

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
                      loginMode ? 'تحقق من بريدك' : 'تأكيد بريدك الإلكتروني',
                      textAlign: TextAlign.center,
                      style: AssalTypography.heading2.copyWith(
                        color: AssalColors.deepBrown,
                      ),
                    ),
                    const SizedBox(height: AssalSpacing.xs),
                    Text(
                      loginMode
                          ? 'أرسلنا رمز التحقق إلى البريد المدخل'
                          : 'أرسلنا رمز التحقق إلى بريدك الإلكتروني',
                      textAlign: TextAlign.center,
                      style: AssalTypography.body.copyWith(
                        color: AssalColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AssalSpacing.md),
                    if (editingEmail)
                      TextField(
                        controller: dialogEmailController,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          helperText: 'يمكنك تعديل البريد قبل التحقق',
                        ),
                        onChanged: (value) => setDialogState(() {
                          dialogEmail = value;
                          dialogError = null;
                          dialogNotice = null;
                        }),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AssalSpacing.md,
                          vertical: AssalSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AssalColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(AssalRadius.pill),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                maskEmail(dialogEmail),
                                textDirection: TextDirection.ltr,
                                overflow: TextOverflow.ellipsis,
                                style: AssalTypography.body.copyWith(
                                  color: AssalColors.textPrimary,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: dialogLoading
                                  ? null
                                  : () =>
                                      setDialogState(() => editingEmail = true),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('تعديل البريد'),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AssalSpacing.lg),
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
                        color: AssalColors.deepBrown,
                        letterSpacing: 5,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'رمز التحقق (6–9 أرقام)',
                        helperText: 'أدخل الرمز المكوّن من 6 أرقام على الأقل',
                        counterText: '',
                      ),
                    ),
                    TextButton(
                      onPressed: dialogLoading || resendSeconds > 0
                          ? null
                          : () async {
                              final email = dialogEmail.trim();
                              if (!email.contains('@')) {
                                setDialogState(() => dialogError =
                                    'أدخل بريدًا إلكترونيًا صالحًا.');
                                return;
                              }
                              setDialogState(() {
                                dialogLoading = true;
                                dialogError = null;
                                dialogNotice = null;
                              });
                              final result = loginMode
                                  ? await widget.repository
                                      .requestEmailOtp(email)
                                  : await widget.repository
                                      .resendEmailConfirmation(email);
                              if (!mounted || !dialogContext.mounted) return;
                              if (result is AssalData<void>) {
                                setDialogState(() {
                                  dialogLoading = false;
                                  dialogNotice = loginMode
                                      ? 'تم إرسال رمز دخول جديد. استخدم أحدث رمز فقط.'
                                      : 'تم إرسال رمز تحقق جديد. استخدم أحدث رمز فقط.';
                                });
                                startCountdown(setDialogState);
                              } else if (result is AssalError<void>) {
                                setDialogState(() {
                                  dialogLoading = false;
                                  dialogError = result.messageAr;
                                });
                              }
                            },
                      child: Text(
                        resendSeconds > 0
                            ? 'إعادة إرسال الرمز 0:${resendSeconds.toString().padLeft(2, '0')}'
                            : 'إعادة إرسال الرمز',
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: AssalSpacing.sm),
                      Text(
                        dialogError!,
                        textAlign: TextAlign.center,
                        style: AssalTypography.caption
                            .copyWith(color: AssalColors.error),
                      ),
                    ],
                    if (dialogNotice != null) ...[
                      const SizedBox(height: AssalSpacing.sm),
                      Text(
                        dialogNotice!,
                        textAlign: TextAlign.center,
                        style: AssalTypography.caption
                            .copyWith(color: AssalColors.success),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                FilledButton(
                  onPressed: dialogLoading
                      ? null
                      : () async {
                          final token = otpController.text.trim();
                          final email = dialogEmail.trim();
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
                      : const Text('تحقق'),
                ),
              ],
            ),
          );
        },
      ),
    );
    resendTimer?.cancel();
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
    final validChecks = checks.where((check) => check.valid).length;
    final strong = asciiOnly && checks.every((check) => check.valid);
    final medium = asciiOnly && !strong && validChecks >= 2;
    final color = strong
        ? AssalColors.success
        : (medium ? AssalColors.warning : AssalColors.error);

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
                : (strong
                    ? 'كلمة المرور قوية'
                    : (medium ? 'كلمة المرور متوسطة' : 'كلمة المرور ضعيفة')),
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
  const ProfileScreen({
    super.key,
    required this.repository,
    this.showAppBar = true,
  });
  final AssalRepository repository;
  final bool showAppBar;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AssalRepository get repository => widget.repository;
  bool imageBusy = false;
  AssalUserProfile? profileOverride;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? const AssalAppBar(title: 'حسابي') : null,
      body: FutureBuilder<AssalSession>(
        future: repository.getSession(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AssalGlassLoading();
          }
          final session = snapshot.data ?? AssalSession.guest;
          return ListView(
              padding: const EdgeInsets.fromLTRB(
                AssalSpacing.lg,
                AssalSpacing.lg,
                AssalSpacing.lg,
                AssalSpacing.x2l,
              ),
              children: [
                if (!session.isAuthenticated) ...[
                  const AssalBrandMark(),
                  const SizedBox(height: AssalSpacing.xl),
                ],
                session.isUnavailable
                    ? AssalMessageCard(
                        icon: Icons.sync_problem_outlined,
                        message: session.errorMessageAr ??
                            'تعذر مزامنة الحساب الآن.',
                      )
                    : session.isAuthenticated
                        ? _authenticated(context, session)
                        : _guest(context),
                const SizedBox(height: AssalSpacing.lg),
                _accountActions(context, session),
              ]);
        },
      ),
    );
  }

  Widget _accountActions(BuildContext context, AssalSession session) {
    final actions = <Widget>[
      if (session.isAuthenticated) ...[
        const SectionHeader(title: 'نشاطك'),
        const SizedBox(height: AssalSpacing.xs),
      ],
      AssalActionTile(
        icon: Icons.bookmarks_outlined,
        title: 'المحفوظات والمتاجر المتابَعة',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FavoritesScreen(repository: repository),
        )),
      ),
      const SizedBox(height: AssalSpacing.sm),
      AssalActionTile(
        icon: Icons.forum_outlined,
        title: 'المراسلات',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MessagesScreen(repository: repository),
        )),
      ),
      const SizedBox(height: AssalSpacing.sm),
      AssalActionTile(
        icon: Icons.notifications_outlined,
        title: 'الإشعارات',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => NotificationsScreen(repository: repository),
        )),
      ),
      if (session.isAuthenticated) ...[
        const SizedBox(height: AssalSpacing.lg),
        const SectionHeader(title: 'الحساب والمساعدة'),
        const SizedBox(height: AssalSpacing.xs),
      ],
      const SizedBox(height: AssalSpacing.sm),
      AssalActionTile(
        icon: Icons.settings_outlined,
        title: 'الإعدادات',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
        )),
      ),
      const SizedBox(height: AssalSpacing.sm),
      AssalActionTile(
        icon: Icons.support_agent_outlined,
        title: 'المساعدة والدعم',
        subtitle: 'أسئلة شائعة ودعم فني وطلبات التصميم',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SupportCenterScreen(repository: repository),
        )),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: actions,
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

  Widget _authenticated(BuildContext context, AssalSession session) {
    final user = profileOverride ?? session.user;
    return Column(
      children: [
        if (user != null) _profileHeader(context, user),
        const SizedBox(height: AssalSpacing.lg),
        if (user != null)
          _ProfileStats(
            repository: repository,
            userId: user.id,
          ),
        const SizedBox(height: AssalSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AssalSpacing.sm,
          runSpacing: AssalSpacing.sm,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: AssalSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AssalRadius.medium),
                ),
              ),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => RequestsScreen(repository: repository))),
              icon: const Icon(Icons.assignment_outlined),
              label: const Text('طلباتي'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: AssalSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AssalRadius.medium),
                ),
              ),
              onPressed: () => _openMerchantArea(context, session),
              icon: Icon(session.role == AssalRole.merchant
                  ? Icons.dashboard_outlined
                  : Icons.storefront_outlined),
              label: Text(session.role == AssalRole.merchant
                  ? 'لوحة التاجر'
                  : 'مساحة المتجر'),
            ),
          ],
        ),
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
          label: const Text('تسجيل الخروج'),
        ),
        const SizedBox(height: AssalSpacing.xs),
        TextButton.icon(
          onPressed: () => _deleteAccount(context),
          icon: const Icon(Icons.delete_outline, color: AssalColors.error),
          label: const Text('حذف الحساب',
              style: TextStyle(color: AssalColors.error)),
        ),
      ],
    );
  }

  String _imageExtension(XFile file) {
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'png';
    if (name.endsWith('.webp')) return 'webp';
    return 'jpg';
  }

  Future<void> _pickAndSaveProfileImage(
    AssalUserProfile user, {
    required bool cover,
  }) async {
    if (imageBusy) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => imageBusy = true);
    try {
      final upload = await repository.uploadMerchantImage(
        user.id,
        cover ? 'cover' : 'logo',
        bytes,
        _imageExtension(picked),
      );
      if (!mounted) return;
      if (upload is! AssalData<String>) {
        if (upload is AssalError<String>) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(upload.messageAr)));
        }
        return;
      }
      final url = upload.value;
      final update = await repository.updateUserProfile(
        user.id,
        AssalUserProfilePatch(
          avatarUrl: cover ? null : url,
          coverUrl: cover ? url : null,
        ),
      );
      if (!mounted) return;
      if (update is AssalData<void>) {
        setState(() {
          profileOverride = AssalUserProfile(
            id: user.id,
            nameAr: user.nameAr,
            email: user.email,
            avatarUrl: cover ? user.avatarUrl : url,
            coverUrl: cover ? url : user.coverUrl,
            bio: user.bio,
            phone: user.phone,
            location: user.location,
            preferences: user.preferences,
            createdAt: user.createdAt,
            updatedAt: DateTime.now(),
            followersCount: user.followersCount,
            followingCount: user.followingCount,
            role: user.role,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(cover
                  ? 'تم تحديث صورة الغلاف.'
                  : 'تم تحديث الصورة الشخصية.')),
        );
      } else if (update is AssalError<void>) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(update.messageAr)));
      }
    } finally {
      if (mounted) setState(() => imageBusy = false);
    }
  }

  Widget _profileHeader(BuildContext context, AssalUserProfile user) =>
      AssalProfileHeaderCard(
        user: user,
        imageBusy: imageBusy,
        onPickAvatar: () => _pickAndSaveProfileImage(user, cover: false),
        onPickCover: () => _pickAndSaveProfileImage(user, cover: true),
        onEdit: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProfileEditorScreen(
              repository: repository,
              profile: user,
            ),
          ));
          if (mounted) setState(() {});
        },
      );

  Future<void> _openMerchantArea(
    BuildContext context,
    AssalSession session,
  ) async {
    if (session.user == null) return;
    final workspace = await repository.loadMerchantWorkspace(session.user!.id);
    if (!context.mounted) return;
    final hasWorkspace =
        workspace is AssalData<AssalMerchantWorkspaceSummary?> &&
            workspace.value != null;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => session.role == AssalRole.merchant || hasWorkspace
          ? MerchantDashboard(repository: repository)
          : MerchantWorkspaceSetupScreen(repository: repository),
    ));
  }

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

class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({
    super.key,
    required this.repository,
    required this.profile,
  });

  final AssalRepository repository;
  final AssalUserProfile profile;

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  late final TextEditingController nameController;
  late final TextEditingController bioController;
  late final TextEditingController phoneController;
  late final TextEditingController locationController;
  Uint8List? avatarBytes;
  Uint8List? coverBytes;
  XFile? avatarFile;
  XFile? coverFile;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.profile.nameAr);
    bioController = TextEditingController(text: widget.profile.bio ?? '');
    phoneController = TextEditingController(text: widget.profile.phone ?? '');
    locationController =
        TextEditingController(text: widget.profile.location ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    phoneController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool cover}) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      if (cover) {
        coverFile = picked;
        coverBytes = bytes;
      } else {
        avatarFile = picked;
        avatarBytes = bytes;
      }
    });
  }

  Future<void> _chooseLocation() async {
    final controller = TextEditingController(text: locationController.text);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تحديد الموقع الجغرافي'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'المدينة أو المنطقة',
            hintText: 'مثال: صنعاء، حدة',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('حفظ الموقع'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && mounted) {
      locationController.text = value.trim();
    }
  }

  String _extension(XFile file) {
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'png';
    if (name.endsWith('.webp')) return 'webp';
    return 'jpg';
  }

  Future<String?> _upload(
    XFile? file,
    Uint8List? bytes,
    String kind,
  ) async {
    if (file == null || bytes == null) return null;
    final result = await widget.repository.uploadMerchantImage(
      widget.profile.id,
      kind,
      bytes,
      _extension(file),
    );
    if (result is AssalData<String>) return result.value;
    if (result is AssalError<String> && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.messageAr)));
    }
    return null;
  }

  Future<void> _save() async {
    if (saving) return;
    setState(() => saving = true);
    final avatarUrl = await _upload(avatarFile, avatarBytes, 'logo');
    final coverUrl = await _upload(coverFile, coverBytes, 'cover');
    final result = await widget.repository.updateUserProfile(
      widget.profile.id,
      AssalUserProfilePatch(
        nameAr: nameController.text,
        bio: bioController.text,
        phone: phoneController.text,
        locationLabel: locationController.text,
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
      ),
    );
    if (!mounted) return;
    setState(() => saving = false);
    if (result is AssalData<void>) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم حفظ الملف الشخصي.')));
      Navigator.of(context).pop();
    } else if (result is AssalError<void>) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.messageAr)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AssalAppBar(title: 'تعديل الملف الشخصي'),
        body: ListView(
          padding: const EdgeInsets.all(AssalSpacing.lg),
          children: [
            AssalImagePickerTile(
              label: 'صورة الغلاف',
              icon: Icons.landscape_outlined,
              bytes: coverBytes,
              imageUrl: widget.profile.coverUrl,
              onPick: saving ? null : () => _pickImage(cover: true),
              onClear: saving ||
                      (coverBytes == null && widget.profile.coverUrl == null)
                  ? null
                  : () => setState(() {
                        coverBytes = null;
                        coverFile = null;
                      }),
              width: double.infinity,
              height: 150,
            ),
            const SizedBox(height: AssalSpacing.lg),
            AssalImagePickerTile(
              label: 'الصورة الشخصية',
              icon: Icons.person_outline,
              bytes: avatarBytes,
              imageUrl: widget.profile.avatarUrl,
              onPick: saving ? null : () => _pickImage(cover: false),
              onClear: saving ||
                      (avatarBytes == null && widget.profile.avatarUrl == null)
                  ? null
                  : () => setState(() {
                        avatarBytes = null;
                        avatarFile = null;
                      }),
              width: double.infinity,
              height: 150,
            ),
            const SizedBox(height: AssalSpacing.lg),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'الاسم',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: AssalSpacing.md),
            TextField(
              controller: bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'النبذة التعريفية',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: AssalSpacing.md),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'الهاتف',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: AssalSpacing.md),
            TextField(
              controller: locationController,
              decoration: InputDecoration(
                labelText: 'الموقع',
                prefixIcon: const Icon(Icons.location_on_outlined),
                suffixIcon: IconButton(
                  onPressed: _chooseLocation,
                  icon: const Icon(Icons.my_location_outlined),
                  tooltip: 'تحديد الموقع الجغرافي',
                ),
              ),
            ),
            const SizedBox(height: AssalSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: saving ? null : _save,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(saving ? 'جارٍ الحفظ...' : 'حفظ التغييرات'),
              ),
            ),
          ],
        ),
      );
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

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key, required this.repository});
  final AssalRepository repository;

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  late Future<AssalSession> sessionFuture;
  Future<AssalLoadState<List<AssalRequestSummary>>>? requestsFuture;
  RequestStatus? selectedStatus;

  @override
  void initState() {
    super.initState();
    sessionFuture = widget.repository.getSession();
  }

  void _retrySession() {
    setState(() {
      sessionFuture = widget.repository.getSession();
      requestsFuture = null;
    });
  }

  void _retryRequests(String userId) {
    setState(() {
      requestsFuture = widget.repository.listRequests(userId);
    });
  }

  String _statusLabel(RequestStatus status) => switch (status) {
        RequestStatus.open => 'جديد',
        RequestStatus.inProgress => 'قيد الرد',
        RequestStatus.answered => 'تم الرد',
        RequestStatus.closed || RequestStatus.cancelled => 'مغلقة',
      };

  Color _statusColor(RequestStatus status) => switch (status) {
        RequestStatus.open => AssalColors.success,
        RequestStatus.inProgress => AssalColors.primaryDark,
        RequestStatus.answered => AssalColors.success,
        RequestStatus.closed ||
        RequestStatus.cancelled =>
          AssalColors.textMuted,
      };

  List<AssalRequestSummary> _filterRequests(
    List<AssalRequestSummary> requests,
  ) {
    final status = selectedStatus;
    if (status == null) return requests;
    if (status == RequestStatus.closed) {
      return requests
          .where((request) =>
              request.status == RequestStatus.closed ||
              request.status == RequestStatus.cancelled)
          .toList(growable: false);
    }
    return requests
        .where((request) => request.status == status)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AssalAppBar(title: 'طلباتي'),
        body: FutureBuilder<AssalSession>(
          future: sessionFuture,
          builder: (context, sessionSnapshot) {
            if (sessionSnapshot.connectionState != ConnectionState.done) {
              return const AssalGlassLoading();
            }
            final session = sessionSnapshot.data ?? AssalSession.guest;
            if (session.isUnavailable) {
              return AssalMessageCard(
                icon: Icons.sync_problem_outlined,
                message: session.errorMessageAr ?? 'تعذر مزامنة الحساب الآن.',
                onRetry: _retrySession,
              );
            }
            if (!session.isAuthenticated || session.user == null) {
              return Center(
                child: FilledButton(
                  onPressed: () => openAuth(context, widget.repository),
                  child: const Text('تسجيل الدخول لمتابعة الطلبات'),
                ),
              );
            }
            final userId = session.user!.id;
            requestsFuture ??= widget.repository.listRequests(userId);
            return FutureBuilder<AssalLoadState<List<AssalRequestSummary>>>(
              future: requestsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return AssalMessageCard(
                    icon: Icons.wifi_off_outlined,
                    message:
                        'تعذر تحميل الطلبات الآن. تحقق من الاتصال ثم أعد المحاولة.',
                    onRetry: () => _retryRequests(userId),
                  );
                }
                if (!snapshot.hasData) return const AssalGlassLoading();
                final state = snapshot.data!;
                final filters = _RequestStatusFilters(
                  selectedStatus: selectedStatus,
                  labelFor: _statusLabel,
                  onSelected: (status) => setState(() {
                    selectedStatus = status;
                  }),
                );
                if (state is AssalData<List<AssalRequestSummary>> &&
                    state.value.isEmpty) {
                  return Column(
                    children: [
                      filters,
                      Expanded(
                        child: _RequestsEmptyState(
                          filtered: false,
                          onRetry: () => _retryRequests(userId),
                          onExplore: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SearchScreen(
                                repository: widget.repository,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return AssalStateView<List<AssalRequestSummary>>(
                  state: state,
                  onRetry: () => _retryRequests(userId),
                  builder: (requests) {
                    final visibleRequests = _filterRequests(requests);
                    return Column(
                      children: [
                        filters,
                        Expanded(
                          child: visibleRequests.isEmpty
                              ? _RequestsEmptyState(
                                  filtered: requests.isNotEmpty,
                                  onRetry: () => _retryRequests(userId),
                                  onExplore: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => SearchScreen(
                                        repository: widget.repository,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    AssalSpacing.lg,
                                    AssalSpacing.sm,
                                    AssalSpacing.lg,
                                    AssalSpacing.lg,
                                  ),
                                  itemCount: visibleRequests.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: AssalSpacing.sm),
                                  itemBuilder: (_, index) => _RequestCard(
                                    request: visibleRequests[index],
                                    statusLabel: _statusLabel(
                                      visibleRequests[index].status,
                                    ),
                                    statusColor: _statusColor(
                                      visibleRequests[index].status,
                                    ),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CustomerRequestDetailScreen(
                                          repository: widget.repository,
                                          request: visibleRequests[index],
                                          merchantMode: false,
                                          onOpenStore: () async {
                                            await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    StoreProfileScreen(
                                                  repository: widget.repository,
                                                  storeId:
                                                      visibleRequests[index]
                                                          .storeId,
                                                ),
                                              ),
                                            );
                                          },
                                          onMessageMerchant: () async {
                                            final session = await widget
                                                .repository
                                                .getSession();
                                            if (!context.mounted) return;
                                            if (session.isUnavailable) {
                                              ScaffoldMessenger.of(context)
                                                ..hideCurrentSnackBar()
                                                ..showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      session.errorMessageAr ??
                                                          'تعذر مزامنة الحساب الآن.',
                                                    ),
                                                  ),
                                                );
                                              return;
                                            }
                                            if (!session.isAuthenticated ||
                                                session.user == null) {
                                              ScaffoldMessenger.of(context)
                                                ..hideCurrentSnackBar()
                                                ..showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'سجّل الدخول لمراسلة التاجر.',
                                                    ),
                                                  ),
                                                );
                                              return;
                                            }
                                            final result = await widget
                                                .repository
                                                .createConversation(
                                              session.user!.id,
                                              visibleRequests[index].storeId,
                                            );
                                            if (!context.mounted) return;
                                            if (result is AssalData<
                                                AssalConversationSummary>) {
                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ConversationScreen(
                                                    repository:
                                                        widget.repository,
                                                    conversation: result.value,
                                                  ),
                                                ),
                                              );
                                            } else if (result is AssalError<
                                                AssalConversationSummary>) {
                                              ScaffoldMessenger.of(context)
                                                ..hideCurrentSnackBar()
                                                ..showSnackBar(
                                                  SnackBar(
                                                    content:
                                                        Text(result.messageAr),
                                                  ),
                                                );
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      );
}

class _RequestStatusFilters extends StatelessWidget {
  const _RequestStatusFilters({
    required this.selectedStatus,
    required this.labelFor,
    required this.onSelected,
  });

  final RequestStatus? selectedStatus;
  final String Function(RequestStatus) labelFor;
  final ValueChanged<RequestStatus?> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AssalSpacing.lg,
          AssalSpacing.md,
          AssalSpacing.lg,
          AssalSpacing.sm,
        ),
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('الكل'),
              selected: selectedStatus == null,
              onSelected: (_) => onSelected(null),
            ),
            ...[
              RequestStatus.open,
              RequestStatus.inProgress,
              RequestStatus.answered,
              RequestStatus.closed,
            ].map(
              (status) => Padding(
                padding:
                    const EdgeInsetsDirectional.only(start: AssalSpacing.sm),
                child: ChoiceChip(
                  label: Text(labelFor(status)),
                  selected: selectedStatus == status,
                  onSelected: (_) => onSelected(status),
                ),
              ),
            ),
          ],
        ),
      );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.statusLabel,
    required this.statusColor,
    required this.onTap,
  });

  final AssalRequestSummary request;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onTap;

  String _dateLabel(DateTime? date) {
    if (date == null) return 'التاريخ غير متاح';
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AssalRadius.medium),
          child: Padding(
            padding: const EdgeInsets.all(AssalSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AssalSpacing.sm,
                              vertical: AssalSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(
                                AssalRadius.small,
                              ),
                            ),
                            child: Text(
                              statusLabel,
                              style: AssalTypography.caption.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: AssalSpacing.sm),
                          Text(
                            request.productName ?? request.subject,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AssalTypography.subtitle,
                          ),
                          const SizedBox(height: AssalSpacing.xs),
                          Text(request.storeName ?? 'متجر عسلكم'),
                        ],
                      ),
                    ),
                    const SizedBox(width: AssalSpacing.md),
                    const SizedBox(
                      width: 76,
                      height: 76,
                      child: AssalImageTile(
                        imageUrl: null,
                        height: 76,
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                  ],
                ),
                const Divider(height: AssalSpacing.lg),
                Wrap(
                  spacing: AssalSpacing.lg,
                  runSpacing: AssalSpacing.sm,
                  children: [
                    InfoChip(
                      icon: Icons.scale_outlined,
                      label: 'الكمية: ${request.quantity ?? 'غير محددة'}',
                    ),
                    InfoChip(
                      icon: Icons.calendar_today_outlined,
                      label: 'التاريخ: ${_dateLabel(request.createdAt)}',
                    ),
                  ],
                ),
                if (request.body != null &&
                    request.body!.trim().isNotEmpty) ...[
                  const SizedBox(height: AssalSpacing.sm),
                  Text(
                    request.body!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AssalTypography.bodySmall.copyWith(
                      color: AssalColors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: AssalSpacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('التفاصيل'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _RequestsEmptyState extends StatelessWidget {
  const _RequestsEmptyState({
    required this.filtered,
    required this.onRetry,
    required this.onExplore,
  });

  final bool filtered;
  final VoidCallback onRetry;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(AssalSpacing.lg),
        child: Column(
          children: [
            AssalMessageCard(
              icon: Icons.forum_outlined,
              message: filtered
                  ? 'لا توجد طلبات بهذه الحالة.'
                  : 'لا توجد طلبات تواصل بعد.',
              onRetry: onRetry,
            ),
            if (!filtered) ...[
              const SizedBox(height: AssalSpacing.sm),
              OutlinedButton.icon(
                onPressed: onExplore,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('استكشف المنتجات'),
              ),
            ],
          ],
        ),
      );
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
          if (sessionSnapshot.connectionState != ConnectionState.done) {
            return const AssalGlassLoading();
          }
          final session = sessionSnapshot.data ?? AssalSession.guest;
          if (session.isUnavailable) {
            return AssalMessageCard(
              icon: Icons.sync_problem_outlined,
              message: session.errorMessageAr ?? 'تعذر مزامنة الحساب الآن.',
            );
          }
          if (!session.isAuthenticated || session.user == null) {
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
                    return AssalNotificationCard(
                      notification: item,
                      onTap: () async {
                        final result = await repository.markNotificationRead(
                          session.user!.id,
                          item.id,
                        );
                        if (!context.mounted) return;
                        if (result is AssalData<bool>) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم تعليم الإشعار كمقروء.'),
                            ),
                          );
                        } else if (result is AssalError<bool>) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result.messageAr)),
                          );
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

class NewConversationSheet extends StatefulWidget {
  const NewConversationSheet({
    super.key,
    required this.store,
  });

  final AssalStoreSummary store;

  @override
  State<NewConversationSheet> createState() => _NewConversationSheetState();
}

class _NewConversationSheetState extends State<NewConversationSheet> {
  final controller = TextEditingController();
  String? validationMessage;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _startConversation() {
    final message = controller.text.trim();
    if (message.isEmpty) {
      setState(() => validationMessage = 'اكتب رسالتك الأولى للمتجر.');
      return;
    }
    Navigator.of(context).pop(message);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          left: AssalSpacing.lg,
          right: AssalSpacing.lg,
          top: AssalSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AssalSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.forum_outlined,
                    color: AssalColors.primaryDark,
                  ),
                  const SizedBox(width: AssalSpacing.sm),
                  const Expanded(
                    child: Text(
                      'مراسلة التاجر',
                      style: AssalTypography.heading3,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'إلغاء',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AssalSpacing.sm),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AssalColors.honeyLight,
                    child: Icon(
                      Icons.storefront_outlined,
                      color: AssalColors.primaryDark,
                    ),
                  ),
                  title: Text(widget.store.nameAr),
                  subtitle: const Text('ابدأ محادثة جديدة مع المتجر'),
                ),
              ),
              const SizedBox(height: AssalSpacing.md),
              TextField(
                controller: controller,
                autofocus: true,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                onChanged: (_) {
                  if (validationMessage != null) {
                    setState(() => validationMessage = null);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'أول رسالة',
                  hintText: 'اكتب استفسارك أو طلبك للمتجر',
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  errorText: validationMessage,
                ),
              ),
              const SizedBox(height: AssalSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: AssalSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _startConversation,
                      icon: const Icon(Icons.forum_outlined),
                      label: const Text('بدء المحادثة'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
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
  late Future<AssalSession> sessionFuture;
  late Future<AssalLoadState<List<AssalMessageSummary>>> messagesFuture;
  bool _isSending = false;
  String? _sendStatus;

  @override
  void initState() {
    super.initState();
    sessionFuture = widget.repository.getSession();
    messagesFuture = widget.repository.listMessages(widget.conversation.id);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _retryMessages() {
    if (!mounted) return;
    setState(() {
      messagesFuture = widget.repository.listMessages(widget.conversation.id);
    });
  }

  void _reloadSession() {
    if (!mounted) return;
    setState(() {
      sessionFuture = widget.repository.getSession();
    });
  }

  Future<void> _login() async {
    final authenticated = await openAuth(context, widget.repository);
    if (!mounted || !authenticated) return;
    _reloadSession();
  }

  Widget _conversationHeader(AssalSession session) => Card(
        margin: const EdgeInsets.fromLTRB(
          AssalSpacing.lg,
          AssalSpacing.lg,
          AssalSpacing.lg,
          AssalSpacing.sm,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AssalSpacing.md),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AssalColors.honeyLight,
                child: Icon(
                  Icons.storefront_outlined,
                  color: AssalColors.primaryDark,
                ),
              ),
              const SizedBox(width: AssalSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.conversation.storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AssalTypography.title,
                    ),
                    const SizedBox(height: AssalSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          session.isAuthenticated
                              ? Icons.circle
                              : Icons.info_outline,
                          size: 10,
                          color: session.isAuthenticated
                              ? AssalColors.success
                              : AssalColors.textMuted,
                        ),
                        const SizedBox(width: AssalSpacing.xs),
                        Text(
                          session.isAuthenticated
                              ? 'متصل الآن'
                              : 'يلزم تسجيل الدخول للإرسال',
                          style: AssalTypography.caption.copyWith(
                            color: session.isAuthenticated
                                ? AssalColors.success
                                : AssalColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _messages(AssalSession session) =>
      FutureBuilder<AssalLoadState<List<AssalMessageSummary>>>(
        future: messagesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const AssalGlassLoading();
          return AssalStateView<List<AssalMessageSummary>>(
            state: snapshot.data!,
            emptyMessageAr: 'لا توجد رسائل بعد. ابدأ المحادثة برسالة جديدة.',
            onRetry: _retryMessages,
            builder: (messages) => ListView(
              padding: const EdgeInsets.fromLTRB(
                AssalSpacing.lg,
                AssalSpacing.sm,
                AssalSpacing.lg,
                AssalSpacing.lg,
              ),
              children: [
                if (session.isAuthenticated && session.user != null)
                  ...messages.map<Widget>(
                    (message) => AssalMessageBubble(message: message),
                  ),
              ],
            ),
          );
        },
      );

  Widget _composer(AssalSession session) {
    final canSend = session.isAuthenticated && session.user != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AssalSpacing.sm,
          AssalSpacing.xs,
          AssalSpacing.sm,
          AssalSpacing.sm,
        ),
        child: Column(
          children: [
            if (_sendStatus != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AssalSpacing.xs),
                  child: Text(
                    _sendStatus!,
                    style: AssalTypography.caption.copyWith(
                      color: AssalColors.textSecondary,
                    ),
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: canSend && !_isSending,
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      labelText: 'اكتب رسالتك',
                      prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: canSend && !_isSending ? _send : _login,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          canSend ? Icons.send_rounded : Icons.login_rounded),
                  tooltip: canSend ? 'إرسال' : 'تسجيل الدخول',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AssalAppBar(title: widget.conversation.storeName),
        body: FutureBuilder<AssalSession>(
          future: sessionFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const AssalGlassLoading();
            final session = snapshot.data!;
            if (session.isUnavailable) {
              return AssalMessageCard(
                icon: Icons.sync_problem_outlined,
                message: session.errorMessageAr ?? 'تعذر تحميل البيانات الآن.',
                onRetry: _reloadSession,
              );
            }
            return Column(
              children: [
                _conversationHeader(session),
                Expanded(child: _messages(session)),
                if (!session.isAuthenticated || session.user == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AssalSpacing.xs),
                    child: TextButton.icon(
                      onPressed: _login,
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('تسجيل الدخول للرد'),
                    ),
                  ),
                _composer(session),
              ],
            );
          },
        ),
      );

  Future<void> _send() async {
    final body = controller.text.trim();
    if (body.isEmpty || _isSending) return;
    setState(() {
      _isSending = true;
      _sendStatus = 'جارٍ إرسال الرسالة...';
    });
    try {
      var session = await widget.repository.getSession();
      if (session.isUnavailable) {
        if (mounted) {
          setState(() => _sendStatus =
              session.errorMessageAr ?? 'تعذر تحميل البيانات الآن.');
        }
        return;
      }
      if (!session.isAuthenticated || session.user == null) {
        if (!mounted) return;
        final authenticated = await openAuth(context, widget.repository);
        if (!mounted || !authenticated) return;
        session = await widget.repository.getSession();
      }
      if (!session.isAuthenticated || session.user == null) {
        if (mounted) {
          setState(() => _sendStatus = 'سجّل الدخول لإرسال الرسالة.');
        }
        return;
      }
      final result = await widget.repository.sendMessage(
        session.user!.id,
        AssalMessageDraft(conversationId: widget.conversation.id, body: body),
      );
      if (!mounted) return;
      if (result is AssalData<AssalMessageSummary>) {
        controller.clear();
        setState(() {
          _sendStatus = 'تم إرسال الرسالة.';
          messagesFuture =
              widget.repository.listMessages(widget.conversation.id);
          sessionFuture = Future<AssalSession>.value(session);
        });
      } else if (result is AssalError<AssalMessageSummary>) {
        setState(() => _sendStatus = result.messageAr);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({
    super.key,
    required this.repository,
    this.showAppBar = true,
  });
  final AssalRepository repository;
  final bool showAppBar;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late Future<AssalSession> sessionFuture;
  Future<AssalLoadState<List<AssalConversationSummary>>>? conversationsFuture;
  final searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    sessionFuture = widget.repository.getSession();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final nextQuery = searchController.text.trim();
    if (nextQuery == searchQuery || !mounted) return;
    setState(() => searchQuery = nextQuery);
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      sessionFuture = widget.repository.getSession();
      conversationsFuture = null;
    });
  }

  void _retryConversations(AssalSession session) {
    if (!mounted || session.user == null) return;
    setState(() {
      conversationsFuture =
          widget.repository.listConversations(session.user!.id);
    });
  }

  Future<void> _login() async {
    final authenticated = await openAuth(context, widget.repository);
    if (!mounted || !authenticated) return;
    setState(() {
      sessionFuture = widget.repository.getSession();
      conversationsFuture = null;
    });
  }

  Future<void> _exploreStores() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoresScreen(repository: widget.repository),
      ),
    );
  }

  List<AssalConversationSummary> _filteredItems(
    List<AssalConversationSummary> items,
  ) {
    if (searchQuery.isEmpty) return items;
    final query = searchQuery.toLowerCase();
    return items
        .where(
          (item) =>
              item.storeName.toLowerCase().contains(query) ||
              item.lastMessage.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  Widget _searchField() => TextField(
        controller: searchController,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          labelText: 'البحث في المحادثات',
          prefixIcon: Icon(Icons.search_rounded),
          suffixIcon: Icon(Icons.forum_outlined),
        ),
      );

  Widget _emptyState({required bool filtered}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AssalSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                filtered ? Icons.search_off_rounded : Icons.forum_outlined,
                size: 42,
                color: AssalColors.textMuted,
              ),
              const SizedBox(height: AssalSpacing.sm),
              Text(
                filtered
                    ? 'لا توجد محادثات تطابق بحثك.'
                    : 'لا توجد محادثات بعد.',
                textAlign: TextAlign.center,
                style: AssalTypography.body.copyWith(
                  color: AssalColors.textSecondary,
                ),
              ),
              if (!filtered) ...[
                const SizedBox(height: AssalSpacing.md),
                OutlinedButton.icon(
                  onPressed: _exploreStores,
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text('استكشف المتاجر'),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _conversationList(
    AssalSession session,
    List<AssalConversationSummary> items,
  ) {
    final visibleItems = _filteredItems(items);
    if (visibleItems.isEmpty) {
      return _emptyState(filtered: searchQuery.isNotEmpty);
    }
    return RefreshIndicator(
      onRefresh: () async => _retryConversations(session),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AssalSpacing.lg,
          AssalSpacing.sm,
          AssalSpacing.lg,
          AssalSpacing.lg,
        ),
        itemCount: visibleItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: AssalSpacing.sm),
        itemBuilder: (_, index) {
          final item = visibleItems[index];
          return AssalConversationCard(
            conversation: item,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ConversationScreen(
                  repository: widget.repository,
                  conversation: item,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _conversations(AssalSession session) {
    final future = conversationsFuture ??=
        widget.repository.listConversations(session.user!.id);
    return FutureBuilder<AssalLoadState<List<AssalConversationSummary>>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const AssalGlassLoading();
        final state = snapshot.data!;
        if (state is AssalLoading<List<AssalConversationSummary>>) {
          return const AssalGlassLoading();
        }
        if (state is AssalError<List<AssalConversationSummary>>) {
          return AssalMessageCard(
            icon: Icons.sync_problem_outlined,
            message: state.messageAr,
            onRetry:
                state.retryable ? () => _retryConversations(session) : null,
          );
        }
        if (state is AssalEmpty<List<AssalConversationSummary>>) {
          return _emptyState(filtered: false);
        }
        final items = state is AssalData<List<AssalConversationSummary>>
            ? state.value
            : const <AssalConversationSummary>[];
        return _conversationList(session, items);
      },
    );
  }

  Widget _authenticatedBody(AssalSession session) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AssalSpacing.lg,
              AssalSpacing.lg,
              AssalSpacing.lg,
              AssalSpacing.sm,
            ),
            child: _searchField(),
          ),
          Expanded(child: _conversations(session)),
        ],
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: widget.showAppBar ? const AssalAppBar(title: 'الرسائل') : null,
        body: FutureBuilder<AssalSession>(
          future: sessionFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const AssalGlassLoading();
            final session = snapshot.data!;
            if (session.isUnavailable) {
              return AssalMessageCard(
                icon: Icons.sync_problem_outlined,
                message: session.errorMessageAr ?? 'تعذر تحميل البيانات الآن.',
                onRetry: _reload,
              );
            }
            if (!session.isAuthenticated || session.user == null) {
              return Center(
                child: FilledButton.icon(
                  onPressed: _login,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('تسجيل الدخول لعرض الرسائل'),
                ),
              );
            }
            return _authenticatedBody(session);
          },
        ),
      );
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

class MerchantWorkspaceSetupScreen extends StatefulWidget {
  const MerchantWorkspaceSetupScreen({super.key, required this.repository});

  final AssalRepository repository;

  @override
  State<MerchantWorkspaceSetupScreen> createState() =>
      _MerchantWorkspaceSetupScreenState();
}

class _MerchantWorkspaceSetupScreenState
    extends State<MerchantWorkspaceSetupScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();
  Uint8List? logoBytes;
  Uint8List? coverBytes;
  String? logoUrl;
  String? coverUrl;
  bool loading = true;
  bool opening = false;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    final session = await widget.repository.getSession();
    if (!session.isAuthenticated || session.user == null) {
      if (mounted) setState(() => loading = false);
      return;
    }
    final result = await widget.repository.loadMerchantApplicationDraft(
      session.user!.id,
    );
    if (!mounted) return;
    if (result is AssalData<AssalMerchantApplicationDraft?> &&
        result.value != null) {
      final draft = result.value!;
      nameController.text = draft.displayName;
      phoneController.text = draft.phone;
      locationController.text = draft.location;
      descriptionController.text = draft.storeDescription ?? draft.experience;
      logoUrl = draft.logoUrl;
      coverUrl = draft.coverUrl;
    }
    setState(() => loading = false);
  }

  String _extension(XFile file) {
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'png';
    if (name.endsWith('.webp')) return 'webp';
    return 'jpg';
  }

  Future<void> _pickImage({required bool cover}) async {
    final session = await widget.repository.getSession();
    if (!session.isAuthenticated || session.user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('سجّل الدخول قبل رفع صورة المتجر.')),
        );
      }
      return;
    }
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      imageQuality: 88,
    );
    if (picked == null) return;
    if (mounted) setState(() => uploading = true);
    final result = await widget.repository.uploadMerchantImage(
      session.user!.id,
      cover ? 'cover' : 'logo',
      await picked.readAsBytes(),
      _extension(picked),
    );
    if (!mounted) return;
    setState(() => uploading = false);
    if (result is AssalData<String>) {
      setState(() {
        if (cover) {
          coverUrl = result.value;
          coverBytes = null;
        } else {
          logoUrl = result.value;
          logoBytes = null;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفع الصورة وربطها بمساحة المتجر.')),
      );
    } else if (result is AssalError<String>) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.messageAr)));
    }
  }

  Future<void> _openWorkspace() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final session = await widget.repository.getSession();
    if (!session.isAuthenticated || session.user == null) {
      if (mounted) await openAuth(context, widget.repository);
      return;
    }
    setState(() => opening = true);
    final result = await widget.repository.openMerchantWorkspace(
      session.user!.id,
      AssalMerchantWorkspaceDraft(
        businessName: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        phone: phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        logoUrl: logoUrl,
        coverUrl: coverUrl,
      ),
    );
    if (!mounted) return;
    setState(() => opening = false);
    if (result is AssalData<AssalMerchantWorkspaceSummary>) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('تم فتح مساحة المتجر فورًا. النشر معلّق حتى تفعيل الإدارة.'),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MerchantDashboard(repository: widget.repository),
        ),
      );
    } else if (result is AssalError<AssalMerchantWorkspaceSummary>) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.messageAr)));
    }
  }

  Future<void> _saveDraft() async {
    final session = await widget.repository.getSession();
    if (!session.isAuthenticated || session.user == null) return;
    final result = await widget.repository.saveMerchantApplicationDraft(
      session.user!.id,
      AssalMerchantApplicationDraft(
        displayName: nameController.text.trim(),
        phone: phoneController.text.trim(),
        experience: descriptionController.text.trim(),
        location: locationController.text.trim(),
        specialties: 'منتجات نحلية يمنية',
        storeDescription: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        logoUrl: logoUrl,
        coverUrl: coverUrl,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result is AssalData<void>
          ? 'تم حفظ البيانات مؤقتًا.'
          : result is AssalError<void>
              ? result.messageAr
              : 'تعذر حفظ البيانات.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        appBar: AssalAppBar(title: 'فتح مساحة المتجر'),
        body: AssalGlassLoading(),
      );
    }
    return Scaffold(
      appBar: const AssalAppBar(title: 'فتح مساحة المتجر'),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(AssalSpacing.lg),
          children: [
            const AssalImageTile(
              height: 170,
              icon: Icons.storefront_outlined,
            ),
            const SizedBox(height: AssalSpacing.lg),
            Text(
              'مساحة متجرك تبدأ الآن',
              style: AssalTypography.heading1
                  .copyWith(color: AssalColors.deepBrown),
            ),
            const SizedBox(height: AssalSpacing.sm),
            Text(
              'أكمل الحد الأدنى من البيانات، ثم افتح مساحة المتجر فورًا. ستتمكن من إضافة المنتجات ومعاينتها، بينما يبقى النشر معلّقًا حتى تفعيل الإدارة.',
              style: AssalTypography.bodyLarge
                  .copyWith(color: AssalColors.textSecondary),
            ),
            const SizedBox(height: AssalSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AssalSpacing.md),
              decoration: BoxDecoration(
                color: AssalColors.cream,
                borderRadius: BorderRadius.circular(AssalRadius.medium),
                border: Border.all(color: AssalColors.border),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.pending_actions_outlined,
                      color: AssalColors.primaryDark),
                  SizedBox(width: AssalSpacing.sm),
                  Expanded(
                    child: Text(
                        'الحالة بعد الفتح: معلّق حتى تفعيل الإدارة. لا تختفي بياناتك ولا منتجاتك، لكنها لا تظهر للعملاء قبل التفعيل.'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AssalSpacing.lg),
            AssalImageUploadSlot(
              label: 'غلاف المتجر',
              icon: Icons.photo_size_select_actual_outlined,
              imageUrl: coverUrl,
              bytes: coverBytes,
              onPick:
                  uploading || opening ? null : () => _pickImage(cover: true),
              height: 150,
            ),
            const SizedBox(height: AssalSpacing.lg),
            AssalImageUploadSlot(
              label: 'شعار المتجر',
              icon: Icons.storefront_outlined,
              imageUrl: logoUrl,
              bytes: logoBytes,
              onPick:
                  uploading || opening ? null : () => _pickImage(cover: false),
              height: 150,
            ),
            const SizedBox(height: AssalSpacing.lg),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'اسم النشاط أو المتجر',
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
              validator: (value) => value == null || value.trim().length < 2
                  ? 'اكتب اسم المتجر.'
                  : null,
            ),
            const SizedBox(height: AssalSpacing.md),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم التواصل (اختياري)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: AssalSpacing.md),
            TextFormField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'الموقع (اختياري)',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: AssalSpacing.md),
            TextFormField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'نبذة عن المتجر (اختياري)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: AssalSpacing.lg),
            OutlinedButton.icon(
              onPressed: opening ? null : _saveDraft,
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ البيانات مؤقتًا'),
            ),
            const SizedBox(height: AssalSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: opening || uploading ? null : _openWorkspace,
                icon: opening
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.dashboard_customize_outlined),
                label: Text(opening
                    ? 'جارٍ فتح مساحة المتجر...'
                    : 'فتح مساحة المتجر الآن'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
