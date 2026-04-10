import 'package:test/test.dart';

import '../tool/check_disallowed_ast_patterns.dart';

const _testYaml = r'''
rules:
  - id: cascade_void_clear
    message: 'no cascade clear'
    match:
      kind: cascaded_method_invocation
      method_names:
        - clear
''';

void main() {
  late List<DisallowedPatternRule> rules;

  setUp(() {
    rules = loadDisallowedAstRulesForTest(_testYaml);
  });

  group('findDisallowedAstViolations', () {
    test('flags cascaded clear()', () {
      const src = r'''
void f(List<int> a) {
  a..clear()..add(1);
}
''';
      final v = findDisallowedAstViolations(
        'packages/foo/lib/x.dart',
        src,
        rules,
      );
      expect(v, isNotEmpty);
      expect(v.first.ruleId, 'cascade_void_clear');
      expect(v.first.line, greaterThan(0));
    });

    test('allows non-cascaded clear()', () {
      const src = r'''
void f(List<int> a) {
  a.clear();
  a.add(1);
}
''';
      expect(
        findDisallowedAstViolations('packages/foo/lib/x.dart', src, rules),
        isEmpty,
      );
    });

    test('respects same-line ignore', () {
      const src = r'''
void f(List<int> a) {
  a..clear()..add(1); // ignore: disallowed_ast_cascade_void_clear
}
''';
      expect(
        findDisallowedAstViolations('packages/foo/lib/x.dart', src, rules),
        isEmpty,
      );
    });

    test('respects ignore on previous line', () {
      const src = r'''
void f(List<int> a) {
  // ignore: disallowed_ast_cascade_void_clear
  a..clear()..add(1);
}
''';
      expect(
        findDisallowedAstViolations('packages/foo/lib/x.dart', src, rules),
        isEmpty,
      );
    });

    test('respects ignore_for_file', () {
      const src = r'''
// ignore_for_file: disallowed_ast_cascade_void_clear

void f(List<int> a) {
  a..clear()..add(1);
}
''';
      expect(
        findDisallowedAstViolations('packages/foo/lib/x.dart', src, rules),
        isEmpty,
      );
    });

    test('skips test paths', () {
      const src = r'''
void f(List<int> a) {
  a..clear();
}
''';
      expect(
        findDisallowedAstViolations(
          'packages/foo/test/x_test.dart',
          src,
          rules,
        ),
        isEmpty,
      );
    });
  });
}
