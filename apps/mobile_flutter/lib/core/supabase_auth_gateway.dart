import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:assalkom_data/assal_repository.dart';

class SupabaseAuthGateway implements AssalAuthGateway {
  const SupabaseAuthGateway({required this.client});

  final SupabaseClient client;

  @override
  Future<AssalAuthIdentity?> currentIdentity() async =>
      _identity(client.auth.currentUser);

  @override
  Future<AssalAuthIdentity?> signInWithPassword(
      String email, String password) async {
    try {
      final response = await client.auth
          .signInWithPassword(email: email.trim(), password: password);
      return _identity(response.user);
    } on AuthException catch (error) {
      throw AssalAuthFailure(_messageFor(error),
          code: error.statusCode ?? error.code);
    }
  }

  @override
  Future<AssalAuthIdentity?> signUp(
      {required String name,
      required String email,
      required String password}) async {
    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: <String, Object?>{'display_name': name.trim()},
      );
      final identity = _identity(response.user);
      if (identity == null && response.session == null) {
        throw const AssalAuthFailure(
            'تم إنشاء الحساب. تحقق من بريدك الإلكتروني لتأكيد الحساب ثم سجّل الدخول.',
            code: 'email_confirmation_required');
      }
      return identity;
    } on AssalAuthFailure {
      rethrow;
    } on AuthException catch (error) {
      throw AssalAuthFailure(_messageFor(error),
          code: error.statusCode ?? error.code);
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (error) {
      throw AssalAuthFailure(_messageFor(error),
          code: error.statusCode ?? error.code);
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await client.rpc('delete_my_account');
      await client.auth.signOut();
    } on AuthException catch (error) {
      throw AssalAuthFailure(_messageFor(error),
          code: error.statusCode ?? error.code);
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
    if (code == 'user_already_exists') {
      return 'يوجد حساب بهذا البريد الإلكتروني.';
    }
    if (code == 'weak_password') {
      return 'اختر كلمة مرور أقوى.';
    }
    if (code == 'over_request_rate_limit') {
      return 'تم تجاوز عدد المحاولات. انتظر قليلًا ثم حاول مرة أخرى.';
    }
    return error.message.isEmpty
        ? 'تعذر إكمال المصادقة. حاول مرة أخرى.'
        : error.message;
  }
}
