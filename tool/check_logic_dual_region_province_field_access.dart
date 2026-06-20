import 'dart:io';

import 'package:path/path.dart' as p;

/// Canonical dual-region province iteration lives here; all other world `lib/src`
/// code should prefer `allProvinces` / `WorldState.allProvinces()` (GitHub #2071).
const _canonicalProvinceRelativePath =
    'packages/colonizethis_world/lib/src/world/province_lookup.dart';
const _canonicalUnitRelativePath =
    'packages/colonizethis_world/lib/src/world/unit_lookup.dart';

/// Post-split scan root (Refs #3290): world domain code moved out of the monolith.
const _scanDirRelative = 'packages/colonizethis_world/lib/src';

/// Exposed for tests verifying the post-split scan root.
String logicDualRegionProvinceFieldAccessScanDirForTests() =>
    _scanDirRelative;

/// Keep direct dual-region field access rare; budget tracks the smallest value
/// confirmed achievable by the audit recorded in
/// SPEC/program/logic-dual-region-province-access.md (Refs #2836 AC 5).
const _maxMatchingLinesOutsideCanonical = 0;

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');
final RegExp _manualRegionBranchPattern = RegExp(
  r'^\s*(if|else if)\s*\(\s*regionId\s*==\s*kRegionOldWorld\s*\)',
);

bool logicDualRegionProvinceFieldAccessLineMatches(String line) {
  return line.contains('oldWorld.provinces') ||
      line.contains('newWorld.provinces') ||
      line.contains('oldWorld.units') ||
      line.contains('newWorld.units') ||
      line.contains('copyWith(oldWorld:') ||
      line.contains('copyWith(newWorld:') ||
      _manualRegionBranchPattern.hasMatch(line);
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckLogicDualRegionProvinceFieldAccess(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final scanRoot = Directory(p.join(root, _scanDirRelative));
  if (!scanRoot.existsSync()) {
    logE('ERROR: Expected world lib tree missing: $_scanDirRelative');
    return 1;
  }

  final hits = <LogicDualRegionProvinceFieldHit>[];
  for (final entity in scanRoot.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final fullPath = p.normalize(entity.path);
    if (!fullPath.endsWith('.dart')) continue;
    if (_generatedSuffix.hasMatch(fullPath)) continue;
    final relative = p.relative(fullPath, from: root);
    final normalizedRelative = p.normalize(relative);
    if (normalizedRelative == _canonicalProvinceRelativePath ||
        normalizedRelative == _canonicalUnitRelativePath) {
      continue;
    }

    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (logicDualRegionProvinceFieldAccessLineMatches(line)) {
        hits.add(
          LogicDualRegionProvinceFieldHit(
            path: p.normalize(relative),
            line: i + 1,
          ),
        );
      }
    }
  }

  if (hits.length <= _maxMatchingLinesOutsideCanonical) {
    logI(
      'World dual-region province field access check passed '
      '(${hits.length}/$_maxMatchingLinesOutsideCanonical lines outside '
      '$_canonicalProvinceRelativePath and $_canonicalUnitRelativePath).',
    );
    return 0;
  }

  logE(
    'ERROR: Too many direct oldWorld/newWorld region-field references '
    '(provinces/units/manual regionId branching/copyWith oldWorld-newWorld) outside '
    '$_canonicalProvinceRelativePath and '
    '$_canonicalUnitRelativePath '
    '(${hits.length} > $_maxMatchingLinesOutsideCanonical). '
    'Prefer allProvinces(world), WorldState.allProvinces(), allUnits(world), '
    'WorldState.allUnits(), or WorldState.updateRegionById(...) per '
    'SPEC/program/logic-dual-region-province-access.md.',
  );
  for (final h in hits) {
    logE('${h.path}:${h.line}');
  }
  return 1;
}

void main() {
  exit(runCheckLogicDualRegionProvinceFieldAccess(Directory.current.path));
}

final class LogicDualRegionProvinceFieldHit {
  const LogicDualRegionProvinceFieldHit({
    required this.path,
    required this.line,
  });

  final String path;
  final int line;
}
