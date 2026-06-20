import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3433).
///
/// Enforces that `combat_resolver_probabilistic.dart` uses the shared
/// `aggregateStrength` from `military_strength.dart` instead of redefining a
/// private `_aggregateStrength` copy.
const _targetRelative =
    'packages/colonizethis_combat/lib/src/combat/combat_resolver_probabilistic.dart';

final RegExp _privateAggregateStrength = RegExp(
  r'(?:^|\n)\s*(?:double|num)\s+_aggregateStrength\s*\(',
  multiLine: true,
);

void main(List<String> args) {
  exit(runCheckCombatNoPrivateAggregateStrength(Directory.current.path));
}

int runCheckCombatNoPrivateAggregateStrength(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final root = p.normalize(repoRoot);
  final targetPath = p.join(root, _targetRelative);
  final file = File(targetPath);
  if (!file.existsSync()) {
    logE('ERROR: Missing combat probabilistic resolver: $_targetRelative');
    return 1;
  }

  final content = file.readAsStringSync();
  final match = _privateAggregateStrength.firstMatch(content);
  if (match == null) {
    logI('check_combat_no_private_aggregate_strength: no violations found.');
    return 0;
  }

  final lineNumber =
      '\n'.allMatches(content.substring(0, match.start)).length + 1;
  logE(
    'check_combat_no_private_aggregate_strength: found private '
    '`_aggregateStrength` in $_targetRelative:$lineNumber. '
    'Use the public `aggregateStrength` from military_strength.dart instead.',
  );
  return 1;
}
