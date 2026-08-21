import 'dart:convert';
import 'dart:typed_data';

const maxPublicImageUploadBytes = 10 * 1024 * 1024;
const maxPrivateImageUploadBytes = 20 * 1024 * 1024;

String normalizePublicImageExtension(String extension) {
  switch (extension.trim().toLowerCase()) {
    case 'jpg':
    case 'jpeg':
      return 'jpg';
    case 'png':
      return 'png';
    case 'webp':
      return 'webp';
    case 'svg':
      return 'svg';
    default:
      throw const FormatException('unsupported_public_image_extension');
  }
}

String normalizePrivateImageExtension(String extension) {
  switch (extension.trim().toLowerCase()) {
    case 'jpg':
    case 'jpeg':
      return 'jpg';
    case 'png':
      return 'png';
    case 'webp':
      return 'webp';
    case 'pdf':
      return 'pdf';
    default:
      throw const FormatException('unsupported_private_upload_extension');
  }
}

void validateStorageUploadPath(String path) {
  final normalized = path.trim();
  if (normalized != path ||
      normalized.isEmpty ||
      normalized.length > 512 ||
      normalized.startsWith('/') ||
      normalized.endsWith('/') ||
      normalized.contains('..') ||
      normalized.contains('\\') ||
      normalized.contains('//') ||
      !RegExp(r'^[A-Za-z0-9][A-Za-z0-9._/-]*$').hasMatch(normalized)) {
    throw const FormatException('invalid_storage_upload_path');
  }
}

void validateImageUploadBytes(
  Uint8List bytes,
  String extension, {
  required int maxBytes,
}) {
  final safeExtension = extension.trim().toLowerCase();
  if (bytes.isEmpty || bytes.length > maxBytes) {
    throw const FormatException('invalid_image_upload_size');
  }
  final validSignature = switch (safeExtension) {
    'jpg' || 'jpeg' => _startsWith(bytes, const [0xff, 0xd8, 0xff]),
    'png' => _startsWith(
        bytes,
        const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
      ),
    'webp' =>
      _startsWith(bytes, const [0x52, 0x49, 0x46, 0x46]) &&
      _containsAt(bytes, const [0x57, 0x45, 0x42, 0x50], 8),
    'pdf' => _startsWith(bytes, const [0x25, 0x50, 0x44, 0x46, 0x2d]),
    'svg' => _looksLikeSvg(bytes),
    _ => false,
  };
  if (!validSignature) {
    throw const FormatException('image_signature_mismatch');
  }
}

bool _startsWith(Uint8List bytes, List<int> prefix) {
  if (bytes.length < prefix.length) return false;
  for (var index = 0; index < prefix.length; index++) {
    if (bytes[index] != prefix[index]) return false;
  }
  return true;
}

bool _containsAt(Uint8List bytes, List<int> value, int offset) {
  if (bytes.length < offset + value.length) return false;
  for (var index = 0; index < value.length; index++) {
    if (bytes[offset + index] != value[index]) return false;
  }
  return true;
}

bool _looksLikeSvg(Uint8List bytes) {
  final prefix = utf8.decode(
    bytes.length > 4096 ? bytes.sublist(0, 4096) : bytes,
    allowMalformed: true,
  ).trimLeft().toLowerCase();
  return prefix.startsWith('<svg') ||
      (prefix.startsWith('<?xml') && prefix.contains('<svg'));
}
