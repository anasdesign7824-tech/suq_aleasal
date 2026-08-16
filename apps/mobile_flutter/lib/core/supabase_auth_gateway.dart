import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:assalkom_data/assal_repository.dart';

class SupabaseAuthGateway implements AssalAuthGateway {
  SupabaseAuthGateway({required this.client, this.androidRedirect = 'com.assalkom.assalkom://login-callback/'});

  final SupabaseClient client;
  final String androidRedirect;

  @override
  Future<AssalAuthIdentity?> currentIdentity() async => _identity(client.auth.currentUser);

  @override
  Future<AssalAuthIdentity?> signInWithPassword(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(email: email.trim(), password: password);
      return _identity(response.user);
    } on AuthException catch (error) {
      throw AssalAuthFailure(_messageFor(error), code: error.statusCode ?? error.code);
    }
  }

  @override
  Future<AssalAuthIdentity?> signUp({required String name, required String email, required String password}) async {
    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: <String, Object?>{'display_name': name.trim()},
      );
      final identity = _identity(response.user);
      if (identity == null && response.session == null) {
        throw const AssalAuthFailure('تم إنشاء الحساب. تحقق من بريدك الإلكتروني لتأكيد الحساب ثم سجّل الدخول.', code: 'email_confirmation_required');
      }
      return identity;
    } on AssalAuthFailure {
      rethrow;
    } on AuthException catch (error) {
      throw AssalAuthFailure(_messageFor(error), code: error.statusCode ?? error.code);
    }
  }

  @override
  Future<AssalAuthIdentity?> signInWithGoogle() => _oauth(OAuthProvider.google, 'Google');

  @override
  Future<AssalAuthIdentity?> signInWithFacebook() => _oauth(OAuthProvider.facebook, 'Facebook');

  Future<AssalAuthIdentity?> _oauth(OAuthProvider provider, String providerName) async {
    try {
      final started = await client.auth.signInWithOAuth(
        provider,
        redirectTo: kIsWeb ? null : androidRedirect,
      );
      if (!started) {
        throw AssalAuthFailure('تعذر بدء تسجيل الدخول عبر $providerName.', code: 'oauth_start_failed');
      }
      final identity = _identity(client.auth.currentUser);
      if (identity == null) {
        throw AssalAuthFailure('تم فتح تسجيل الدخول عبر $providerName. أكمل الخطوة في المتصفح ثم عد إلى عسلكم.', code: 'oauth_started');
      }
      return identity;
    } on AssalAuthFailure {
      rethrow;
    } on AuthException catch (error) {
      throw AssalAuthFailure(_messageFor(error), code: error.statusCode ?? error.code);
    }
  }

  @override
  Future<void> signOut() => client.auth.signOut();

  AssalAuthIdentity? _identity(User? user) {
    if (user == null) return null;
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    String? metadataString(String key) => metadata[key] is String ? metadata[key] as String : null;
    return AssalAuthIdentity(
      id: user.id,
      email: user.email,
      displayName: metadataString('display_name') ?? metadataString('full_name') ?? metadataString('name'),
      avatarUrl: metadataString('avatar_url') ?? metadataString('picture'),
    );
  }

  String _messageFor(AuthException error) {
    final code = error.code?.toLowerCase();
    if (code == 'invalid_credentials') return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
    if (code == 'email_not_confirmed') return 'تحقق من بريدك الإلكتروني قبل تسجيل الدخول.';
    if (code == 'user_already_exists') return 'يوجد حساب بهذا البريد الإلكتروني.';
    if (code == 'weak_password') return 'اختر كلمة مرور أقوى.';
    return error.message.isEmpty ? 'تعذر إكمال المصادقة. حاول مرة أخرى.' : error.message;
  }
}
