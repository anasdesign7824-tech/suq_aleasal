import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom_data/storage_upload_policy.dart';

void main() {
  test('normalizes only supported public and private extensions', () {
    expect(normalizePublicImageExtension(' JPEG '), 'jpg');
    expect(normalizePublicImageExtension('webp'), 'webp');
    expect(normalizePrivateImageExtension('PDF'), 'pdf');
    expect(
      () => normalizePublicImageExtension('gif'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => normalizePrivateImageExtension('svg'),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects traversal, absolute, duplicated-separator, and malformed paths', () {
    for (final path in <String>[
      '../private/file.png',
      r'user\private\file.png',
      '/absolute/file.png',
      'user//private/file.png',
      ' user/private/file.png',
      'user/private/file.png ',
      'user/private/../file.png',
    ]) {
      expect(
        () => validateStorageUploadPath(path),
        throwsA(isA<FormatException>()),
        reason: path,
      );
    }
    expect(
      () => validateStorageUploadPath('user/private/file.png'),
      returnsNormally,
    );
  });

  test('requires matching magic bytes and enforces the private size limit', () {
    final png = Uint8List.fromList(<int>[
      0x89,
      0x50,
      0x4e,
      0x47,
      0x0d,
      0x0a,
      0x1a,
      0x0a,
    ]);
    validateImageUploadBytes(
      png,
      'png',
      maxBytes: maxPrivateImageUploadBytes,
    );
    expect(
      () => validateImageUploadBytes(
        Uint8List.fromList(<int>[1, 2, 3]),
        'png',
        maxBytes: maxPrivateImageUploadBytes,
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => validateImageUploadBytes(
        Uint8List(maxPrivateImageUploadBytes + 1),
        'png',
        maxBytes: maxPrivateImageUploadBytes,
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('accepts PDF and SVG signatures only on their declared extensions', () {
    validateImageUploadBytes(
      Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46, 0x2d]),
      'pdf',
      maxBytes: maxPrivateImageUploadBytes,
    );
    validateImageUploadBytes(
      Uint8List.fromList('<svg xmlns="http://www.w3.org/2000/svg"/>'.codeUnits),
      'svg',
      maxBytes: maxPublicImageUploadBytes,
    );
  });
}
