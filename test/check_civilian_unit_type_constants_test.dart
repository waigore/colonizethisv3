import 'package:test/test.dart';

import '../tool/check_civilian_unit_type_constants.dart';

void main() {
  const canonicalCivilianUnitTypeIds = <String>{'Explorer', 'Builder', 'Spy'};
  const constantNameById = <String, String>{
    'Explorer': 'kUnitTypeExplorer',
    'Builder': 'kUnitTypeBuilder',
    'Spy': 'kUnitTypeSpy',
  };

  group('findCivilianUnitTypeConstantViolations', () {
    test('flags executable raw civilian unit type string literal', () {
      const src = r'''
void f() {
  const t = 'Builder';
  print(t);
}
''';
      final violations = findCivilianUnitTypeConstantViolations(
        relativePath: 'packages/foo/lib/x.dart',
        source: src,
        canonicalCivilianUnitTypeIds: canonicalCivilianUnitTypeIds,
        constantNameById: constantNameById,
      );
      expect(violations, isNotEmpty);
      expect(violations.first.message, contains('kUnitTypeBuilder'));
      expect(violations.first.line, greaterThan(0));
      expect(violations.first.column, greaterThan(0));
    });

    test('allows non-canonical literal', () {
      const src = r'''
void f() {
  const t = 'Warship';
  print(t);
}
''';
      final violations = findCivilianUnitTypeConstantViolations(
        relativePath: 'packages/foo/lib/x.dart',
        source: src,
        canonicalCivilianUnitTypeIds: canonicalCivilianUnitTypeIds,
        constantNameById: constantNameById,
      );
      expect(violations, isEmpty);
    });

    test('does not flag top-level constant declarations', () {
      const src = r'''
const String kDemo = 'Explorer';
void f() {}
''';
      final violations = findCivilianUnitTypeConstantViolations(
        relativePath: 'packages/foo/lib/x.dart',
        source: src,
        canonicalCivilianUnitTypeIds: canonicalCivilianUnitTypeIds,
        constantNameById: constantNameById,
      );
      expect(violations, isEmpty);
    });

    test('skips generated file paths', () {
      const src = r'''
void f() {
  final t = 'Spy';
  print(t);
}
''';
      final violations = findCivilianUnitTypeConstantViolations(
        relativePath: 'packages/foo/lib/x.g.dart',
        source: src,
        canonicalCivilianUnitTypeIds: canonicalCivilianUnitTypeIds,
        constantNameById: constantNameById,
      );
      expect(violations, isEmpty);
    });

    test('skips test-data fixture directories', () {
      const src = r'''
void f() {
  final t = 'Builder';
  print(t);
}
''';
      final violations = findCivilianUnitTypeConstantViolations(
        relativePath: 'packages/foo/lib/test_data/sample.dart',
        source: src,
        canonicalCivilianUnitTypeIds: canonicalCivilianUnitTypeIds,
        constantNameById: constantNameById,
      );
      expect(violations, isEmpty);
    });

    test(
      'skips hand-maintained app l10n part files (display labels may '
      'coincide with civilian unit type ids)',
      () {
        const src = r'''
mixin _AppLocalizationsEnStrings2 on AppLocalizations {
  @override
  String get example_role_label => 'Builder';
}
''';
        for (final relPath in <String>[
          'app/lib/l10n/app_localizations_en_part1.dart',
          'app/lib/l10n/app_localizations_en_part2.dart',
          'app/lib/l10n/app_localizations_en_part3.dart',
          'app/lib/l10n/app_localizations_en_part4.dart',
          'app/lib/l10n/app_localizations_en_part5.dart',
        ]) {
          final violations = findCivilianUnitTypeConstantViolations(
            relativePath: relPath,
            source: src,
            canonicalCivilianUnitTypeIds: canonicalCivilianUnitTypeIds,
            constantNameById: constantNameById,
          );
          expect(
            violations,
            isEmpty,
            reason: 'expected $relPath to be skipped by the l10n carve-out',
          );
        }
      },
    );
  });
}
