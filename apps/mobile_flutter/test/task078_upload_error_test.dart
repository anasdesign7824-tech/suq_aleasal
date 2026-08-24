import 'dart:typed_data';

import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_data/production_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _UploadGateway implements ProductionQueryGateway {
  int uploadCalls = 0;
  int insertCalls = 0;

  @override
  Future<List<Map<String, Object?>>> select(
    String table, {
    Map<String, Object?> filters = const <String, Object?>{},
  }) async {
    if (table == 'stores') {
      return const <Map<String, Object?>>[
        {'id': 'store-078', 'merchant_id': 'merchant-078'},
      ];
    }
    if (table == 'products') {
      return const <Map<String, Object?>>[
        {'id': 'product-078', 'store_id': 'store-078'},
      ];
    }
    return const <Map<String, Object?>>[];
  }

  @override
  Future<String> uploadPublicImage(
    String path,
    Uint8List bytes,
    String extension,
  ) async {
    uploadCalls += 1;
    return 'https://cdn.example/$path';
  }

  @override
  Future<Map<String, Object?>> insert(
    String table,
    Map<String, Object?> values,
  ) async {
    insertCalls += 1;
    return values;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  test('TASK 078 returns validation state for unsupported merchant image type',
      () async {
    final gateway = _UploadGateway();
    final repository = ProductionRepository(gateway: gateway);

    final result = await repository.uploadMerchantImage(
      'merchant-078',
      'logo',
      Uint8List.fromList([1, 2, 3]),
      'gif',
    );

    final error = result as AssalError<String>;
    expect(error.kind, AssalErrorKind.validation);
    expect(error.retryable, isFalse);
    expect(error.code, 'upload_validation_failed');
    expect(error.messageAr, contains('صيغة الملف'));
    expect(gateway.uploadCalls, 0);
  });

  test('TASK 078 rejects unsupported gallery and product extensions', () async {
    final gateway = _UploadGateway();
    final repository = ProductionRepository(gateway: gateway);
    final bytes = Uint8List.fromList([1, 2, 3]);

    final gallery = await repository.uploadStoreGalleryImage(
      'merchant-078',
      'store-078',
      bytes,
      'gif',
    );
    final product = await repository.uploadProductImage(
      'merchant-078',
      'product-078',
      bytes,
      'gif',
    );

    expect((gallery as AssalError<String>).kind, AssalErrorKind.validation);
    expect((product as AssalError<String>).kind, AssalErrorKind.validation);
    expect(gateway.uploadCalls, 0);
    expect(gateway.insertCalls, 0);
  });
}
