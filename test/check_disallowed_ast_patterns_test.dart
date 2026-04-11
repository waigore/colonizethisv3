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
  - id: stream_where_is_map_as
    message: 'use whereType'
    match:
      kind: stream_where_is_map_as
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

    test('flags .where is .map as chain', () {
      const src = r'''
import 'dart:async';

Stream<int> f(Stream<num> s) =>
    s.where((e) => e is int).map((e) => e as int);
''';
      final v = findDisallowedAstViolations(
        'packages/foo/lib/x.dart',
        src,
        rules,
      );
      expect(v, isNotEmpty);
      expect(v.first.ruleId, 'stream_where_is_map_as');
      expect(v.first.line, greaterThan(0));
    });

    test('allows whereType', () {
      const src = r'''
import 'dart:async';

Stream<int> f(Stream<num> s) => s.whereType<int>();
''';
      expect(
        findDisallowedAstViolations('packages/foo/lib/x.dart', src, rules),
        isEmpty,
      );
    });

    test('allows where+map without is/as pattern', () {
      const src = r'''
Iterable<String> f(Iterable<Object?> xs) =>
    xs.where((x) => x != null).map((x) => x as String);
''';
      expect(
        findDisallowedAstViolations('packages/foo/lib/x.dart', src, rules),
        isEmpty,
      );
    });

    test('stream_where_is_map_as respects same-line ignore', () {
      const src = r'''
import 'dart:async';

Stream<int> f(Stream<num> s) =>
    s.where((e) => e is int).map((e) => e as int); // ignore: disallowed_ast_stream_where_is_map_as
''';
      expect(
        findDisallowedAstViolations('packages/foo/lib/x.dart', src, rules),
        isEmpty,
      );
    });

    test('stream_where_is_map_as respects ignore on previous line', () {
      const src = r'''
import 'dart:async';

Stream<int> f(Stream<num> s) {
  // ignore: disallowed_ast_stream_where_is_map_as
  return s.where((e) => e is int).map((e) => e as int);
}
''';
      expect(
        findDisallowedAstViolations('packages/foo/lib/x.dart', src, rules),
        isEmpty,
      );
    });

    test('stream_where_is_map_as respects ignore_for_file', () {
      const src = r'''
// ignore_for_file: disallowed_ast_stream_where_is_map_as

import 'dart:async';

Stream<int> f(Stream<num> s) =>
    s.where((e) => e is int).map((e) => e as int);
''';
      expect(
        findDisallowedAstViolations('packages/foo/lib/x.dart', src, rules),
        isEmpty,
      );
    });
  });
}
