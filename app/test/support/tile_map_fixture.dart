// Loader for the committed seed-42 per-region tile-map fixture (Refs #3656).
//
// A few widget/behaviour suites need the generated `tileMapByRegion`
// (`Map<String, TileMapResult>`) that `runInitGame` produces on
// `InitGameResult` — e.g. to discover valid work-order target tiles or to drive
// the production-breakdown extraction view. That data is not part of `Game`
// serialization, so the committed `Game`/map-view fixtures alone cannot
// reconstruct it. These suites load this committed fixture instead, paying only
// a cheap JSON decode per test isolate rather than the ~7-11s procedural map
// generation.
//
// `TileMapResult.toJson()` / `fromJson()` are the production map-data save path
// (`SPEC/program/map-data.md`), so the fixture reconstructs exactly what the
// generator emits for the structural grid/terrain. The fixture is kept honest
// by `seed42_tile_map_fixture_roundtrip_test.dart`, which fails if the
// serializer is no longer lossless or if a fresh
// `runInitGame(GameSetupConfig.defaultConfig)` no longer matches the committed
// fixture's shape (regenerate via that test's `REGEN_TILE_MAP_FIXTURE` flag).

import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart' show TileMapResult;

/// Fixture schema version. Bump when the serialized envelope changes shape.
const int kTileMapFixtureVersion = 1;

/// Repo-relative fixture path (canonical home of the committed JSON).
const String kSeed42TileMapFixtureRepoPath =
    'app/test/support/fixtures/seed42_tile_map.json';

/// Candidate paths so the fixture resolves whether `flutter test` runs from the
/// `app/` package directory or the repository root.
const List<String> _kFixtureCandidatePaths = <String>[
  'test/support/fixtures/seed42_tile_map.json',
  kSeed42TileMapFixtureRepoPath,
];

/// Resolves the committed fixture file across supported working directories.
File seed42TileMapFixtureFile() {
  for (final candidate in _kFixtureCandidatePaths) {
    final file = File(candidate);
    if (file.existsSync()) return file;
  }
  // Fall back to the canonical repo-relative path so the failure message points
  // at the expected location.
  return File(_kFixtureCandidatePaths.first);
}

/// Raw committed fixture JSON string.
String readSeed42TileMapFixtureJson() =>
    seed42TileMapFixtureFile().readAsStringSync();

/// Encodes [tileMapByRegion] into the committed fixture envelope shape.
Map<String, dynamic> seed42TileMapToJson(
  Map<String, TileMapResult> tileMapByRegion,
) {
  final sortedKeys = tileMapByRegion.keys.toList()..sort();
  return <String, dynamic>{
    'version': kTileMapFixtureVersion,
    'tileMapByRegion': <String, dynamic>{
      for (final key in sortedKeys) key: tileMapByRegion[key]!.toJson(),
    },
  };
}

/// Decodes the committed seed-42 fixture into per-region [TileMapResult]s via
/// the production `TileMapResult.fromJson` save path.
Map<String, TileMapResult> loadSeed42TileMapByRegion() {
  final json =
      jsonDecode(readSeed42TileMapFixtureJson()) as Map<String, dynamic>;
  final byRegion = json['tileMapByRegion'] as Map<String, dynamic>;
  return <String, TileMapResult>{
    for (final entry in byRegion.entries)
      entry.key: TileMapResult.fromJson(entry.value as Map<String, dynamic>),
  };
}
