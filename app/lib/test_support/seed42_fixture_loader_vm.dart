// VM/desktop seed-42 fixture loaders (Refs #3656, #3847).
//
// Map-chrome and overlay demo suites load committed JSON instead of the ~7-11s
// procedural `getDebugInitGameResult()` generator. Paths resolve from either
// the `app/` package directory or the repository root.

import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'map_view_serialization.dart';
import 'seed42_fixture_paths.dart';

/// Resolves the committed seed-42 [Game] fixture file.
File seed42GameFixtureFile() => _resolveFixtureFile(kSeed42GameFixtureCandidatePaths);

/// Resolves the committed seed-42 map-view fixture file.
File seed42MapViewFixtureFile() =>
    _resolveFixtureFile(kSeed42MapViewFixtureCandidatePaths);

File _resolveFixtureFile(List<String> candidatePaths) {
  for (final candidate in candidatePaths) {
    final file = File(candidate);
    if (file.existsSync()) return file;
  }
  return File(candidatePaths.first);
}

/// Raw committed seed-42 [Game] fixture JSON string.
String readSeed42GameFixtureJson() =>
    seed42GameFixtureFile().readAsStringSync();

/// Raw committed seed-42 map-view fixture JSON string.
String readSeed42MapViewFixtureJson() =>
    seed42MapViewFixtureFile().readAsStringSync();

/// Decodes the committed seed-42 fixture into a [Game] via the production
/// `Game.fromJson` save path.
Game loadSeed42Game() {
  final json =
      jsonDecode(readSeed42GameFixtureJson()) as Map<String, dynamic>;
  return Game.fromJson(json);
}

/// Decodes the committed seed-42 fixture into [InitGameMapViewData].
InitGameMapViewData loadSeed42MapViewData() {
  final json =
      jsonDecode(readSeed42MapViewFixtureJson()) as Map<String, dynamic>;
  return initGameMapViewDataFromJson(json);
}
