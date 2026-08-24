import 'package:test/test.dart';

import '../tool/check_tech_id_constants.dart';

void main() {
  const techIds = <String>{'land_enclosure', 'saw_mill'};
  const constantNameByTechId = <String, String>{
    'land_enclosure': 'kTechIdLandEnclosure',
    'saw_mill': 'kTechIdSawMill',
  };

  group('findTechIdConstantViolations', () {
    test('flags executable raw tech id string literal', () {
      const src = r'''
void f() {
  const t = 'land_enclosure';
  print(t);
}
''';
      final violations = findTechIdConstantViolations(
        relativePath: 'packages/foo/lib/x.dart',
        source: src,
        techIds: techIds,
        constantNameByTechId: constantNameByTechId,
      );
      expect(violations, isNotEmpty);
      expect(violations.first.message, contains('kTechIdLandEnclosure'));
      expect(violations.first.line, greaterThan(0));
      expect(violations.first.column, greaterThan(0));
    });

    test('allows non-catalog literal', () {
      const src = r'''
void f() {
  const t = 'not_a_tech';
  print(t);
}
''';
      final violations = findTechIdConstantViolations(
        relativePath: 'packages/foo/lib/x.dart',
        source: src,
        techIds: techIds,
        constantNameByTechId: constantNameByTechId,
      );
      expect(violations, isEmpty);
    });

    test('does not flag top-level constant declarations', () {
      const src = r'''
const String kDemo = 'land_enclosure';
void f() {}
''';
      final violations = findTechIdConstantViolations(
        relativePath: 'packages/foo/lib/x.dart',
        source: src,
        techIds: techIds,
        constantNameByTechId: constantNameByTechId,
      );
      expect(violations, isEmpty);
    });

    test('flags raw catalog tech-id map keys in extraction-cap table files', () {
      const src = r'''
final Map<String, Map<String, int>> table = {
  'grain': const {
    'land_enclosure': 2,
  },
};
''';
      final violations = findTechIdConstantViolations(
        relativePath:
            'packages/colonizethis_data/lib/src/tech_extraction_caps_ow_food.dart',
        source: src,
        techIds: techIds,
        constantNameByTechId: constantNameByTechId,
      );
      expect(violations, isNotEmpty);
      expect(violations.first.message, contains('land_enclosure'));
      expect(violations.first.message, contains('kTechIdLandEnclosure'));
    });

    test(
      'does not flag extraction-cap map keys outside tech_extraction_caps*.dart',
      () {
        const src = r'''
final Map<String, Map<String, int>> table = {
  'grain': const {
    'land_enclosure': 2,
  },
};
''';
        final violations = findTechIdConstantViolations(
          relativePath: 'packages/colonizethis_data/lib/src/other_tables.dart',
          source: src,
          techIds: techIds,
          constantNameByTechId: constantNameByTechId,
        );
        expect(violations, isEmpty);
      },
    );

    test('skips generated file paths', () {
      const src = r'''
void f() {
  final t = 'saw_mill';
  print(t);
}
''';
      final violations = findTechIdConstantViolations(
        relativePath: 'packages/foo/lib/x.g.dart',
        source: src,
        techIds: techIds,
        constantNameByTechId: constantNameByTechId,
      );
      expect(violations, isEmpty);
    });
  });
}
