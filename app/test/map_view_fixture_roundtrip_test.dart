// Staleness + round-trip guard for the committed seed-42 map-view fixture
// (Refs #3656).
//
// The map-dependent widget suites load `app/test/support/fixtures/
// seed42_map_view.json` instead of running the ~7-11s procedural map generator.
// This test keeps that fixture honest with two checks:
//
//   1. Lossless serializer — decode the committed fixture and re-encode it; the
//      bytes must be identical, so the serializer never drops or reshapes data.
//
//   2. Schema parity with the generator — generate a fresh
//      `runInitGame(GameSetupConfig.defaultConfig)` map-view (the exact call
//      `getDebugInitGameResult()` wraps) and assert it has the *same shape* as
//      the committed fixture: schema version, top-level keys, per-region
//      dimensions / cell counts / marker+colour-table cardinalities, and the
//      union of per-cell JSON keys. This catches fixture staleness (a new field,
//      a dimension change, a version bump) and keeps the generator path covered.
//
// Exact value-equality is intentionally NOT asserted: `runInitGame` map-view
// output is deterministic within a process but varies *across* processes in
// per-cell value placement (e.g. a tile's `resourceId`), because resource
// assignment iterates identity-hashed collections. Cell geometry, dimensions,
// counts, and schema are cross-process stable, so the committed fixture is a
// valid representative snapshot and shape parity is the meaningful guard.
//
// Regenerate the snapshot after an intentional generator/serialization change by
// running this test once with `REGEN_MAP_VIEW_FIXTURE=1` in the environment.

import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart' show GameSetupConfig;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'support/map_view_fixture.dart';
import 'support/map_view_serialization.dart';

Set<String> _cellKeyUnion(Map<String, dynamic> regionJson) {
  final cells = (regionJson['cells'] as List).cast<Map<String, dynamic>>();
  final keys = <String>{};
  for (final cell in cells) {
    keys.addAll(cell.keys);
  }
  return keys;
}

/// A cross-process-stable shape descriptor for one serialized region: scalar
/// dimensions, container cardinalities, and the union of per-cell keys. Excludes
/// value-level fields that the generator places non-deterministically across
/// processes (e.g. individual `resourceId`s).
Map<String, Object> _regionShape(Map<String, dynamic> regionJson) {
  return <String, Object>{
    'regionId': regionJson['regionId'] as String,
    'width': regionJson['width'] as int,
    'height': regionJson['height'] as int,
    'cellSize': regionJson['cellSize'] as int,
    'cellCount': (regionJson['cells'] as List).length,
    'capitalMarkers': (regionJson['capitalMarkers'] as List).length,
    'portMarkers': (regionJson['portMarkers'] as List).length,
    'townMarkers': (regionJson['townMarkers'] as List).length,
    'warpMarkers': (regionJson['warpMarkers'] as List).length,
    'factionColors': (regionJson['factionColors'] as Map).length,
    'terrainColors': (regionJson['terrainColors'] as Map).length,
    'greatPowerFactionIds':
        (regionJson['greatPowerFactionIds'] as List).length,
    'cellKeyUnion': (_cellKeyUnion(regionJson).toList()..sort()).join(','),
  };
}

Map<String, Object> _shape(Map<String, dynamic> json) {
  return <String, Object>{
    'version': json['version'] as int,
    'topLevelKeys': (json.keys.toList()..sort()).join(','),
    'oldWorld': _regionShape(json['oldWorld'] as Map<String, dynamic>),
    'newWorld': _regionShape(json['newWorld'] as Map<String, dynamic>),
    'topologyKeys':
        ((json['combinedTopology'] as Map).keys.toList()..sort()).join(','),
  };
}

void main() {
  suppressLogsForTests();

  test('seed-42 map-view fixture stays shape-compatible with runInitGame', () {
    final fresh = runInitGame(
      config: GameSetupConfig.defaultConfig,
      options: const InitGameOptions(cellSize: 24, renderPng: false),
    ).mapViewData;
    final freshJson = initGameMapViewDataToJson(fresh);

    if (Platform.environment['REGEN_MAP_VIEW_FIXTURE'] == '1') {
      final file = seed42MapViewFixtureFile();
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('${jsonEncode(freshJson)}\n');
    }

    final committedRaw = readSeed42MapViewFixtureJson().trim();
    final committedJson = jsonDecode(committedRaw) as Map<String, dynamic>;

    // (1) Lossless serializer: decode the committed fixture and re-encode; the
    // bytes must match exactly (no field dropped or reshaped).
    final reEncoded = jsonEncode(
      initGameMapViewDataToJson(loadSeed42MapViewData()),
    );
    expect(
      reEncoded,
      committedRaw,
      reason: 'Serializer is not lossless for the committed fixture.',
    );

    // (2) Schema parity with a fresh generation (value-independent shape).
    expect(
      _shape(committedJson),
      _shape(freshJson),
      reason:
          'Committed seed-42 map-view fixture is shape-stale vs runInitGame. '
          'Regenerate by running this test with REGEN_MAP_VIEW_FIXTURE=1.',
    );
    expect(committedJson['version'], kMapViewFixtureVersion);
  });
}
