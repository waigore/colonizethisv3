import 'dart:io';

import 'package:path/path.dart' as p;

/// Setup package whose Great Power id list/set construction from `game.players`
/// must stay deduplicated behind the shared `gpIdsSortedFromPlayers(...)` helper
/// (Refs #3449). The resource and terrain redistribution concerns each
/// previously rebuilt the slot-ordered GP id list with verbatim
/// `game.players.map((p) => p.id).toList()` / `.toSet()` expressions.
const _setupLibDir = 'packages/colonizethis_setup/lib/src/setup';

/// The shared module that owns the canonical `gpIdsSortedFromPlayers` helper.
/// It is the only setup source allowed to derive GP ids directly from players.
const _sharedModuleRelativePath =
    'packages/colonizethis_setup/lib/src/setup/gp_old_world_tile_scan.dart';

/// Re-inlined GP-id projection over a player collection, e.g.
/// `game.players.map((p) => p.id)` or `players.map((x) => x.id)`. Any match
/// outside the shared module signals a duplicated slot-order id construction
/// that should call `gpIdsSortedFromPlayers(game)` (and `.toSet()` for the set).
final RegExp _bannedPlayersIdProjection = RegExp(
  r'players\.map\(\s*\(\s*\w+\s*\)\s*=>\s*\w+\.id\s*\)',
);

/// True when [line] is a pure comment line (`//`, `///`, or a `*` doc/block
/// continuation), so a pattern mentioned in prose is not flagged.
bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckSetupDedupGpIdsFromPlayers(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, _setupLibDir));
  if (!dir.existsSync()) {
    logI(
      'Setup dedup GP-ids-from-players check skipped (setup lib dir absent).',
    );
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

  final violations = findSetupDedupGpIdsFromPlayersViolations(
    sourcesByPath: sourcesByPath,
  );

  if (violations.isEmpty) {
    logI('Setup dedup GP-ids-from-players check passed.');
    return 0;
  }

  logE(
    'ERROR: Found duplicated Great Power id construction from game.players in '
    'the setup package. Call gpIdsSortedFromPlayers(game) (slot order) from '
    'gp_old_world_tile_scan.dart and derive the set via .toSet() instead of '
    're-inlining game.players.map((p) => p.id).',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckSetupDedupGpIdsFromPlayers(Directory.current.path));
}

/// Scans [sourcesByPath] (relative path -> source) for re-inlined GP-id
/// projections over a player collection. The shared module
/// ([_sharedModuleRelativePath]) is exempt because it owns the canonical
/// `gpIdsSortedFromPlayers` helper.
List<SetupDedupGpIdsFromPlayersViolation>
findSetupDedupGpIdsFromPlayersViolations({
  required Map<String, String> sourcesByPath,
}) {
  final violations = <SetupDedupGpIdsFromPlayersViolation>[];
  final paths = sourcesByPath.keys.toList()..sort();
  for (final path in paths) {
    final normalized = p.normalize(path);
    if (normalized == p.normalize(_sharedModuleRelativePath)) continue;
    final lines = sourcesByPath[path]!.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isCommentLine(line)) continue;
      if (_bannedPlayersIdProjection.hasMatch(line)) {
        violations.add(
          SetupDedupGpIdsFromPlayersViolation(
            path: path,
            line: i + 1,
            message:
                'Duplicated GP-id projection over players; call '
                'gpIdsSortedFromPlayers(game) instead.',
          ),
        );
      }
    }
  }
  return violations;
}

class SetupDedupGpIdsFromPlayersViolation {
  const SetupDedupGpIdsFromPlayersViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
