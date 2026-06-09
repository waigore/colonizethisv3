import 'dart:io';

import 'package:path/path.dart' as p;

/// Canonical dual-region province iteration lives here; all other world `lib/src`
/// code should prefer `allProvinces` / `WorldState.allProvinces()` (GitHub #2071).
const _canonicalProvinceRelativePath =
    'packages/colonizethis_world/lib/src/world/province_lookup.dart';
const _canonicalUnitRelativePath =
    'packages/colonizethis_world/lib/src/world/unit_lookup.dart';

/// Production source trees scanned for direct `oldWorld`/`newWorld` region-field
/// access.
///
/// Post-split (Refs #3290) the world domain code — including the canonical
/// `province_lookup.dart` / `unit_lookup.dart` and every consumer that walked
/// `oldWorld`/`newWorld` lists directly — moved out of the `colonizethis_logic`
/// monolith into the eight split domain packages. Several budget-0 migration
/// sites recorded in the audit history of
/// `SPEC/program/logic-dual-region-province-access.md` now live in
/// `colonizethis_setup` (`game_setup_helpers_bootstrap.dart`,
/// `game_setup_helpers_naming.dart`) and `colonizethis_orders`
/// (`orders_application.dart`), so scanning only `colonizethis_world/lib/src`
/// would let those packages reintroduce direct dual-region field access without
/// tripping the gate. The checker therefore scans all split domain package
/// source trees (plus the thin `colonizethis_logic` core) where a direct
/// `oldWorld`/`newWorld` access could regress.
const _scanDirsRelative = <String>[
  'packages/colonizethis_world/lib/src',
  'packages/colonizethis_combat/lib/src',
  'packages/colonizethis_economy/lib/src',
  'packages/colonizethis_diplomacy/lib/src',
  'packages/colonizethis_setup/lib/src',
  'packages/colonizethis_orders/lib/src',
  'packages/colonizethis_turn/lib/src',
  'packages/colonizethis_ai_contracts/lib/src',
  'packages/colonizethis_logic/lib/src',
];

/// Exposed for tests verifying the post-split scan roots.
List<String> logicDualRegionProvinceFieldAccessScanDirsForTests() =>
    List<String>.unmodifiable(_scanDirsRelative);

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
  final scanRoots = <Directory>[];
  for (final relative in _scanDirsRelative) {
    final dir = Directory(p.join(root, relative));
    if (!dir.existsSync()) {
      logE('ERROR: Expected domain lib tree missing: $relative');
      return 1;
    }
    scanRoots.add(dir);
  }

  final hits = <LogicDualRegionProvinceFieldHit>[];
  for (final scanRoot in scanRoots) {
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
  }

  if (hits.length <= _maxMatchingLinesOutsideCanonical) {
    logI(
      'Dual-region province field access check passed across split domain '
      'packages (${hits.length}/$_maxMatchingLinesOutsideCanonical lines '
      'outside $_canonicalProvinceRelativePath and '
      '$_canonicalUnitRelativePath).',
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
