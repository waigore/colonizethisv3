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
  - id: widget_build_method_too_long
    message: 'widget build body too long'
    match:
      kind: method_body_line_span
      function_name: build
      max_body_line_span: 3
      require_widget_class_extends: true
  - id: sea_zone_local_id_extraction
    message: 'do not strip sea-zone ids to local'
    match:
      kind: sea_zone_local_id_extraction
      allowed_relative_paths:
        - packages/foo/lib/boundary.dart
  - id: sea_zone_bucket_lookup_without_canonical_key
    message: 'sea-zone bucket lookup requires canonical key'
    match:
      kind: sea_zone_bucket_lookup_without_canonical_key
      allowed_relative_paths:
        - packages/foo/lib/boundary.dart
  - id: province_lookup_unprefixed_literal
    message: 'prefixed province id literals required for lookup'
    match:
      kind: unprefixed_province_id_string_literal_argument
      method_names:
        - getProvince
        - tryGetProvince
        - resolveToFullProvinceId
      argument_index: 1
  - id: province_local_id_from_unprefixed_literal
    message: 'prefixed province id literals required for localIdFrom'
    match:
      kind: unprefixed_province_id_string_literal_argument
      method_names:
        - localIdFrom
      argument_index: 0
  - id: province_local_segment_boundary_only
    message: 'localSegmentFromStoredGameState is boundary-only'
    match:
      kind: province_local_segment_boundary_only
  - id: debug_console_logic_contract_boundary
    message: 'debug console must use logic contract imports only'
    match:
      kind: package_import_allowlist
      scoped_relative_path_prefixes:
        - packages/colonizethis_debug_console/lib/
      package_name: colonizethis_logic
      allowed_imports:
        - package:colonizethis_logic/debug_console_api.dart
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

    test('analyzes package test paths', () {
      const src = r'''
void f(List<int> a) {
  a..clear();
}
''';
      final violations = findDisallowedAstViolations(
        'packages/foo/test/x_test.dart',
        src,
        rules,
      );
      expect(violations, isNotEmpty);
      expect(violations.first.ruleId, 'cascade_void_clear');
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

    test('flags avoid_print suppression in package test path', () {
      const src = r'''
void f() {
  // ignore: avoid_print
  print('x');
}
''';
      final violations = findDisallowedAstViolations(
        'packages/foo/test/x_test.dart',
        src,
        rules,
      );
      expect(violations, isNotEmpty);
      expect(violations.first.ruleId, 'avoid_print_suppression');
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

    test('flags overlong widget build() body', () {
      const src = r'''
import 'package:flutter/widgets.dart';

class X extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final a = 1;
    final b = 2;
    return Text('$a$b');
  }
}
''';
      final v = findDisallowedAstViolations(
        'packages/foo/lib/x.dart',
        src,
        rules,
      );
      expect(v, isNotEmpty);
      expect(v.first.ruleId, 'widget_build_method_too_long');
    });

    test('allows short widget build() body', () {
      const src = r'''
import 'package:flutter/widgets.dart';

class X extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
''';
      expect(
        findDisallowedAstViolations('packages/foo/lib/x.dart', src, rules),
        isEmpty,
      );
    });

    test('ignores build() in non-widget classes', () {
      const src = r'''
class NotAWidget {
  Object build() {
    final a = 1;
    final b = 2;
    final c = 3;
    return a + b + c;
  }
}
''';
      expect(
        findDisallowedAstViolations('packages/foo/lib/x.dart', src, rules),
        isEmpty,
      );
    });

    test('widget_build_method_too_long respects suppression comment', () {
      const src = r'''
import 'package:flutter/widgets.dart';

class X extends StatefulWidget {
  const X({super.key});
  @override
  State<X> createState() => _XState();
}

class _XState extends State<X> {
  @override
  // ignore: disallowed_ast_widget_build_method_too_long
  Widget build(BuildContext context) {
    final a = 1;
    final b = 2;
    return Text('$a$b');
  }
}
''';
      expect(
        findDisallowedAstViolations('packages/foo/lib/x.dart', src, rules),
        isEmpty,
      );
    });

    test('flags unprefixed province id literal in lookup call', () {
      const src = r'''
void f(world) {
  getProvince(world, 'p1');
}
''';
      final v = findDisallowedAstViolations(
        'packages/foo/lib/x.dart',
        src,
        rules,
      );
      expect(v, isNotEmpty);
      expect(v.first.ruleId, 'province_lookup_unprefixed_literal');
    });

    test('allows prefixed province id literal in lookup call', () {
      const src = r'''
void f(world) {
  getProvince(world, 'oldWorld|p1');
}
''';
      expect(
        findDisallowedAstViolations('packages/foo/lib/x.dart', src, rules),
        isEmpty,
      );
    });

    test('allows non-literal lookup argument', () {
      const src = r'''
void f(world, String id) {
  getProvince(world, id);
}
''';
      expect(
        findDisallowedAstViolations('packages/foo/lib/x.dart', src, rules),
        isEmpty,
      );
    });

    test('flags unprefixed province id literal for localIdFrom helper', () {
      const src = r'''
void f() {
  ProvinceId.localIdFrom('p1');
}
''';
      final v = findDisallowedAstViolations(
        'packages/foo/lib/x.dart',
        src,
        rules,
      );
      expect(v, isNotEmpty);
      expect(v.first.ruleId, 'province_local_id_from_unprefixed_literal');
    });

    test('flags ProvinceId.localIdFrom on sea-zone ids', () {
      const src = r'''
import 'package:colonizethis_models/colonizethis_models.dart';

bool bad(String seaZoneId) => ProvinceId.localIdFrom(seaZoneId) == 's1';
''';
      final v = findDisallowedAstViolations(
        'packages/foo/lib/x.dart',
        src,
        rules,
      );
      expect(v, isNotEmpty);
      expect(v.first.ruleId, 'sea_zone_local_id_extraction');
    });

    test('allows ProvinceId.localIdFrom for non-sea-zone identifiers', () {
      const src = r'''
import 'package:colonizethis_models/colonizethis_models.dart';

bool ok(String provinceId) => ProvinceId.localIdFrom(provinceId) == 'p1';
''';
      final v = findDisallowedAstViolations(
        'packages/foo/lib/x.dart',
        src,
        rules,
      );
      expect(
        v.where((e) => e.ruleId == 'sea_zone_local_id_extraction'),
        isEmpty,
      );
    });

    test('flags ProvinceId.localSegmentFromStoredGameState usage', () {
      const src = r'''
import 'package:colonizethis_models/colonizethis_models.dart';

String bad(String provinceId) =>
    ProvinceId.localSegmentFromStoredGameState(provinceId);
''';
      final v = findDisallowedAstViolations(
        'packages/foo/lib/not_allowed.dart',
        src,
        rules,
      );
      expect(v, isNotEmpty);
      expect(v.first.ruleId, 'province_local_segment_boundary_only');
    });

    test('flags sea-zone bucket lookup without canonical key helper', () {
      const src = r'''
class X {
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince = const {};
  List<String> read(String regionId, String seaZoneId) {
    return tileKeysByRegionAndProvince[regionId]?[seaZoneId] ?? const [];
  }
}
''';
      final v = findDisallowedAstViolations(
        'packages/foo/lib/x.dart',
        src,
        rules,
      );
      expect(v, isNotEmpty);
      expect(v.first.ruleId, 'sea_zone_bucket_lookup_without_canonical_key');
    });

    test('allows sea-zone bucket lookup with canonical helper', () {
      const src = r'''
String canonicalSeaZoneTileBucketKey(String regionId, String seaZoneId) =>
    '$regionId|$seaZoneId';

class X {
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince = const {};
  List<String> read(String regionId, String seaZoneId) {
    final bucket = canonicalSeaZoneTileBucketKey(regionId, seaZoneId);
    return tileKeysByRegionAndProvince[regionId]?[bucket] ?? const [];
  }
}
''';
      expect(
        findDisallowedAstViolations(
          'packages/foo/lib/x.dart',
          src,
          rules,
        ).where(
          (e) => e.ruleId == 'sea_zone_bucket_lookup_without_canonical_key',
        ),
        isEmpty,
      );
    });

    test('sea-zone rule ignores are rejected outside allowlisted boundary', () {
      const src = r'''
import 'package:colonizethis_models/colonizethis_models.dart';

bool bad(String seaZoneId) {
  // ignore: disallowed_ast_sea_zone_local_id_extraction
  return ProvinceId.localIdFrom(seaZoneId) == 's1';
}
''';
      final v = findDisallowedAstViolations(
        'packages/foo/lib/not_boundary.dart',
        src,
        rules,
      );
      expect(
        v.where((e) => e.ruleId == 'sea_zone_local_id_extraction'),
        isNotEmpty,
      );
    });

    test('sea-zone rule ignores are allowed in allowlisted boundary file', () {
      const src = r'''
import 'package:colonizethis_models/colonizethis_models.dart';

bool ok(String seaZoneId) {
  // ignore: disallowed_ast_sea_zone_local_id_extraction
  return ProvinceId.localIdFrom(seaZoneId) == 's1';
}
''';
      final v = findDisallowedAstViolations(
        'packages/foo/lib/boundary.dart',
        src,
        rules,
      );
      expect(
        v.where((e) => e.ruleId == 'sea_zone_local_id_extraction'),
        isEmpty,
      );
    });

    test('allows allowlisted logic contract import in debug console scope', () {
      const src = r'''
import 'package:colonizethis_logic/debug_console_api.dart';
''';
      expect(
        findDisallowedAstViolations(
          'packages/colonizethis_debug_console/lib/panel.dart',
          src,
          rules,
        ).where((e) => e.ruleId == 'debug_console_logic_contract_boundary'),
        isEmpty,
      );
    });

    test(
      'flags debug console import from colonizethis_logic src internals',
      () {
        const src = r'''
import 'package:colonizethis_logic/src/world_state.dart';
''';
        final violations = findDisallowedAstViolations(
          'packages/colonizethis_debug_console/lib/panel.dart',
          src,
          rules,
        );
        expect(violations, isNotEmpty);
        expect(
          violations.first.ruleId,
          'debug_console_logic_contract_boundary',
        );
      },
    );

    test('flags debug console import from non-contract logic entrypoint', () {
      const src = r'''
import 'package:colonizethis_logic/colonizethis_logic.dart';
''';
      final violations = findDisallowedAstViolations(
        'packages/colonizethis_debug_console/lib/panel.dart',
        src,
        rules,
      );
      expect(violations, isNotEmpty);
      expect(violations.first.ruleId, 'debug_console_logic_contract_boundary');
    });
  });
}
