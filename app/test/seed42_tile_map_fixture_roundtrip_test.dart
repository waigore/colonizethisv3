// Staleness + round-trip guard for the committed seed-42 tile-map fixture
// (Refs #3656).
//
// Behaviour/widget suites that need the generated `tileMapByRegion` load
// `app/test/support/fixtures/seed42_tile_map.json` instead of running the
// ~7-11s procedural map generator. This test keeps that fixture honest with two
// checks:
//
//   1. Lossless serializer — decode the committed fixture and re-encode it; the
//      bytes must be identical, so `TileMapResult.toJson()`/`fromJson()` never
//      drop or reshape data for the committed grids.
//
//   2. Schema parity with the generator — generate a fresh
//      `runInitGame(GameSetupConfig.defaultConfig)` `tileMapByRegion` (the exact
//      call `getDebugInitGameResult()` wraps) and assert it has the *same shape*
//      as the committed fixture: schema version, region ids, and per-region
//      width / height / grid dimensions / presence of terrain & resource grids.
//
// Exact per-cell value-equality is intentionally NOT asserted: `runInitGame`
// tile output is deterministic within a process but varies *across* processes in
// per-cell value placement (e.g. a cell's resource), because resource
// assignment iterates identity-hashed collections (same caveat as
// `map_view_fixture_roundtrip_test.dart`). Region grids, dimensions, and grid
// shape are cross-process stable, so the committed fixture is a valid
// representative snapshot and shape parity is the meaningful guard.
//
// Regenerate the snapshot after an intentional generator/serialization change by
// running this test once with `REGEN_TILE_MAP_FIXTURE=1` in the environment.

import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart'
    show GameSetupConfig, TileMapResult;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'support/tile_map_fixture.dart';

Map<String, Object> _regionShape(Map<String, dynamic> regionJson) {
  final grid = regionJson['grid'] as List<dynamic>;
  return <String, Object>{
    'width': regionJson['width'] as int,
    'height': regionJson['height'] as int,
    'gridRows': grid.length,
    'gridCols': grid.isEmpty ? 0 : (grid.first as List<dynamic>).length,
    'hasTerrainGrid': regionJson.containsKey('terrainGrid'),
    'hasResourceGrid': regionJson.containsKey('resourceGrid'),
  };
}

Map<String, Object> _shape(Map<String, dynamic> json) {
  final byRegion = json['tileMapByRegion'] as Map<String, dynamic>;
  final regionIds = byRegion.keys.toList()..sort();
  return <String, Object>{
    'version': json['version'] as int,
    'topLevelKeys': (json.keys.toList()..sort()).join(','),
    'regionIds': regionIds.join(','),
    for (final id in regionIds)
      'region:$id': _regionShape(byRegion[id] as Map<String, dynamic>),
  };
}

void main() {
  suppressLogsForTests();

  test('seed-42 tile-map fixture stays shape-compatible with runInitGame', () {
    final Map<String, TileMapResult> fresh = runInitGame(
      config: GameSetupConfig.defaultConfig,
      options: const InitGameOptions(cellSize: 24, renderPng: false),
    ).tileMapByRegion;
    final freshJson = seed42TileMapToJson(fresh);

    if (Platform.environment['REGEN_TILE_MAP_FIXTURE'] == '1') {
      final file = seed42TileMapFixtureFile();
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('${jsonEncode(freshJson)}\n');
    }

    final committedRaw = readSeed42TileMapFixtureJson().trim();
    final committedJson = jsonDecode(committedRaw) as Map<String, dynamic>;

    // (1) Lossless serializer: decode the committed fixture and re-encode; the
    // bytes must match exactly (no field dropped or reshaped).
    final reEncoded = jsonEncode(
      seed42TileMapToJson(loadSeed42TileMapByRegion()),
    );
    expect(
      reEncoded,
      committedRaw,
      reason: 'Serializer is not lossless for the committed tile-map fixture.',
    );

    // (2) Schema parity with a fresh generation (value-independent shape).
    expect(
      _shape(committedJson),
      _shape(freshJson),
      reason:
          'Committed seed-42 tile-map fixture is shape-stale vs runInitGame. '
          'Regenerate by running this test with REGEN_TILE_MAP_FIXTURE=1.',
    );
    expect(committedJson['version'], kTileMapFixtureVersion);
  });
}
