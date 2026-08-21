import 'dart:io';

import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_data/production_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ProductionRepository recovers after a transient read failure',
      () async {
    final gateway = _FlakyRegionsGateway();
    final repository = ProductionRepository(gateway: gateway);

    final failed = await repository.listRegions();
    expect(failed, isA<AssalError<List<AssalRegion>>>());
    final error = failed as AssalError<List<AssalRegion>>;
    expect(error.kind, AssalErrorKind.network);
    expect(error.code, 'network');
    expect(error.retryable, isTrue);
    expect(failed, isNot(isA<AssalData<List<AssalRegion>>>()));

    final recovered = await repository.listRegions();
    expect(recovered, isA<AssalData<List<AssalRegion>>>());
    expect((recovered as AssalData<List<AssalRegion>>).value.single.nameAr,
        'حضرموت');
    expect(gateway.calls, 2);
  });
}

class _FlakyRegionsGateway implements ProductionQueryGateway {
  int calls = 0;

  @override
  Future<List<Map<String, Object?>>> select(
    String table, {
    Map<String, Object?> filters = const <String, Object?>{},
  }) async {
    expect(table, 'regions');
    expect(filters, {'is_active': true});
    calls += 1;
    if (calls == 1) throw const SocketException('network unavailable');
    return const <Map<String, Object?>>[
      {'id': 'region-1', 'name_ar': 'حضرموت', 'is_active': true},
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
