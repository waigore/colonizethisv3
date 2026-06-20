import 'dart:io';

import 'package:path/path.dart' as p;

/// Canonical `unitsByIdFromWorld` lives here; all other logic `lib/src` code
/// must use the cached `WorldStateUnitLookup.allUnitsById` extension getter
/// instead, so the `_WorldUnitIndex` cache built per [WorldState] is reused
/// across the order-suggestion / turn-resolution call chain (Refs #2836 AC 2;
/// SPEC/program/order-suggestions.md § Throughput bounds).
const _canonicalUnitRelativePath =
    'packages/colonizethis_world/lib/src/world/unit_lookup.dart';

/// Production source trees scanned for non-canonical `unitsByIdFromWorld(` call
/// sites.
///
/// Post-split (Refs #3290) the world domain code — including the canonical
/// `unit_lookup.dart` and every consumer that walks units — moved out of the
/// `colonizethis_logic` monolith into the eight split domain packages. Scanning
/// only the now-thin `colonizethis_logic/lib/src` core would make this gate a
/// silent no-op, so it scans all split domain package source trees (plus the
/// thin core) where a `unitsByIdFromWorld(` rebuild could regress.
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
List<String> logicUnitsByIdRebuildScanDirsForTests() =>
    List<String>.unmodifiable(_scanDirsRelative);

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');
final RegExp _callPattern = RegExp(r'unitsByIdFromWorld\(');

/// Returns true when [line] looks like an actual `unitsByIdFromWorld(` call
/// site outside the canonical unit_lookup module (excluding doc-comment
/// references which should still be allowed for backwards-compat narrative).
bool logicUnitsByIdRebuildLineMatches(String line) {
  final trimmed = line.trimLeft();
  if (trimmed.startsWith('//') || trimmed.startsWith('///')) {
    return false;
  }
  return _callPattern.hasMatch(line);
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckLogicUnitsByIdRebuild(
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

  final hits = <LogicUnitsByIdRebuildHit>[];
  for (final scanRoot in scanRoots) {
    for (final entity in scanRoot.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      final fullPath = p.normalize(entity.path);
      if (!fullPath.endsWith('.dart')) continue;
      if (_generatedSuffix.hasMatch(fullPath)) continue;
      final relative = p.normalize(p.relative(fullPath, from: root));
      if (relative == _canonicalUnitRelativePath) {
        continue;
      }

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (logicUnitsByIdRebuildLineMatches(line)) {
          hits.add(LogicUnitsByIdRebuildHit(path: relative, line: i + 1));
        }
      }
    }
  }

  if (hits.isEmpty) {
    logI(
      'Logic units-by-id rebuild check passed '
      '(no unitsByIdFromWorld( call sites under '
      '${_scanDirsRelative.join(', ')} outside $_canonicalUnitRelativePath).',
    );
    return 0;
  }

  logE(
    'ERROR: unitsByIdFromWorld( is called outside the canonical module. '
    'Use the cached WorldStateUnitLookup.allUnitsById getter '
    '(`world.allUnitsById`) so the per-WorldState _WorldUnitIndex cache is '
    'reused (Refs #2836 AC 2). For a mutable copy, take '
    '`Map<String, Unit>.from(world.allUnitsById)`.',
  );
  for (final h in hits) {
    logE('${h.path}:${h.line}');
  }
  return 1;
}

void main() {
  exit(runCheckLogicUnitsByIdRebuild(Directory.current.path));
}

final class LogicUnitsByIdRebuildHit {
  const LogicUnitsByIdRebuildHit({required this.path, required this.line});

  final String path;
  final int line;
}
