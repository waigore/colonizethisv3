import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3615 Cluster 3).
///
/// Guards the deduplicated port-tile-key collection in the economy package.
/// `collectPortTileKeys` (`game_lookup_helpers.dart`) is the single canonical
/// builder of the per-seaboard port tile-key set; it was extracted to remove
/// the copy-pasted `portsByProvinceSeaboard.values.toSet()` comprehension
/// (#3396 Cluster 5). This rule fails when any economy lib source re-inlines
/// that comprehension outside the shared helper file, mirroring
/// `repo.setup_dedup_gp_ow_tile_scans`.
const _economyLibDir = 'packages/colonizethis_economy/lib';

/// The shared helper module that owns the canonical port-tile-key builder. It
/// is the only file allowed to inline the `portsByProvinceSeaboard.values`
/// comprehension.
const _sharedHelperRelativePath =
    'packages/colonizethis_economy/lib/src/economy/game_lookup_helpers.dart';

/// Matches the re-inlined port tile-key comprehension
/// (`portsByProvinceSeaboard.values.toSet()`), tolerant of whitespace between
/// the member accesses so reformatting cannot defeat the gate.
final RegExp _bannedInlinePortTileKeys = RegExp(
  r'portsByProvinceSeaboard\s*\.\s*values\s*\.\s*toSet\s*\(',
);

/// True when [line] is a pure comment line (`//`, `///`, or a `*` doc/block
/// continuation), so a pattern mentioned in prose is not flagged.
bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

void main() {
  exit(runCheckEconomyDedupPortTileKeys(Directory.current.path));
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckEconomyDedupPortTileKeys(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, _economyLibDir));
  if (!dir.existsSync()) {
    logI('Economy dedup port-tile-keys check skipped (economy lib absent).');
    return 0;
  }

  final sourcesByPath = <String, String>{};
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('.g.dart')) continue;
    final relativePath = p.relative(entity.path, from: root);
    sourcesByPath[relativePath] = entity.readAsStringSync();
  }

  final violations = findEconomyDedupPortTileKeysViolations(
    sourcesByPath: sourcesByPath,
  );

  if (violations.isEmpty) {
    logI('Economy dedup port-tile-keys check passed.');
    return 0;
  }

  logE(
    'ERROR: Found re-inlined port tile-key collection in the economy '
    'package. Use collectPortTileKeys(game) from game_lookup_helpers.dart '
    'instead of inlining portsByProvinceSeaboard.values.toSet() '
    '(Refs #3615 Cluster 3, #3396 Cluster 5).',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

/// Scans [sourcesByPath] (relative path -> source) for re-inlined port
/// tile-key comprehensions. The shared helper module
/// ([_sharedHelperRelativePath]) is exempt because it owns the canonical
/// `collectPortTileKeys` builder.
List<EconomyDedupPortTileKeysViolation> findEconomyDedupPortTileKeysViolations({
  required Map<String, String> sourcesByPath,
}) {
  final violations = <EconomyDedupPortTileKeysViolation>[];
  final paths = sourcesByPath.keys.toList()..sort();
  for (final path in paths) {
    if (p.normalize(path) == p.normalize(_sharedHelperRelativePath)) continue;
    final lines = sourcesByPath[path]!.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isCommentLine(line)) continue;
      if (_bannedInlinePortTileKeys.hasMatch(line)) {
        violations.add(
          EconomyDedupPortTileKeysViolation(
            path: path,
            line: i + 1,
            message:
                'Re-inlined portsByProvinceSeaboard.values.toSet(); use '
                'collectPortTileKeys(game) from game_lookup_helpers.dart.',
          ),
        );
      }
    }
  }
  return violations;
}

class EconomyDedupPortTileKeysViolation {
  const EconomyDedupPortTileKeysViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
