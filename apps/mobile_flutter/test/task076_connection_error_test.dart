import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_data/production_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _NetworkGateway implements ProductionQueryGateway {
  @override
  Future<List<Map<String, Object?>>> select(
    String table, {
    Map<String, Object?> filters = const <String, Object?>{},
  }) async {
    throw StateError('network unavailable');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _UnavailableAuthGateway implements AssalAuthGateway {
  @override
  Future<AssalAuthIdentity?> currentIdentity() async {
    throw StateError('network unavailable');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  test('TASK 076 classifies generic network reads as retryable', () async {
    final repository = ProductionRepository(gateway: _NetworkGateway());

    final result = await repository.listCategories();

    expect(result, isA<AssalError<List<AssalCategorySummary>>>());
    final error = result as AssalError<List<AssalCategorySummary>>;
    expect(error.kind, AssalErrorKind.network);
    expect(error.retryable, isTrue);
    expect(error.code, 'network');
    expect(error.messageAr, contains('تحقق من الاتصال'));
  });

  test('TASK 076 maps auth gateway network failure to unavailable session',
      () async {
    final repository = ProductionRepository(
      gateway: _NetworkGateway(),
      authGateway: _UnavailableAuthGateway(),
    );

    final session = await repository.getSession();

    expect(session.isUnavailable, isTrue);
    expect(session.errorMessageAr, contains('مزامنة جلسة الحساب'));
  });
}
