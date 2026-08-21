import 'dart:async';
import 'dart:typed_data';

import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_data/production_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('session cache avoids repeating profile/admin hydration reads', () async {
    final gateway = _CountingGateway();
    final auth = _StaticAuthGateway();
    final repository = ProductionRepository(gateway: gateway, authGateway: auth);

    final first = await repository.getSession();
    final second = await repository.getSession();

    expect(first.isAuthenticated, isTrue);
    expect(second.isAuthenticated, isTrue);
    expect(auth.currentIdentityCalls, 2, reason: 'auth identity is checked per call');
    expect(gateway.selectCalls['profiles'], 1);
    expect(gateway.selectCalls['admin_users'], 1);
  });

  test('concurrent session hydration reuses one in-flight read', () async {
    final gateway = _CountingGateway()..holdProfileRead = true;
    final auth = _StaticAuthGateway();
    final repository = ProductionRepository(gateway: gateway, authGateway: auth);

    final first = repository.getSession();
    await Future<void>.delayed(Duration.zero);
    final second = repository.getSession();
    gateway.releaseProfileRead();

    final sessions = await Future.wait([first, second]);
    expect(sessions, everyElement(isA<AssalSession>()));
    expect(gateway.selectCalls['profiles'], 1);
    expect(gateway.selectCalls['admin_users'], 1);
  });
}

class _StaticAuthGateway implements AssalAuthGateway {
  int currentIdentityCalls = 0;
  static const identity = AssalAuthIdentity(
    id: 'user-1',
    email: 'user@example.com',
    displayName: 'مستخدم الاختبار',
  );

  @override
  Future<AssalAuthIdentity?> currentIdentity() async {
    currentIdentityCalls++;
    return identity;
  }

  @override
  Future<AssalAuthIdentity?> signInWithPassword(String email, String password) async => identity;
  @override
  Future<void> requestEmailOtp(String email) async {}
  @override
  Future<AssalAuthIdentity?> verifyEmailOtp(String email, String token) async => identity;
  @override
  Future<AssalAuthIdentity?> signUp({required String name, required String email, required String password}) async => identity;
  @override
  Future<void> requestPasswordReset(String email) async {}
  @override
  Future<void> resendEmailConfirmation(String email) async {}
  @override
  Future<AssalAuthIdentity?> verifyEmailConfirmation(String email, String token) async => identity;
  @override
  Future<void> deleteAccount() async {}
  @override
  Future<AssalAuthIdentity?> signInWithGoogle() async => identity;
  @override
  Future<AssalAuthIdentity?> signInWithFacebook() async => identity;
  @override
  Future<void> signOut() async {}
}

class _CountingGateway implements ProductionQueryGateway {
  final Map<String, int> selectCalls = <String, int>{};
  bool holdProfileRead = false;
  Completer<void>? _profileGate;

  @override
  Future<List<Map<String, Object?>>> select(
    String table, {
    Map<String, Object?> filters = const <String, Object?>{},
  }) async {
    selectCalls[table] = (selectCalls[table] ?? 0) + 1;
    if (table == 'profiles' && holdProfileRead) {
      _profileGate ??= Completer<void>();
      await _profileGate!.future;
    }
    if (table == 'profiles') {
      return <Map<String, Object?>>[
        <String, Object?>{'user_id': 'user-1', 'display_name': 'مستخدم الاختبار', 'role': 'customer', 'is_active': true},
      ];
    }
    return <Map<String, Object?>>[];
  }

  void releaseProfileRead() {
    _profileGate ??= Completer<void>();
    if (!_profileGate!.isCompleted) _profileGate!.complete();
  }

  @override
  Future<Map<String, Object?>> insert(String table, Map<String, Object?> values) async => values;
  @override
  Future<Map<String, Object?>> update(String table, Map<String, Object?> values, {required String id}) async => values;
  @override
  Future<void> delete(String table, {Map<String, Object?> filters = const <String, Object?>{}}) async {}
  @override
  Future<Map<String, Object?>> upsert(String table, Map<String, Object?> values, {String? onConflict}) async => values;
  @override
  Future<Map<String, Object?>> rpc(String function, Map<String, Object?> params) async => <String, Object?>{};
  @override
  Future<String> uploadPublicImage(String path, Uint8List bytes, String extension) async => path;
  @override
  Future<String> uploadPrivateImage(String path, Uint8List bytes, String extension) async => path;
}
