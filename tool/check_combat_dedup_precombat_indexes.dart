import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md / SPEC/program/combat-resolution.md (Refs #3448, AC3/AC7).
///
/// Guards the shared pre-combat movement index (#3448, slice 2): the two
/// combat-phase consumers that previously duplicated the movement/province scan
/// must keep delegating to the single `PreCombatMovementIndex` helper rather
/// than re-inlining the duplicated indexing blocks.
///
/// Each consumer must reference both `PreCombatMovementIndex.build` (it builds
/// the shared index once per pass) and `greatPowerArmyMoves` (it iterates the
/// shared, pre-resolved GP army moves). If a future edit re-introduces a private
/// scan and drops the shared index, one of these references disappears and the
/// rule fails.
const _consumerRelativePaths = <String>[
  'packages/colonizethis_combat/lib/src/combat/conflict_detection.dart',
  'packages/colonizethis_combat/lib/src/combat/unopposed_province_capture.dart',
];

const _requiredTokens = <String>[
  'PreCombatMovementIndex.build',
  'greatPowerArmyMoves',
];

void main() {
  exit(runCheckCombatDedupPrecombatIndexes(Directory.current.path));
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckCombatDedupPrecombatIndexes(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);

  final violations = <String>[];
  for (final relative in _consumerRelativePaths) {
    final file = File(p.join(root, relative));
    if (!file.existsSync()) {
      logE('ERROR: Missing pre-combat index consumer: $relative');
      return 1;
    }
    final source = file.readAsStringSync();
    for (final token in _requiredTokens) {
      if (!source.contains(token)) {
        violations.add(
          '$relative no longer references `$token`; it must delegate the '
          'pre-combat movement/province scan to PreCombatMovementIndex '
          '(pre_combat_index.dart) instead of re-inlining it.',
        );
      }
    }
  }

  if (violations.isEmpty) {
    logI('Combat pre-combat index dedup check passed.');
    return 0;
  }

  logE(
    'ERROR: Pre-combat movement indexing must stay deduplicated via '
    'PreCombatMovementIndex (Refs #3448).',
  );
  for (final v in violations) {
    logE(v);
  }
  return 1;
}
