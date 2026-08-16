import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:assalkom/core/yemen_location_reference.dart';

void main() {
  test('parses the pinned Yemen reference and exposes cascading districts', () {
    final reference = YemenLocationReference.fromJson(jsonDecode(_fixture));

    expect(reference.governorates, hasLength(2));
    expect(reference.districtsByGovernorateCode['YE-GOV-001'], hasLength(2));
    expect(reference.districtsFor('YE-GOV-001').first.nameAr, 'صنعاء القديمة');
    expect(reference.districtsFor('YE-GOV-999'), isEmpty);
    expect(reference.governorateByCode('YE-GOV-001')?.nameAr, 'أمانة العاصمة');
    expect(reference.districtByCode('YE-DST-020-001')?.parentRegionId, 'YE-GOV-020');
  });

  test('rejects an incompatible schema', () {
    expect(
      () => YemenLocationReference.fromJson({'schema': 'wrong'}),
      throwsA(isA<AssalReferenceDataFailure>()),
    );
  });
}

const _fixture = '''
{
  "schema": "assalkom.yemen_governorates_districts.v1",
  "provenance": {"source_sha256": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"},
  "counts": {"governorates": 2, "districts": 3},
  "governorates": [
    {"code": "YE-GOV-001", "name_ar": "أمانة العاصمة", "name_en": "Amant Al-Asmah", "districts": [
      {"code": "YE-DST-001-001", "name_ar": "صنعاء القديمة", "name_en": "Sana'a Al-qdimah"},
      {"code": "YE-DST-001-002", "name_ar": "آزال", "name_en": "Azal"}
    ]},
    {"code": "YE-GOV-020", "name_ar": "ريمة", "name_en": "Raymah", "districts": [
      {"code": "YE-DST-020-001", "name_ar": "الجبين", "name_en": "Al Jabin"}
    ]}
  ]
}
''';
