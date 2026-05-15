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
  - id: sea_zone_bucket_lookup_without_canonical_key
    message: 'sea-zone bucket lookup requires canonical key'
    match:
      kind: sea_zone_bucket_lookup_without_canonical_key
  - id: province_lookup_unprefixed_literal
    message: 'prefixed province id literals required for lookup'
    match:
      kind: unprefixed_province_id_string_literal_argument
      method_names:
        - getProvince
        - tryGetProvince
        - resolveToFullProvinceId
      argument_index: 1
  - id: province_world_state_lookup_unprefixed_literal
    message: 'prefixed province id literals required for WorldState lookup'
    match:
      kind: unprefixed_province_id_string_literal_argument
      method_names:
        - tryGetProvince
        - getProvince
        - resolveToFullProvinceId
      argument_index: 0
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
      kind: scoped_package_import_contract
      scoped_relative_path_prefixes:
        - packages/colonizethis_debug_console/lib/
      package_name: colonizethis_logic
      allowed_imports:
        - package:colonizethis_logic/debug_console_api.dart
  - id: logic_lib_list_queue_remove_at_zero
    message: >-
      Do not use a List named queue as a FIFO frontier (queue.removeAt(0)).
    match:
      kind: simple_receiver_remove_at_zero
      receiver_identifier: queue
      relative_path_prefix: packages/colonizethis_logic/lib/src/
  - id: prohibited_linear_province_lookup
    message: >-
      Do not chain .provinces.where(...).firstOrNull under
      packages/colonizethis_logic/lib/src/.
    match:
      kind: linear_collection_where_first_or_null
      collection_names:
        - provinces
      relative_path_prefix: packages/colonizethis_logic/lib/src/
  - id: prohibited_linear_units_armies_fleets_lookup
    message: >-
      Do not chain .units/.armies/.fleets.where(...).firstOrNull under
      packages/colonizethis_logic/lib/src/.
    match:
      kind: linear_collection_where_first_or_null
      collection_names:
        - units
        - armies
        - fleets
      relative_path_prefix: packages/colonizethis_logic/lib/src/
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

    test(
      'flags unprefixed literal on WorldState.tryGetProvince receiver form',
      () {
        const src = r'''
void f(ws) {
  ws.tryGetProvince('p1');
}
''';
        final v = findDisallowedAstViolations(
          'packages/foo/lib/x.dart',
          src,
          rules,
        );
        expect(v, isNotEmpty);
        expect(
          v.map((e) => e.ruleId),
          contains('province_world_state_lookup_unprefixed_literal'),
        );
      },
    );

    test('flags unprefixed literal on cascaded ..tryGetProvince', () {
      const src = r'''
void f(ws) {
  ws..tryGetProvince('p1');
}
''';
      final v = findDisallowedAstViolations(
        'packages/foo/lib/x.dart',
        src,
        rules,
      );
      expect(v, isNotEmpty);
      expect(
        v.map((e) => e.ruleId),
        contains('province_world_state_lookup_unprefixed_literal'),
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

    test('sea-zone rule respects ignore on previous line', () {
      const src = r'''
import 'package:colonizethis_models/colonizethis_models.dart';

bool bad(String seaZoneId) {
  // ignore: disallowed_ast_sea_zone_local_id_extraction
  return ProvinceId.localIdFrom(seaZoneId) == 's1';
}
''';
      final v = findDisallowedAstViolations(
        'packages/foo/lib/any_file.dart',
        src,
        rules,
      );
      expect(
        v.where((e) => e.ruleId == 'sea_zone_local_id_extraction'),
        isEmpty,
      );
    });

    test('sea-zone rule respects ignore_for_file', () {
      const src = r'''
// ignore_for_file: disallowed_ast_sea_zone_local_id_extraction

import 'package:colonizethis_models/colonizethis_models.dart';

bool ok(String seaZoneId) {
  return ProvinceId.localIdFrom(seaZoneId) == 's1';
}
''';
      final v = findDisallowedAstViolations(
        'packages/foo/lib/any_file.dart',
        src,
        rules,
      );
      expect(
        v.where((e) => e.ruleId == 'sea_zone_local_id_extraction'),
        isEmpty,
      );
    });

    test('allows approved logic contract import in debug console scope', () {
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

  group('logic_lib_list_queue_remove_at_zero', () {
    test('flags queue.removeAt(0) under colonizethis_logic lib/src', () {
      const src = r'''
void f(List<String> queue) {
  final x = queue.removeAt(0);
}
''';
      final violations = findDisallowedAstViolations(
        'packages/colonizethis_logic/lib/src/x.dart',
        src,
        rules,
      );
      expect(
        violations.where((e) => e.ruleId == 'logic_lib_list_queue_remove_at_zero'),
        isNotEmpty,
      );
    });

    test('ignores queue.removeAt(0) outside lib/src tree', () {
      const src = r'''
void f(List<String> queue) {
  final x = queue.removeAt(0);
}
''';
      final violations = findDisallowedAstViolations(
        'packages/colonizethis_logic/lib/x.dart',
        src,
        rules,
      );
      expect(
        violations.where((e) => e.ruleId == 'logic_lib_list_queue_remove_at_zero'),
        isEmpty,
      );
    });

    test('respects same-line ignore for queue.removeAt(0)', () {
      const src = r'''
void f(List<String> queue) {
  final x = queue.removeAt(0); // ignore: disallowed_ast_logic_lib_list_queue_remove_at_zero
}
''';
      expect(
        findDisallowedAstViolations(
          'packages/colonizethis_logic/lib/src/x.dart',
          src,
          rules,
        ).where((e) => e.ruleId == 'logic_lib_list_queue_remove_at_zero'),
        isEmpty,
      );
    });
  });

  group('prohibited_linear_province_lookup', () {
    test('flags region.provinces.where(...).firstOrNull under lib/src', () {
      const src = r'''
class Province { final String id = ''; final String ownerId = ''; }
class Region { List<Province> get provinces => const []; }
Province? bad(Region region, String ownerId) {
  return region.provinces.where((p) => p.ownerId == ownerId).firstOrNull;
}
''';
      final violations = findDisallowedAstViolations(
        'packages/colonizethis_logic/lib/src/world/x.dart',
        src,
        rules,
      );
      expect(
        violations.where(
          (e) => e.ruleId == 'prohibited_linear_province_lookup',
        ),
        isNotEmpty,
      );
    });

    test(
      'flags deep receiver world.oldWorld.provinces.where(...).firstOrNull',
      () {
        const src = r'''
class Province { final String id = ''; }
class Region { List<Province> get provinces => const []; }
class World { Region get oldWorld => Region(); }
class Game { World get worldState => World(); }
Province? bad(Game game, String id) {
  return game.worldState.oldWorld.provinces
      .where((p) => p.id == id)
      .firstOrNull;
}
''';
        final violations = findDisallowedAstViolations(
          'packages/colonizethis_logic/lib/src/orders/x.dart',
          src,
          rules,
        );
        expect(
          violations.where(
            (e) => e.ruleId == 'prohibited_linear_province_lookup',
          ),
          isNotEmpty,
        );
      },
    );

    test('flags local variable provinces.where(...).firstOrNull', () {
      const src = r'''
class Province { final String id = ''; }
Province? bad(List<Province> provinces, String id) {
  return provinces.where((p) => p.id == id).firstOrNull;
}
''';
      final violations = findDisallowedAstViolations(
        'packages/colonizethis_logic/lib/src/x.dart',
        src,
        rules,
      );
      expect(
        violations.where(
          (e) => e.ruleId == 'prohibited_linear_province_lookup',
        ),
        isNotEmpty,
      );
    });

    test('allows tryGetProvince O(1) lookup helper instead of where chain', () {
      const src = r'''
class Province { final String id = ''; }
Province? tryGetProvince(world, String fullId) => null;
Province? ok(world, String id) {
  return tryGetProvince(world, id);
}
''';
      expect(
        findDisallowedAstViolations(
          'packages/colonizethis_logic/lib/src/x.dart',
          src,
          rules,
        ).where((e) => e.ruleId == 'prohibited_linear_province_lookup'),
        isEmpty,
      );
    });

    test('allows .provinces.where(...) without .firstOrNull (iterable use)',
        () {
      const src = r'''
class Province { final String id = ''; final String ownerId = ''; }
class Region { List<Province> get provinces => const []; }
int countOwned(Region region, String ownerId) {
  return region.provinces.where((p) => p.ownerId == ownerId).length;
}
''';
      expect(
        findDisallowedAstViolations(
          'packages/colonizethis_logic/lib/src/x.dart',
          src,
          rules,
        ).where((e) => e.ruleId == 'prohibited_linear_province_lookup'),
        isEmpty,
      );
    });

    test(
      'ignores .provinces.where(...).firstOrNull outside scoped path prefix',
      () {
        const src = r'''
class Province { final String id = ''; }
class Region { List<Province> get provinces => const []; }
Province? still(Region region, String id) {
  return region.provinces.where((p) => p.id == id).firstOrNull;
}
''';
        expect(
          findDisallowedAstViolations(
            'app/lib/widgets/x.dart',
            src,
            rules,
          ).where((e) => e.ruleId == 'prohibited_linear_province_lookup'),
          isEmpty,
        );
      },
    );

    test(
      'ignores .units.where(...).firstOrNull (collection name not configured)',
      () {
        const src = r'''
class Unit { final String id = ''; }
class Region { List<Unit> get units => const []; }
Unit? bad(Region region, String id) {
  return region.units.where((u) => u.id == id).firstOrNull;
}
''';
        expect(
          findDisallowedAstViolations(
            'packages/colonizethis_logic/lib/src/x.dart',
            src,
            rules,
          ).where((e) => e.ruleId == 'prohibited_linear_province_lookup'),
          isEmpty,
        );
      },
    );

    test('respects same-line ignore for prohibited_linear_province_lookup', () {
      const src = r'''
class Province { final String id = ''; }
class Region { List<Province> get provinces => const []; }
Province? f(Region region, String id) {
  return region.provinces.where((p) => p.id == id).firstOrNull; // ignore: disallowed_ast_prohibited_linear_province_lookup
}
''';
      expect(
        findDisallowedAstViolations(
          'packages/colonizethis_logic/lib/src/x.dart',
          src,
          rules,
        ).where((e) => e.ruleId == 'prohibited_linear_province_lookup'),
        isEmpty,
      );
    });

    test('respects ignore on previous line', () {
      const src = r'''
class Province { final String id = ''; }
class Region { List<Province> get provinces => const []; }
Province? f(Region region, String id) {
  // ignore: disallowed_ast_prohibited_linear_province_lookup
  return region.provinces.where((p) => p.id == id).firstOrNull;
}
''';
      expect(
        findDisallowedAstViolations(
          'packages/colonizethis_logic/lib/src/x.dart',
          src,
          rules,
        ).where((e) => e.ruleId == 'prohibited_linear_province_lookup'),
        isEmpty,
      );
    });

    test('respects ignore_for_file for prohibited_linear_province_lookup', () {
      const src = r'''
// ignore_for_file: disallowed_ast_prohibited_linear_province_lookup

class Province { final String id = ''; }
class Region { List<Province> get provinces => const []; }
Province? f(Region region, String id) {
  return region.provinces.where((p) => p.id == id).firstOrNull;
}
''';
      expect(
        findDisallowedAstViolations(
          'packages/colonizethis_logic/lib/src/x.dart',
          src,
          rules,
        ).where((e) => e.ruleId == 'prohibited_linear_province_lookup'),
        isEmpty,
      );
    });
  });

  group('prohibited_linear_units_armies_fleets_lookup', () {
    test('flags region.units.where(...).firstOrNull under lib/src', () {
      const src = r'''
class Unit { final String id = ''; }
class Region { List<Unit> get units => const []; }
Unit? bad(Region region, String id) {
  return region.units.where((u) => u.id == id).firstOrNull;
}
''';
      final violations = findDisallowedAstViolations(
        'packages/colonizethis_logic/lib/src/world/x.dart',
        src,
        rules,
      );
      expect(
        violations.where(
          (e) => e.ruleId == 'prohibited_linear_units_armies_fleets_lookup',
        ),
        isNotEmpty,
      );
    });

    test('flags worldState.armies.where(...).firstOrNull', () {
      const src = r'''
class Army { final String id = ''; }
class WorldState { List<Army> get armies => const []; }
Army? bad(WorldState ws, String id) {
  return ws.armies.where((a) => a.id == id).firstOrNull;
}
''';
      final violations = findDisallowedAstViolations(
        'packages/colonizethis_logic/lib/src/orders/x.dart',
        src,
        rules,
      );
      expect(
        violations.where(
          (e) => e.ruleId == 'prohibited_linear_units_armies_fleets_lookup',
        ),
        isNotEmpty,
      );
    });

    test('flags fleets.where(...).firstOrNull', () {
      const src = r'''
class Fleet { final String id = ''; }
class WorldState { List<Fleet> get fleets => const []; }
Fleet? bad(WorldState ws, String id) {
  return ws.fleets.where((f) => f.id == id).firstOrNull;
}
''';
      final violations = findDisallowedAstViolations(
        'packages/colonizethis_logic/lib/src/naval/x.dart',
        src,
        rules,
      );
      expect(
        violations.where(
          (e) => e.ruleId == 'prohibited_linear_units_armies_fleets_lookup',
        ),
        isNotEmpty,
      );
    });

    test('ignores .units.where(...).firstOrNull outside scoped path prefix',
        () {
      const src = r'''
class Unit { final String id = ''; }
class Region { List<Unit> get units => const []; }
Unit? still(Region region, String id) {
  return region.units.where((u) => u.id == id).firstOrNull;
}
''';
      expect(
        findDisallowedAstViolations(
          'app/lib/widgets/x.dart',
          src,
          rules,
        ).where(
          (e) => e.ruleId == 'prohibited_linear_units_armies_fleets_lookup',
        ),
        isEmpty,
      );
    });

    test('respects same-line ignore for prohibited_linear_units_armies_fleets_lookup',
        () {
      const src = r'''
class Unit { final String id = ''; }
class Region { List<Unit> get units => const []; }
Unit? f(Region region, String id) {
  return region.units.where((u) => u.id == id).firstOrNull; // ignore: disallowed_ast_prohibited_linear_units_armies_fleets_lookup
}
''';
      expect(
        findDisallowedAstViolations(
          'packages/colonizethis_logic/lib/src/x.dart',
          src,
          rules,
        ).where(
          (e) => e.ruleId == 'prohibited_linear_units_armies_fleets_lookup',
        ),
        isEmpty,
      );
    });
  });
}
