import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:async';

import 'package:assalkom_data/assal_repository.dart';

class SupabaseAuthGateway implements AssalAuthGateway {
  const SupabaseAuthGateway({required this.client, this.emailRedirectTo});

  final SupabaseClient client;
  final String? emailRedirectTo;

  @override
  Future<AssalAuthIdentity?> currentIdentity() async =>
      _identity(client.auth.currentUser);

  @override
  Future<AssalAuthIdentity?> signInWithPassword(
      String email, String password) async {
    try {
      final response = await client.auth
          .signInWithPassword(email: email.trim(), password: password)
          .timeout(const Duration(seconds: 20));
      return _identity(response.user);
    } on AuthException catch (error) {
      throw AssalAuthFailure(_messageFor(error),
          code: error.code ?? error.statusCode);
    }
  }

  @override
  Future<void> requestEmailOtp(String email) async {
    try {
      await client.auth
          .signInWithOtp(
            email: email.trim(),
            shouldCreateUser: false,
          )
          .timeout(const Duration(seconds: 20));
    } on AuthException catch (error) {
      if (error.code == 'otp_disabled' ||
          error.message.toLowerCase().contains('signups not allowed for otp')) {
        throw const AssalAuthFailure(
          'لا يوجد حساب بهذا البريد الإلكتروني. اختر «إنشاء حساب» أولًا.',
          code: 'user_not_found',
        );
      }
      throw AssalAuthFailure(_messageFor(error),
          code: error.code ?? error.statusCode);
    }
  }

  @override
  Future<AssalAuthIdentity?> verifyEmailOtp(String email, String token) async {
    try {
      final response = await client.auth
          .verifyOTP(
            email: email.trim(),
            token: token.trim(),
            type: OtpType.email,
          )
          .timeout(const Duration(seconds: 20));
      return _identity(response.user);
    } on AuthException catch (error) {
      throw AssalAuthFailure(_messageFor(error),
          code: error.code ?? error.statusCode);
    }
  }

  @override
  Future<AssalAuthIdentity?> signUp(
      {required String name,
      required String email,
      required String password}) async {
    try {
      final response = await client.auth
          .signUp(
            email: email.trim(),
            password: password,
            emailRedirectTo: emailRedirectTo,
            data: <String, Object?>{'display_name': name.trim()},
          )
          .timeout(const Duration(seconds: 20));
      final identity = _identity(response.user);
      // Supabase returns a user but no session when email confirmation is required.
      // Never treat that response as an authenticated login.
      if (response.session == null) {
        throw const AssalAuthFailure(
            'تم إنشاء الحساب. تحقق من بريدك الإلكتروني لتأكيد الحساب ثم سجّل الدخول.',
            code: 'email_confirmation_required');
      }
      return identity;
    } on AssalAuthFailure {
      rethrow;
    } on AuthException catch (error) {
      throw AssalAuthFailure(_messageFor(error),
          code: error.code ?? error.statusCode);
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      await client.auth
          .resetPasswordForEmail(email.trim(), redirectTo: emailRedirectTo);
    } on AuthException catch (error) {
      throw AssalAuthFailure(_messageFor(error),
          code: error.code ?? error.statusCode);
    }
  }

  @override
  Future<void> resendEmailConfirmation(String email) async {
    try {
      await client.auth
          .resend(
            email: email.trim(),
            type: OtpType.signup,
            emailRedirectTo: emailRedirectTo,
          )
          .timeout(const Duration(seconds: 20));
    } on AuthException catch (error) {
      throw AssalAuthFailure(_messageFor(error),
          code: error.code ?? error.statusCode);
    }
  }

  @override
  Future<AssalAuthIdentity?> verifyEmailConfirmation(
      String email, String token) async {
    try {
      final response = await client.auth
          .verifyOTP(
            email: email.trim(),
            token: token.trim(),
            type: OtpType.signup,
          )
          .timeout(const Duration(seconds: 20));
      return _identity(response.user);
    } on AuthException catch (error) {
      throw AssalAuthFailure(_messageFor(error),
          code: error.code ?? error.statusCode);
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await client.rpc('delete_my_account');
      await client.auth.signOut();
    } on AuthException catch (error) {
      throw AssalAuthFailure(_messageFor(error),
          code: error.code ?? error.statusCode);
    }
  }

  @override
  Future<AssalAuthIdentity?> signInWithGoogle() async {
    throw const AssalAuthFailure(
        'تسجيل Google مؤجل للإصدار اللاحق. استخدم البريد الإلكتروني في الإصدار الحالي.',
        code: 'google_auth_deferred');
  }

  @override
  Future<AssalAuthIdentity?> signInWithFacebook() async {
    throw const AssalAuthFailure(
        'تسجيل Facebook مؤجل للإصدار اللاحق. استخدم البريد الإلكتروني في الإصدار الحالي.',
        code: 'facebook_auth_deferred');
  }

  @override
  Future<void> signOut() => client.auth.signOut();

  AssalAuthIdentity? _identity(User? user) {
    if (user == null) return null;
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    String? metadataString(String key) =>
        metadata[key] is String ? metadata[key] as String : null;
    return AssalAuthIdentity(
      id: user.id,
      email: user.email,
      displayName: metadataString('display_name') ??
          metadataString('full_name') ??
          metadataString('name'),
      avatarUrl: metadataString('avatar_url') ?? metadataString('picture'),
    );
  }

  String _messageFor(AuthException error) {
    final code = error.code?.toLowerCase();
    if (code == 'invalid_credentials') {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
    }
    if (code == 'email_not_confirmed') {
      return 'تحقق من بريدك الإلكتروني قبل تسجيل الدخول.';
    }
    if (code == 'bad_code' ||
        code == 'otp_expired' ||
        code == 'token_expired' ||
        code == 'invalid_token' ||
        code == 'invalid_or_already_used_token') {
      return 'رمز التحقق غير صحيح أو انتهت صلاحيته. اطلب رمزًا جديدًا وأدخله مرة واحدة.';
    }
    if (code == 'user_already_exists' || code == 'email_exists') {
      return 'يوجد حساب بهذا البريد الإلكتروني.';
    }
    if (code == 'user_not_found' || code == 'signup_disabled') {
      return 'لا يوجد حساب بهذا البريد الإلكتروني. اختر «إنشاء حساب» أولًا.';
    }
    if (code == 'weak_password' ||
        code == 'password_too_short' ||
        code == 'password_strength') {
      return 'اختر كلمة مرور أقوى: استخدم 8 أحرف على الأقل وامزج بين الحروف والأرقام والرموز.';
    }
    if (code == 'invalid_email' || code == 'email_address_invalid') {
      return 'أدخل بريدًا إلكترونيًا صالحًا.';
    }
    if (code == 'signup_disabled' || code == 'signup_disabled_for_otp') {
      return 'إنشاء الحسابات الجديدة غير مفعّل حاليًا. استخدم حسابًا موجودًا أو فعّل التسجيل من إعدادات الخدمة.';
    }
    if (code == 'over_request_rate_limit' ||
        code == 'over_email_send_rate_limit' ||
        code == 'email_send_rate_limit') {
      return 'تم تجاوز عدد محاولات الإرسال. انتظر قليلًا ثم حاول مرة أخرى.';
    }
    if (code == 'same_password') {
      return 'استخدم كلمة مرور مختلفة عن كلمة المرور السابقة.';
    }
    return 'تعذر إكمال المصادقة. تحقق من البيانات وحاول مرة أخرى.';
  }
}
