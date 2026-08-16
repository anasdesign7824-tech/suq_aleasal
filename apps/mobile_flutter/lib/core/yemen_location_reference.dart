import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:assalkom_contracts/assal_domain.dart';

class AssalReferenceDataFailure implements Exception {
  const AssalReferenceDataFailure(this.messageAr);

  final String messageAr;

  @override
  String toString() => messageAr;
}

/// Immutable Yemen governorate/district reference used by both Demo and Production UI.
///
/// The public contract deliberately exposes stable source codes rather than generated
/// UUIDs. Production rows use the same codes, so a wizard can switch between local
/// reference data and Supabase rows without changing selected values.
class YemenLocationReference {
  YemenLocationReference._({required this.governorates, required this.districtsByGovernorateCode, required this.sourceSha256});

  static const assetPath = 'assets/yemen_governorates_districts.json';

  final List<AssalRegion> governorates;
  final Map<String, List<AssalRegion>> districtsByGovernorateCode;
  final String sourceSha256;

  static Future<YemenLocationReference> load([AssetBundle? bundle]) async {
    try {
      final content = await (bundle ?? rootBundle).loadString(assetPath);
      return fromJson(jsonDecode(content));
    } on AssalReferenceDataFailure {
      rethrow;
    } on Object catch (error) {
      throw AssalReferenceDataFailure('تعذر تحميل مرجع محافظات ومديريات اليمن: $error');
    }
  }

  static YemenLocationReference fromJson(Object? raw) {
    if (raw is! Map) {
      throw const AssalReferenceDataFailure('مرجع المواقع غير صالح: الجذر ليس كائن JSON.');
    }

    final root = raw.cast<String, Object?>();
    if (root['schema'] != 'assalkom.yemen_governorates_districts.v1') {
      throw const AssalReferenceDataFailure('مرجع المواقع غير متوافق مع إصدار عسلكم الحالي.');
    }

    final provenance = _map(root['provenance']);
    final sourceSha256 = _string(provenance['source_sha256']);
    if (sourceSha256.length != 64) {
      throw const AssalReferenceDataFailure('مرجع المواقع يفتقد بصمة المصدر SHA-256 الصحيحة.');
    }

    final governorateJson = _listOfMaps(root['governorates']);
    final governorates = <AssalRegion>[];
    final districtMap = <String, List<AssalRegion>>{};
    final seenCodes = <String>{};

    for (final governorate in governorateJson) {
      final governorateCode = _requiredString(governorate, 'code');
      if (!seenCodes.add(governorateCode)) {
        throw AssalReferenceDataFailure('مرجع المواقع يحتوي كودًا مكررًا: $governorateCode');
      }
      final governorateRegion = AssalRegion(
        id: governorateCode,
        code: governorateCode,
        nameAr: _requiredString(governorate, 'name_ar'),
        nameEn: _nullableString(governorate['name_en']),
        parentRegionId: null,
      );
      governorates.add(governorateRegion);

      final districts = <AssalRegion>[];
      for (final district in _listOfMaps(governorate['districts'])) {
        final districtCode = _requiredString(district, 'code');
        if (!seenCodes.add(districtCode)) {
          throw AssalReferenceDataFailure('مرجع المواقع يحتوي كودًا مكررًا: $districtCode');
        }
        districts.add(
          AssalRegion(
            id: districtCode,
            code: districtCode,
            nameAr: _requiredString(district, 'name_ar'),
            nameEn: _nullableString(district['name_en']),
            parentRegionId: governorateCode,
          ),
        );
      }
      districtMap[governorateCode] = List<AssalRegion>.unmodifiable(districts);
    }

    if (governatesCount(root) != governorates.length) {
      throw const AssalReferenceDataFailure('عدد المحافظات في مرجع المواقع لا يطابق البيانات المعلنة.');
    }
    final declaredDistrictCount = _map(root['counts'])['districts'];
    final actualDistrictCount = districtMap.values.fold<int>(0, (sum, items) => sum + items.length);
    if (declaredDistrictCount is! num || declaredDistrictCount.toInt() != actualDistrictCount) {
      throw const AssalReferenceDataFailure('عدد المديريات في مرجع المواقع لا يطابق البيانات الفعلية.');
    }

    return YemenLocationReference._(
      governorates: List<AssalRegion>.unmodifiable(governorates),
      districtsByGovernorateCode: Map<String, List<AssalRegion>>.unmodifiable(districtMap),
      sourceSha256: sourceSha256,
    );
  }

  List<AssalRegion> districtsFor(String? governorateCode) => governorateCode == null ? const <AssalRegion>[] : districtsByGovernorateCode[governorateCode] ?? const <AssalRegion>[];

  AssalRegion? governorateByCode(String? code) => _findByCode(governorates, code);

  AssalRegion? districtByCode(String? code) {
    for (final districts in districtsByGovernorateCode.values) {
      final match = _findByCode(districts, code);
      if (match != null) return match;
    }
    return null;
  }
}

int governatesCount(Map<String, Object?> root) {
  final value = _map(root['counts'])['governorates'];
  return value is num ? value.toInt() : -1;
}

AssalRegion? _findByCode(Iterable<AssalRegion> items, String? code) {
  if (code == null) return null;
  for (final item in items) {
    if (item.code == code) return item;
  }
  return null;
}

List<Map<String, Object?>> _listOfMaps(Object? value) => value is List ? value.whereType<Map>().map((item) => item.cast<String, Object?>()).toList(growable: false) : const <Map<String, Object?>>[];
Map<String, Object?> _map(Object? value) => value is Map ? value.cast<String, Object?>() : const <String, Object?>{};
String _requiredString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is String && value.trim().isNotEmpty) return value;
  throw AssalReferenceDataFailure('مرجع المواقع يفتقد الحقل $key.');
}
String _string(Object? value) => value is String ? value : '';
String? _nullableString(Object? value) => value is String && value.trim().isNotEmpty ? value : null;
