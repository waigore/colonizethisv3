import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3717).
///
/// Enforces the shared minor / tribe faction-membership contract for
/// `colonizethis_ai`: `lib/**` planner/scoring code must call the canonical
/// `isMinorFaction(game, id)` / `isTribeFaction(game, id)` /
/// `isMinorOrTribeFaction(game, id)` helpers from `src/util/faction_query.dart`
/// instead of re-inlining the roster-membership predicate
/// `game.minorNations.any((m) => m.id == <id>)` or
/// `game.tribes.any((t) => t.id == <id>)`.
///
/// The single canonical home (`lib/src/util/faction_query.dart`) is the only
/// file allowed to contain the membership predicate; every other inline copy
/// is rejected so the deterministic faction-membership check lives in one
/// place (`colonizethis-component-structure.mdc` — reuse at 2+ uses).
///
/// Detection is structural and conservative. The rejected pattern is a
/// `(minorNations|tribes).any((<param>) => <param>.id == ...)` call — the
/// roster-membership form. Iterating the same rosters for a *different*
/// predicate (for example `game.minorNations.any((m) =>
/// ownerCache.ownsAnyInRegion(m.id, kRegionOldWorld))` or
/// `game.minorNations.any((m) => _minorOwnsOldWorldProvinces(game, m.id))`)
/// does not contain the `<param>.id ==` equality test and is therefore not
/// matched.

const _aiLibRelative = 'packages/colonizethis_ai/lib';

/// Canonical home of the membership predicates — the only allowed inline copy.
const _allowedRelative =
    'packages/colonizethis_ai/lib/src/util/faction_query.dart';

/// `(minorNations|tribes).any((<param>) => <param>.id == ...)`.
final RegExp _inlineMembership = RegExp(
  r'\b(?:minorNations|tribes)\s*\.\s*any\s*\(\s*\(\s*(\w+)\s*\)\s*=>\s*'
  r'\1\s*\.\s*id\s*==',
);

void main(List<String> args) {
  exit(runCheckAiDedupMinorTribeMembership(Directory.current.path));
}

int runCheckAiDedupMinorTribeMembership(
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
    final content = entity.readAsStringSync();
    final match = _inlineMembership.firstMatch(content);
    if (match == null) continue;
    final relative = p.relative(entity.path, from: root);
    final lineNumber =
        '\n'.allMatches(content.substring(0, match.start)).length + 1;
    violations.add('$relative:$lineNumber');
  }

  if (violations.isEmpty) {
    logI('check_ai_dedup_minor_tribe_membership: no violations found.');
    return 0;
  }

  logE(
    'check_ai_dedup_minor_tribe_membership: found ${violations.length} inline '
    'minor/tribe membership check(s) in $_aiLibRelative. Use the shared '
    '`isMinorFaction(game, id)`, `isTribeFaction(game, id)`, or '
    '`isMinorOrTribeFaction(game, id)` helper from '
    'src/util/faction_query.dart instead.',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  return 1;
}
