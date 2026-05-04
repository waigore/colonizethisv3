import 'package:test/test.dart';

import '../tool/check_work_target_constants.dart';

void main() {
  const canonicalWorkTargets = <String>{'explore', 'prospect', 'steal_tech'};
  const constantNameByWorkTarget = <String, String>{
    'explore': 'kWorkTargetExplore',
    'prospect': 'kWorkTargetProspect',
    'steal_tech': 'kWorkTargetStealTech',
  };

  group('findWorkTargetConstantViolations', () {
    test('flags executable raw work target string literal', () {
      const src = r'''
void f() {
  const target = 'explore';
  print(target);
}
''';
      final violations = findWorkTargetConstantViolations(
        relativePath: 'packages/foo/lib/x.dart',
        source: src,
        canonicalWorkTargets: canonicalWorkTargets,
        constantNameByWorkTarget: constantNameByWorkTarget,
      );
      expect(violations, isNotEmpty);
      expect(violations.first.message, contains('kWorkTargetExplore'));
      expect(violations.first.line, greaterThan(0));
      expect(violations.first.column, greaterThan(0));
    });

    test('allows non-canonical literal', () {
      const src = r'''
void f() {
  const target = 'not_a_work_target';
  print(target);
}
''';
      final violations = findWorkTargetConstantViolations(
        relativePath: 'packages/foo/lib/x.dart',
        source: src,
        canonicalWorkTargets: canonicalWorkTargets,
        constantNameByWorkTarget: constantNameByWorkTarget,
      );
      expect(violations, isEmpty);
    });

    test('does not flag top-level constant declarations', () {
      const src = r'''
const String kDemo = 'explore';
void f() {}
''';
      final violations = findWorkTargetConstantViolations(
        relativePath: 'packages/foo/lib/x.dart',
        source: src,
        canonicalWorkTargets: canonicalWorkTargets,
        constantNameByWorkTarget: constantNameByWorkTarget,
      );
      expect(violations, isEmpty);
    });

    test('skips generated file paths', () {
      const src = r'''
void f() {
  final target = 'prospect';
  print(target);
}
''';
      final violations = findWorkTargetConstantViolations(
        relativePath: 'packages/foo/lib/x.g.dart',
        source: src,
        canonicalWorkTargets: canonicalWorkTargets,
        constantNameByWorkTarget: constantNameByWorkTarget,
      );
      expect(violations, isEmpty);
    });

    test('skips flutter gen-l10n app output paths', () {
      const src = r'''
void f() {
  final target = 'explore';
  print(target);
}
''';
      final violations = findWorkTargetConstantViolations(
        relativePath: 'app/lib/l10n/gen/app_l10n_flutter_gen_en.dart',
        source: src,
        canonicalWorkTargets: canonicalWorkTargets,
        constantNameByWorkTarget: constantNameByWorkTarget,
      );
      expect(violations, isEmpty);
    });

    test('skips test-data fixture directories', () {
      const src = r'''
void f() {
  final target = 'steal_tech';
  print(target);
}
''';
      final violations = findWorkTargetConstantViolations(
        relativePath: 'packages/foo/lib/test_data/sample.dart',
        source: src,
        canonicalWorkTargets: canonicalWorkTargets,
        constantNameByWorkTarget: constantNameByWorkTarget,
      );
      expect(violations, isEmpty);
    });
  });
}
