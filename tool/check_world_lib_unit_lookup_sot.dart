import 'dart:io';

import 'package:path/path.dart' as p;

/// Canonical `allUnitsFromWorld` lives here; other world `lib/src` files must
/// iterate `WorldState.allUnitsById.values` (Refs #4611).
const _canonicalUnitRelativePath =
    'packages/colonizethis_world/lib/src/world/unit_lookup.dart';

const _scanDirRelative = 'packages/colonizethis_world/lib/src';

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');
final RegExp _callPattern = RegExp(r'allUnitsFromWorld\(');

/// True when [line] is a non-comment `allUnitsFromWorld(` call site.
bool worldLibUnitLookupSotLineMatches(String line) {
  final trimmed = line.trimLeft();
  if (trimmed.startsWith('//') || trimmed.startsWith('///')) {
    return false;
  }
  return _callPattern.hasMatch(line);
}

int runCheckWorldLibUnitLookupSot(
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

  final hits = <({String path, int line})>[];
  for (final entity in scanRoot.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final fullPath = p.normalize(entity.path);
    if (!fullPath.endsWith('.dart')) continue;
    if (_generatedSuffix.hasMatch(fullPath)) continue;
    final relative = p.normalize(p.relative(fullPath, from: root));
    if (relative.replaceAll('\\', '/') == _canonicalUnitRelativePath) {
      continue;
    }

    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      if (worldLibUnitLookupSotLineMatches(lines[i])) {
        hits.add((path: relative, line: i + 1));
      }
    }
  }

  if (hits.isEmpty) {
    logI(
      'World unit-lookup SoT check passed '
      '(no allUnitsFromWorld( call sites under $_scanDirRelative '
      'outside $_canonicalUnitRelativePath).',
    );
    return 0;
  }

  logE(
    'ERROR: allUnitsFromWorld( is called outside unit_lookup.dart. '
    'Iterate world.allUnitsById.values (Refs #4611).',
  );
  for (final h in hits) {
    logE('${h.path}:${h.line}');
  }
  return 1;
}

void main() {
  exit(runCheckWorldLibUnitLookupSot(Directory.current.path));
}
