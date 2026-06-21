import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3459, AC5).
///
/// Ensures tile-map generation service families implement the shared
/// [MapGenStage] contract in `map_gen_stage.dart` so pass orchestration
/// shares a uniform params + grid-in/grid-out protocol across land seeds,
/// lakes/provinces, join-sea, and terrain/resource services.
///
/// In addition (Refs #3574, slice 4) it requires the contract to declare the
/// uniform [MapGenPass] pass entry point and at least
/// [_requiredMapGenPassFamilyMinimum] generator families to adopt it. After the
/// join-sea split (Refs #3588) the former exempt `_TileMapGenJoinSea` family is
/// replaced by three standalone [MapGenPass] services ([ContinentJoinPass],
/// [TerrainJitterPass], [SeaZoneSubdividePass]); all bound families now adopt
/// the uniform pass entry point.
const _stageContractFile =
    'packages/colonizethis_map/lib/src/gen/map_gen_stage.dart';

const _requiredStageContractPattern = 'abstract interface class MapGenStage';

const _requiredPassContractPattern = 'abstract interface class MapGenPass';

/// Marker showing a family implements either the base stage or the uniform pass.
const _implementsStage = 'implements MapGenStage';
const _implementsPass = 'implements MapGenPass';

/// At least this many generator families must adopt the uniform [MapGenPass].
const _requiredMapGenPassFamilyMinimum = 3;

/// Each generator service family must declare `implements MapGenStage`.
const _requiredServiceBindings = <String, String>{
  'packages/colonizethis_map/lib/src/gen/tile_map_generator_land_seeds.dart':
      'class TileMapGenLandSeeds',
  'packages/colonizethis_map/lib/src/gen/tile_map_generator_lakes_provinces.dart':
      'class _TileMapGenLakesProvinces',
  'packages/colonizethis_map/lib/src/gen/tile_map_gen_continent_join_pass.dart':
      'class ContinentJoinPass',
  'packages/colonizethis_map/lib/src/gen/tile_map_gen_terrain_jitter_pass.dart':
      'class TerrainJitterPass',
  'packages/colonizethis_map/lib/src/gen/tile_map_gen_sea_zone_subdivide_pass.dart':
      'class SeaZoneSubdividePass',
  'packages/colonizethis_map/lib/src/gen/tile_map_generator_terrain_assign.dart':
      'class _TileMapGenTerrainResource',
};

class MapGenStageProtocolViolation {
  MapGenStageProtocolViolation(this.relativePath, this.message);

  final String relativePath;
  final String message;

  @override
  String toString() => '$relativePath: $message';
}

/// Finds violations of the map generation stage protocol in [source] at
/// [relativePath].
List<MapGenStageProtocolViolation> findMapGenStageProtocolViolations({
  required String relativePath,
  required String source,
}) {
  final violations = <MapGenStageProtocolViolation>[];
  final classDecl = _requiredServiceBindings[relativePath];
  if (classDecl == null) {
    return violations;
  }
  // Collapse runs of whitespace so a class declaration that the formatter wrapped
  // across lines (e.g. `class Foo\n    implements\n        MapGenPass<...>`) still
  // matches the single-line markers below.
  final normalized = _collapseWhitespace(source);
  if (!normalized.contains(classDecl)) {
    violations.add(
      MapGenStageProtocolViolation(
        relativePath,
        'missing expected service declaration `$classDecl`',
      ),
    );
    return violations;
  }
  if (!normalized.contains(_implementsStage) &&
      !normalized.contains(_implementsPass)) {
    violations.add(
      MapGenStageProtocolViolation(
        relativePath,
        '$classDecl must implement MapGenStage (Refs #3459)',
      ),
    );
  }
  return violations;
}

/// Collapses every run of whitespace (including newlines) to a single space so
/// multiline declarations match the single-line substring markers.
String _collapseWhitespace(String source) =>
    source.replaceAll(RegExp(r'\s+'), ' ');

/// True when [source] adopts the uniform [MapGenPass] entry point.
bool sourceAdoptsMapGenPass(String source) =>
    _collapseWhitespace(source).contains(_implementsPass);

void main() {
  exit(runCheckMapGenStageProtocol(Directory.current.path));
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckMapGenStageProtocol(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final violations = <MapGenStageProtocolViolation>[];

  final contractFile = File(p.join(root, _stageContractFile));
  if (!contractFile.existsSync()) {
    logE('check_map_gen_stage_protocol: missing $_stageContractFile');
    return 1;
  }
  final contractSource = contractFile.readAsStringSync();
  if (!contractSource.contains(_requiredStageContractPattern)) {
    violations.add(
      MapGenStageProtocolViolation(
        _stageContractFile,
        'missing `$_requiredStageContractPattern` contract declaration',
      ),
    );
  }
  if (!contractSource.contains(_requiredPassContractPattern)) {
    violations.add(
      MapGenStageProtocolViolation(
        _stageContractFile,
        'missing `$_requiredPassContractPattern` uniform pass entry '
        'declaration (Refs #3574)',
      ),
    );
  }

  var mapGenPassFamilies = 0;
  for (final entry in _requiredServiceBindings.entries) {
    final file = File(p.join(root, entry.key));
    if (!file.existsSync()) {
      violations.add(
        MapGenStageProtocolViolation(entry.key, 'missing service file'),
      );
      continue;
    }
    final fileSource = file.readAsStringSync();
    violations.addAll(
      findMapGenStageProtocolViolations(
        relativePath: entry.key,
        source: fileSource,
      ),
    );
    if (sourceAdoptsMapGenPass(fileSource)) {
      mapGenPassFamilies++;
    }
  }

  if (mapGenPassFamilies < _requiredMapGenPassFamilyMinimum) {
    violations.add(
      MapGenStageProtocolViolation(
        _stageContractFile,
        'at least $_requiredMapGenPassFamilyMinimum generator families must '
        'adopt the uniform MapGenPass entry point '
        '(found $mapGenPassFamilies) (Refs #3574)',
      ),
    );
  }

  if (violations.isEmpty) {
    logI('colonizethis_map MapGenStage protocol check passed.');
    return 0;
  }

  logE(
    'ERROR: Tile-map generation services must implement MapGenStage '
    '(packages/colonizethis_map/lib/src/gen/map_gen_stage.dart). '
    'Refs #3459.',
  );
  for (final v in violations) {
    logE('  $v');
  }
  return 1;
}
