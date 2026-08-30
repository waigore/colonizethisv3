import 'dart:io';

import 'package:path/path.dart' as p;

/// Canonical dual-region province iteration lives in the province lookup modules;
/// all other world `lib/src` code should prefer `allProvinces` /
/// `WorldState.allProvinces()` (GitHub #2071; wave-5 split Refs #4125).
const _canonicalProvinceRelativePaths = <String>[
  'packages/colonizethis_world/lib/src/world/province_lookup.dart',
  'packages/colonizethis_world/lib/src/world/province_lookup_extension.dart',
  'packages/colonizethis_world/lib/src/world/province_lookup_indexes.dart',
];
const _canonicalUnitRelativePath =
    'packages/colonizethis_world/lib/src/world/unit_lookup.dart';

/// Post-split scan roots (Refs #3290 world; Refs #4660 thin logic core).
const _scanDirRelatives = <String>[
  'packages/colonizethis_world/lib/src',
  'packages/colonizethis_logic/lib/src',
];

/// Exposed for tests verifying the post-split scan roots.
List<String> logicDualRegionProvinceFieldAccessScanDirsForTests() =>
    List<String>.unmodifiable(_scanDirRelatives);

/// Backward-compatible single-root accessor used by older tests.
String logicDualRegionProvinceFieldAccessScanDirForTests() =>
    _scanDirRelatives.first;

/// Keep direct dual-region field access rare; budget tracks the smallest value
/// confirmed achievable by the audit recorded in
/// SPEC/program/logic-dual-region-province-access.md (Refs #2836 AC 5; #4660).
const _maxMatchingLinesOutsideCanonical = 0;

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');
final RegExp _manualRegionBranchPattern = RegExp(
  r'^\s*(if|else if)\s*\(\s*regionId\s*==\s*kRegionOldWorld\s*\)',
);

/// List-literal region iteration such as
/// `[game.worldState.oldWorld, game.worldState.newWorld]` bypasses the canonical
/// dual-region traversal helpers (`WorldState.regionsInOrder` /
/// `forEachWorldRegion`) and previously escaped this gate because it carries no
/// `oldWorld.provinces` / `newWorld.provinces` substring (Refs #3710). Matches a
/// `[` that reaches `.oldWorld` then `.newWorld` before the closing `]` on the
/// same line; record types `(oldWorld: ..., newWorld: ...)` use `(` and are not
/// matched.
final RegExp _regionListLiteralPattern = RegExp(
  r'\[[^\]]*\.oldWorld\b[^\]]*\.newWorld\b',
);

bool logicDualRegionProvinceFieldAccessLineMatches(String line) {
  return line.contains('oldWorld.provinces') ||
      line.contains('newWorld.provinces') ||
      line.contains('oldWorld.units') ||
      line.contains('newWorld.units') ||
      line.contains('copyWith(oldWorld:') ||
      line.contains('copyWith(newWorld:') ||
      _manualRegionBranchPattern.hasMatch(line) ||
      _regionListLiteralPattern.hasMatch(line);
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

  final hits = <LogicDualRegionProvinceFieldHit>[];
  for (final scanRelative in _scanDirRelatives) {
    final scanRoot = Directory(p.join(root, scanRelative));
    if (!scanRoot.existsSync()) {
      // World tree is required; logic core is required when present on real
      // workspaces. Missing world fails; missing logic in fixtures is OK only
      // when world is also absent (handled below via world-required check).
      if (scanRelative == _scanDirRelatives.first) {
        logE('ERROR: Expected world lib tree missing: $scanRelative');
        return 1;
      }
      continue;
    }

    for (final entity in scanRoot.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      final fullPath = p.normalize(entity.path);
      if (!fullPath.endsWith('.dart')) continue;
      if (_generatedSuffix.hasMatch(fullPath)) continue;
      final relative = p.relative(fullPath, from: root);
      final normalizedRelative = p.normalize(relative);
      if (_canonicalProvinceRelativePaths.contains(normalizedRelative) ||
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
  }

  if (hits.length <= _maxMatchingLinesOutsideCanonical) {
    logI(
      'World dual-region province field access check passed '
      '(${hits.length}/$_maxMatchingLinesOutsideCanonical lines outside '
      '$_canonicalProvinceRelativePaths and $_canonicalUnitRelativePath).',
    );
    return 0;
  }

  logE(
    'ERROR: Too many direct oldWorld/newWorld region-field references '
    '(provinces/units/manual regionId branching/copyWith oldWorld-newWorld) outside '
    '$_canonicalProvinceRelativePaths and '
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

class LogicDualRegionProvinceFieldHit {
  const LogicDualRegionProvinceFieldHit({
    required this.path,
    required this.line,
  });

  final String path;
  final int line;
}

void main() {
  exit(runCheckLogicDualRegionProvinceFieldAccess(Directory.current.path));
}
