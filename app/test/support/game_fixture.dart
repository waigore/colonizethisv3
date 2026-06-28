// Loader for the committed seed-42 game fixture (Refs #3656).
//
// Map-chrome suites that mount `GameMapArea` need a real `Game` (e.g. for
// `worldState.tileKeysByRegionAndProvince`) but never the ~7-11s procedural
// generation itself. They load this committed fixture instead, paying only a
// cheap JSON decode per test isolate. The `Game` payload uses the production
// save path (`Game.toJson()` / `Game.fromJson()`), so it reconstructs exactly
// what the running app persists and restores.
//
// The fixture is kept honest by `seed42_game_fixture_roundtrip_test.dart`,
// which fails if the serializer is no longer lossless or if a fresh
// `runInitGame(GameSetupConfig.defaultConfig)` game no longer matches the
// committed fixture's shape (regenerate via that test's
// `REGEN_SEED42_GAME_FIXTURE` flag).

import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_models/colonizethis_models.dart';

/// Repo-relative fixture path (canonical home of the committed JSON).
const String kSeed42GameFixtureRepoPath =
    'app/test/support/fixtures/seed42_game.json';

/// Candidate paths so the fixture resolves whether `flutter test` runs from the
/// `app/` package directory or the repository root.
const List<String> _kFixtureCandidatePaths = <String>[
  'test/support/fixtures/seed42_game.json',
  kSeed42GameFixtureRepoPath,
];

/// Resolves the committed fixture file across supported working directories.
File seed42GameFixtureFile() {
  for (final candidate in _kFixtureCandidatePaths) {
    final file = File(candidate);
    if (file.existsSync()) return file;
  }
  // Fall back to the canonical repo-relative path so the failure message points
  // at the expected location.
  return File(_kFixtureCandidatePaths.first);
}

/// Raw committed fixture JSON string.
String readSeed42GameFixtureJson() =>
    seed42GameFixtureFile().readAsStringSync();

/// Decodes the committed seed-42 fixture into a [Game] via the production
/// `Game.fromJson` save path.
Game loadSeed42Game() {
  final json = jsonDecode(readSeed42GameFixtureJson()) as Map<String, dynamic>;
  return Game.fromJson(json);
}
