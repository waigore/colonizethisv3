import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3459, AC5).
///
/// Ensures tile-map generation service families implement the shared
/// [MapGenStage] contract in `map_gen_stage.dart` so pass orchestration
/// shares a uniform params + grid-in/grid-out protocol across land seeds,
/// lakes/provinces, join-sea, and terrain/resource services.
const _mapLibRoot = 'packages/colonizethis_map/lib';

const _stageContractFile =
    'packages/colonizethis_map/lib/src/map_gen_stage.dart';

const _requiredStageContractPattern = 'abstract interface class MapGenStage';

/// Each generator service family must declare `implements MapGenStage`.
const _requiredServiceBindings = <String, String>{
  'packages/colonizethis_map/lib/src/tile_map_generator_land_seeds.dart':
      'class TileMapGenLandSeeds',
  'packages/colonizethis_map/lib/src/tile_map_generator_lakes_provinces.dart':
      'class _TileMapGenLakesProvinces',
  'packages/colonizethis_map/lib/src/tile_map_generator_join_sea.dart':
      'class _TileMapGenJoinSea',
  'packages/colonizethis_map/lib/src/tile_map_generator_terrain_assign.dart':
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
  if (!source.contains(classDecl)) {
    violations.add(
      MapGenStageProtocolViolation(
        relativePath,
        'missing expected service declaration `$classDecl`',
      ),
    );
    return violations;
  }
  if (!source.contains('implements MapGenStage')) {
    violations.add(
      MapGenStageProtocolViolation(
        relativePath,
        '$classDecl must implement MapGenStage (Refs #3459)',
      ),
    );
  }
  return violations;
}

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

  for (final entry in _requiredServiceBindings.entries) {
    final file = File(p.join(root, entry.key));
    if (!file.existsSync()) {
      violations.add(
        MapGenStageProtocolViolation(entry.key, 'missing service file'),
      );
      continue;
    }
    violations.addAll(
      findMapGenStageProtocolViolations(
        relativePath: entry.key,
        source: file.readAsStringSync(),
      ),
    );
  }

  if (violations.isEmpty) {
    logI('colonizethis_map MapGenStage protocol check passed.');
    return 0;
  }

  logE(
    'ERROR: Tile-map generation services must implement MapGenStage '
    '(packages/colonizethis_map/lib/src/map_gen_stage.dart). '
    'Refs #3459.',
  );
  for (final v in violations) {
    logE('  $v');
  }
  return 1;
}
