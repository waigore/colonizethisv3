// Loader for the committed seed-42 map-view fixture (Refs #3656).
//
// Map-dependent widget suites (`ct_region_map_*`, region minimap, etc.) need the
// generated `InitGameMapViewData` but never the ~7-11s procedural generation
// itself. They load this committed fixture instead, paying only a cheap JSON
// decode per test isolate. The fixture is kept in sync with the generator by
// `map_view_fixture_roundtrip_test.dart`, which fails if a fresh
// `runInitGame(GameSetupConfig.defaultConfig)` no longer serializes to the
// committed bytes (regenerate via that test's `REGEN_MAP_VIEW_FIXTURE` flag).

import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_map/colonizethis_map.dart';

import 'map_view_serialization.dart';

/// Repo-relative fixture path (canonical home of the committed JSON).
const String kSeed42MapViewFixtureRepoPath =
    'app/test/support/fixtures/seed42_map_view.json';

/// Candidate paths so the fixture resolves whether `flutter test` runs from the
/// `app/` package directory or the repository root.
const List<String> _kFixtureCandidatePaths = <String>[
  'test/support/fixtures/seed42_map_view.json',
  kSeed42MapViewFixtureRepoPath,
];

/// Resolves the committed fixture file across supported working directories.
File seed42MapViewFixtureFile() {
  for (final candidate in _kFixtureCandidatePaths) {
    final file = File(candidate);
    if (file.existsSync()) return file;
  }
  // Fall back to the canonical repo-relative path so the failure message points
  // at the expected location.
  return File(_kFixtureCandidatePaths.first);
}

/// Raw committed fixture JSON string.
String readSeed42MapViewFixtureJson() =>
    seed42MapViewFixtureFile().readAsStringSync();

/// Decodes the committed seed-42 fixture into [InitGameMapViewData].
InitGameMapViewData loadSeed42MapViewData() {
  final json = jsonDecode(readSeed42MapViewFixtureJson()) as Map<String, dynamic>;
  return initGameMapViewDataFromJson(json);
}
