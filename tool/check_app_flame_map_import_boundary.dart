// Enforces one-way import graph among flame map submodules (Refs #3878 Phase 3).
// SPEC: SPEC/program/repo-and-packages.md
import 'dart:io';

import 'package:path/path.dart' as p;

const _flameRoot = 'app/lib/features/game/flame';
const _mapAreaDir = '$_flameRoot/map_area';
const _regionMapDir = '$_flameRoot/region_map';
const _mapStateDir = '$_flameRoot/map_state';
const _mapStateNeedle = '/map_state/';
const _mapAreaNeedle = '/map_area/';
const _allowedMapAreaImportSuffixes = <String>[
  'map_area/map_area.dart',
];

const _legacyShimFileNames = <String>[
  'game_map_area.dart',
  'game_map_area_background.dart',
  'game_map_area_civilian_draft_projection.dart',
  'game_map_area_fleet_draft_projection.dart',
  'game_map_area_province_action_states.dart',
  'game_map_area_state_logic.dart',
  'region_map_component.dart',
  'region_map_boundary_visibility.dart',
  'region_map_province_overlay_geometry.dart',
  'region_map_viewport_snapshot.dart',
];

const _legacyImportNeedles = <String>[
  'features/game/flame/game_map_area.dart',
  'features/game/flame/game_map_area_',
  'features/game/flame/region_map_component.dart',
  'features/game/flame/region_map_boundary_visibility.dart',
  'features/game/flame/region_map_province_overlay_geometry.dart',
  'features/game/flame/region_map_viewport_snapshot.dart',
];

const _legacyImportScanRoots = <String>[
  'app/lib',
  'app/test',
  'widgetbook_host/lib',
];

int runCheckAppFlameMapImportBoundary(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final violations = <String>[];

  for (final relativeDir in [_mapAreaDir, _regionMapDir]) {
    final dir = Directory(p.join(repoRoot, relativeDir));
    if (!dir.existsSync()) {
      violations.add('$relativeDir: expected flame map submodule directory');
      continue;
    }
    for (final file in _dartFilesUnder(dir)) {
      final relFile = p.relative(file.path, from: repoRoot);
      _scanForForbiddenImport(
        file: file,
        relFile: relFile,
        forbiddenNeedle: _mapStateNeedle,
        reason: 'must not import flame/map_state',
        violations: violations,
      );
    }
  }

  final mapStateDir = Directory(p.join(repoRoot, _mapStateDir));
  if (mapStateDir.existsSync()) {
    for (final file in _dartFilesUnder(mapStateDir)) {
      final relFile = p.relative(file.path, from: repoRoot);
      _scanMapStateMapAreaImports(
        file: file,
        relFile: relFile,
        violations: violations,
      );
    }
  }

  final flameRootDir = Directory(p.join(repoRoot, _flameRoot));
  if (flameRootDir.existsSync()) {
    for (final name in _legacyShimFileNames) {
      final shim = File(p.join(flameRootDir.path, name));
      if (shim.existsSync()) {
        violations.add(
          '${p.relative(shim.path, from: repoRoot)}: legacy flame re-export shim must be removed (use map_area/, map_state/, or region_map/ barrels)',
        );
      }
    }
  }

  for (final scanRoot in _legacyImportScanRoots) {
    final dir = Directory(p.join(repoRoot, scanRoot));
    if (!dir.existsSync()) continue;
    for (final file in _dartFilesUnder(dir)) {
      final relFile = p.relative(file.path, from: repoRoot);
      _scanForLegacyShimImports(
        file: file,
        relFile: relFile,
        violations: violations,
      );
    }
  }

  if (violations.isEmpty) {
    logI('check_app_flame_map_import_boundary: no violations found.');
    return 0;
  }

  logE(
    'check_app_flame_map_import_boundary: found ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

Iterable<File> _dartFilesUnder(Directory dir) sync* {
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      yield entity;
    }
  }
}

void _scanForForbiddenImport({
  required File file,
  required String relFile,
  required String forbiddenNeedle,
  required String reason,
  required List<String> violations,
}) {
  final lines = file.readAsLinesSync();
  for (var i = 0; i < lines.length; i++) {
    final trimmed = lines[i].trim();
    if (trimmed.startsWith('//')) continue;
    if (!trimmed.startsWith('import ') && !trimmed.startsWith('export ')) {
      continue;
    }
    if (!trimmed.contains(forbiddenNeedle)) continue;
    violations.add('$relFile:${i + 1}: $reason');
  }
}

void _scanMapStateMapAreaImports({
  required File file,
  required String relFile,
  required List<String> violations,
}) {
  final lines = file.readAsLinesSync();
  for (var i = 0; i < lines.length; i++) {
    final trimmed = lines[i].trim();
    if (trimmed.startsWith('//')) continue;
    if (!trimmed.startsWith('import ') && !trimmed.startsWith('export ')) {
      continue;
    }
    if (!trimmed.contains(_mapAreaNeedle)) continue;
    final allowed = _allowedMapAreaImportSuffixes.any(trimmed.contains);
    if (!allowed) {
      violations.add(
        '$relFile:${i + 1}: map_state may import map_area public exports only',
      );
    }
  }
}

void _scanForLegacyShimImports({
  required File file,
  required String relFile,
  required List<String> violations,
}) {
  final lines = file.readAsLinesSync();
  for (var i = 0; i < lines.length; i++) {
    final trimmed = lines[i].trim();
    if (trimmed.startsWith('//')) continue;
    if (!trimmed.startsWith('import ') && !trimmed.startsWith('export ')) {
      continue;
    }
    for (final needle in _legacyImportNeedles) {
      if (!trimmed.contains(needle)) continue;
      if (needle == 'features/game/flame/game_map_area_') {
        if (trimmed.contains('/map_state/') ||
            trimmed.contains('/map_area/')) {
          continue;
        }
      }
      violations.add(
        '$relFile:${i + 1}: import legacy flame shim path; use map_area/, map_state/, or region_map/ barrels',
      );
      break;
    }
  }
}

void main(List<String> args) {
  final repoRoot = args.isNotEmpty
      ? p.normalize(args.first)
      : p.normalize(Directory.current.path);
  exit(runCheckAppFlameMapImportBoundary(repoRoot));
}
