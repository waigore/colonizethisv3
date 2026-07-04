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

void main(List<String> args) {
  final repoRoot = args.isNotEmpty
      ? p.normalize(args.first)
      : p.normalize(Directory.current.path);
  exit(runCheckAppFlameMapImportBoundary(repoRoot));
}
