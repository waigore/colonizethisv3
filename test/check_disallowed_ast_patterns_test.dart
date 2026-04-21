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
  - id: avoid_print_suppression
    message: 'do not suppress avoid_print'
    match:
      kind: comment_substring
      contains: 'ignore: avoid_print'
  - id: strict_raw_types
    message: 'no raw generic core types'
    match:
      kind: raw_named_type
      type_names:
        - List
        - Map
        - Set
        - Iterable
        - Future
        - Stream
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

    test('flags avoid_print suppression comment', () {
      const src = r'''
void f() {
  // ignore: avoid_print
  print('x');
}
''';
      final v = findDisallowedAstViolations(
        'packages/foo/lib/x.dart',
        src,
        rules,
      );
      expect(v, isNotEmpty);
      expect(v.first.ruleId, 'avoid_print_suppression');
    });

    test('allows avoid_print suppression in excluded test path', () {
      const src = r'''
void f() {
  // ignore: avoid_print
  print('x');
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

    test('flags raw generic core type declarations', () {
      const src = r'''
class X {
  List values = [];
}
''';
      final v = findDisallowedAstViolations(
        'packages/foo/lib/x.dart',
        src,
        rules,
      );
      expect(v, isNotEmpty);
      expect(v.first.ruleId, 'strict_raw_types');
    });

    test('allows explicit generic type arguments', () {
      const src = r'''
class X {
  List<int> values = <int>[];
}
''';
      expect(
        findDisallowedAstViolations('packages/foo/lib/x.dart', src, rules),
        isEmpty,
      );
    });

    test('strict_raw_types respects suppression comment', () {
      const src = r'''
// ignore_for_file: disallowed_ast_strict_raw_types

class X {
  Map value = {};
}
''';
      expect(
        findDisallowedAstViolations('packages/foo/lib/x.dart', src, rules),
        isEmpty,
      );
    });
  });
}
