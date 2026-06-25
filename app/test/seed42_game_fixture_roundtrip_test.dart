// Staleness + round-trip guard for the committed seed-42 game fixture
// (Refs #3656).
//
// Map-chrome suites that mount `GameMapArea` load
// `app/test/support/fixtures/seed42_game.json` instead of running the ~7-11s
// procedural map generator. This test keeps that fixture honest with two checks:
//
//   1. Lossless serializer — decode the committed fixture via `Game.fromJson`
//      and re-encode via `Game.toJson`; the bytes must be identical, so the
//      save round-trip never drops or reshapes data.
//
//   2. Schema parity with the generator — generate a fresh
//      `runInitGame(GameSetupConfig.defaultConfig)` game (the exact call
//      `getDebugInitGameResult()` wraps) and assert it has the *same shape* as
//      the committed fixture: player/unit/fleet/army cardinalities and the
//      per-region province structure of `tileKeysByRegionAndProvince`.
//
// Exact value-equality is intentionally NOT asserted: like the map-view fixture
// (`map_view_fixture_roundtrip_test.dart`), `runInitGame` output is
// deterministic within a process but varies *across* processes in per-tile
// value placement (e.g. a tile's `resourceId`), because resource assignment
// iterates identity-hashed collections. Cardinalities and the region/province
// structure are cross-process stable, so the committed fixture is a valid
// representative snapshot and shape parity is the meaningful guard.
//
// Regenerate the snapshot after an intentional generator/serialization change by
// running this test once with `REGEN_SEED42_GAME_FIXTURE=1` in the environment.

import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart' show GameSetupConfig;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'support/game_fixture.dart';

/// A cross-process-stable shape descriptor for a [Game]: container
/// cardinalities and the region/province structure of
/// `tileKeysByRegionAndProvince`. Excludes value-level fields that the generator
/// places non-deterministically across processes (e.g. individual `resourceId`s
/// or tile coordinates).
Map<String, Object> _gameShape(Game game) {
  final ws = game.worldState;
  final tileKeys = ws.tileKeysByRegionAndProvince;
  final provinceCountByRegion = <String, int>{
    for (final entry in tileKeys.entries) entry.key: entry.value.length,
  };
  return <String, Object>{
    'players': game.players.length,
    'humanPlayers': game.players.where((p) => p.isHuman).length,
    'oldWorldUnits': ws.oldWorld.units.length,
    'newWorldUnits': ws.newWorld.units.length,
    'fleets': ws.fleets.length,
    'armies': ws.armies.length,
    'tileKeyRegions': (tileKeys.keys.toList()..sort()).join(','),
    'provinceCountByRegion':
        (provinceCountByRegion.entries.map((e) => '${e.key}=${e.value}').toList()
              ..sort())
            .join(','),
  };
}

void main() {
  suppressLogsForTests();

  test('seed-42 game fixture stays shape-compatible with runInitGame', () {
    final fresh = runInitGame(
      config: GameSetupConfig.defaultConfig,
      options: const InitGameOptions(cellSize: 24, renderPng: false),
    ).game;

    if (Platform.environment['REGEN_SEED42_GAME_FIXTURE'] == '1') {
      final file = seed42GameFixtureFile();
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('${jsonEncode(fresh.toJson())}\n');
    }

    final committedRaw = readSeed42GameFixtureJson().trim();

    // (1) Lossless save round-trip: decode the committed fixture and re-encode;
    // the bytes must match exactly (no field dropped or reshaped).
    final reEncoded = jsonEncode(loadSeed42Game().toJson());
    expect(
      reEncoded,
      committedRaw,
      reason: 'Game.toJson/fromJson is not lossless for the committed fixture.',
    );

    // (2) Schema parity with a fresh generation (value-independent shape).
    expect(
      _gameShape(loadSeed42Game()),
      _gameShape(fresh),
      reason:
          'Committed seed-42 game fixture is shape-stale vs runInitGame. '
          'Regenerate by running this test with REGEN_SEED42_GAME_FIXTURE=1.',
    );
  });
}
