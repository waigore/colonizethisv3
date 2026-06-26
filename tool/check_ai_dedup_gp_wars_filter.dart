import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3278).
///
/// Enforces the shared GP-wars filter contract for `colonizethis_ai`:
/// `lib/**` planner/filter code must call the shared
/// `gpFactionIdsAtWarWith(game, snapshot)` / `isAtWarWithAnyGreatPower(game,
/// snapshot)` helpers instead of re-inlining the Great-Power at-war filter,
/// whether spelled as the
/// `[for (final f in snapshot.threats.atWarWith) if (game.playerById(f) !=
/// null) f]` comprehension or the functional
/// `snapshot.threats.atWarWith.any/where((id) => game.playerById(id) != null)`
/// form.
///
/// The single canonical home (`lib/src/planning/planning_helpers.dart`) is
/// the only file allowed to contain the filter; every other inline copy is
/// rejected so the deterministic GP filter lives in one place.
///
/// Detection is structural. Two patterns are rejected:
///   1. A `for (final … in <expr>.atWarWith)` comprehension header followed
///      (within a short window) by a `playerById(...) != null` test.
///   2. An `<expr>.atWarWith.any(` / `<expr>.atWarWith.where(` call whose body
///      (within the same statement, no intervening `;`) contains a
///      `playerById(...) != null` test — the functional dedup form (Refs
///      #3717).
///
/// The unrelated `for (final … in candidates) { if (playerById(...) != null)
/// continue; … }` skip loop, `.atWarWith.contains(...)` membership tests, and
/// `.atWarWith.any(...)` predicates that do *not* test `playerById(...) !=
/// null` (for example the minor-owner / invadable predicate) are not matched.

const _aiLibRelative = 'packages/colonizethis_ai/lib';

/// Canonical home of `gpFactionIdsAtWarWith` — the only allowed comprehension.
const _allowedRelative =
    'packages/colonizethis_ai/lib/src/planning/planning_helpers.dart';

/// `for (final <id> in <expr>.atWarWith)` … `playerById(<...>) != null`.
final RegExp _inlineGpWarsFilter = RegExp(
  r'for\s*\(\s*final\s+\w+\s+in\s+[^)]*\.atWarWith\s*\)'
  r'[\s\S]{0,200}?playerById\s*\([^)]*\)\s*!=\s*null',
);

/// `<expr>.atWarWith.any(`/`.where(` … `playerById(<...>) != null`, bounded to
/// the same statement (`[^;]`) so unrelated later `playerById` tests and
/// non-`playerById` `atWarWith.any(...)` predicates do not match (Refs #3717).
final RegExp _inlineGpWarsFunctionalFilter = RegExp(
  r'\.atWarWith\s*\.\s*(?:any|where)\s*\('
  r'[^;]{0,200}?playerById\s*\([^)]*\)\s*!=\s*null',
);

void main(List<String> args) {
  exit(runCheckAiDedupGpWarsFilter(Directory.current.path));
}

int runCheckAiDedupGpWarsFilter(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final root = p.normalize(repoRoot);
  final libDir = Directory(p.join(root, _aiLibRelative));
  if (!libDir.existsSync()) {
    logE('ERROR: Missing colonizethis_ai lib directory: $_aiLibRelative');
    return 1;
  }

  final allowedPath = p.normalize(p.join(root, _allowedRelative));
  final violations = <String>[];
  for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (p.normalize(entity.path) == allowedPath) continue;
    final relative = p.relative(entity.path, from: root);
    final content = entity.readAsStringSync();
    final match = _inlineGpWarsFilter.firstMatch(content) ??
        _inlineGpWarsFunctionalFilter.firstMatch(content);
    if (match == null) continue;
    final lineNumber =
        '\n'.allMatches(content.substring(0, match.start)).length + 1;
    violations.add('$relative:$lineNumber');
  }

  if (violations.isEmpty) {
    logI('check_ai_dedup_gp_wars_filter: no violations found.');
    return 0;
  }

  logE(
    'check_ai_dedup_gp_wars_filter: found ${violations.length} inline '
    'GP-wars filter(s) in $_aiLibRelative. Use the shared '
    '`gpFactionIdsAtWarWith(game, snapshot)` (for the id list/length) or '
    '`isAtWarWithAnyGreatPower(game, snapshot)` (for the boolean presence '
    'check) helper from src/planning/planning_helpers.dart instead.',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  return 1;
}
