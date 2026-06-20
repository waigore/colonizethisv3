import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3288).
///
/// Guards the treasury-planner hot path against re-introducing repeated
/// `game.players` linear scans. The treasury planner now resolves single
/// players through the O(1) lookup `game.playerById(playerId)` and computes
/// any per-turn aggregates (treasury totals, trade-eligible players,
/// offer-clearing capacity) in a single precomputed pass threaded into the
/// planner. Iterating `game.players` — `for (final p in game.players)`,
/// `game.players.where(...)`, `game.players.any(...)`, `game.players.map(...)`,
/// etc. — is O(players) per call and, when repeated across the hot path,
/// regresses the 15 000 ms next-turn budget (see
/// `SPEC/program/turn-resolution.md` and
/// `.cursor/rules/colonizethis-turn-resolution-budget.mdc`).
///
/// Scope: `packages/colonizethis_ai/lib/src/planning/treasury_planner.dart`
/// only (the treasury-planner library entry file). `game.players` iteration
/// remains allowed elsewhere — for example `economy_planner.dart`,
/// `full_ai_planner.dart`, and the lock-recovery rotation in
/// `treasury_lock_recovery.dart`, which legitimately need the full player
/// list — exactly as the sibling
/// `repo.ai_no_repeated_production_recipes_catalog_scan` rule keeps
/// `ProductionRecipesCatalog.all` allowed outside this file.

const _treasuryPlannerRelative =
    'packages/colonizethis_ai/lib/src/planning/treasury_planner.dart';

/// Matches `game.players` as a member access. Word-bounded so the O(1) point
/// lookup `game.playerById(...)` (which does not contain the literal
/// `game.players`) never false-positives.
final RegExp _gamePlayersAccess = RegExp(
  r'game\s*\.\s*players\b',
);

void main(List<String> args) {
  exit(runCheckAiNoRepeatedGamePlayersScan(Directory.current.path));
}

int runCheckAiNoRepeatedGamePlayersScan(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final root = p.normalize(repoRoot);
  final file = File(p.join(root, _treasuryPlannerRelative));
  if (!file.existsSync()) {
    logE(
      'ERROR: Missing treasury planner source: $_treasuryPlannerRelative',
    );
    return 1;
  }

  final content = file.readAsStringSync();
  final violations = <String>[];
  for (final match in _gamePlayersAccess.allMatches(content)) {
    final lineNumber =
        '\n'.allMatches(content.substring(0, match.start)).length + 1;
    violations.add('$_treasuryPlannerRelative:$lineNumber');
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_no_repeated_game_players_scan: no violations found.',
    );
    return 0;
  }

  logE(
    'check_ai_no_repeated_game_players_scan: found '
    '${violations.length} game.players scan(s) in '
    '$_treasuryPlannerRelative. Use the O(1) lookup '
    'game.playerById(playerId) for point lookups and precompute per-turn '
    'aggregates in a single pass instead of repeated O(players) scans '
    '(Refs #3288).',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  return 1;
}
