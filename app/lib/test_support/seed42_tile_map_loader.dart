// Loader for the committed seed-42 per-region tile-map fixture (Refs #3656, #3847).
//
// Widgetbook and map-dependent suites need `InitGameResult.tileMapByRegion`
// without paying the ~7-11s procedural map generator.

import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart' show TileMapResult;

import 'seed42_fixture_paths.dart';

/// Fixture schema version. Bump when the serialized envelope changes shape.
const int kTileMapFixtureVersion = 1;

/// Resolves the committed fixture file across supported working directories.
File seed42TileMapFixtureFile() =>
    _resolveFixtureFile(kSeed42TileMapFixtureCandidatePaths);

File _resolveFixtureFile(List<String> candidatePaths) {
  for (final candidate in candidatePaths) {
    final file = File(candidate);
    if (file.existsSync()) return file;
  }
  return File(candidatePaths.first);
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
