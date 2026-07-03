/// Locks in the #3749 step-5 EXPAND-regime peace **decider registry** so the
/// peace aggregators stay composed from ordered `ExpandPeaceDecider` data
/// instead of regressing to hand-unrolled `yield*` decider chains.
///
/// `observer_goal_phase.dart` hosts the `ExpandPeaceDecider` typedef, the two
/// ordered registry constants (`kSurvivalGreatPowerPeaceDeciders`,
/// `kExpandRatchetGreatPowerPeaceDeciders`), and the two aggregators that fold
/// them (`survivalGreatPowerPeaceTargets`,
/// `expandRatchetGreatPowerPeaceTargets`). Each aggregator must iterate its
/// registry and `yield* decider(...)`; a regression that re-inlines a
/// `yield* someSpecificPeaceTargets(...)` chain (bypassing the registry) is a
/// violation. Normative: `SPEC/program/repo-lint.md` and `SPEC/ai/` expand-peace
/// planning docs (Refs #3749).
library;

import 'dart:io';

/// Repo-relative path of the canonical expand-peace decider registry host.
const String expandPeaceDeciderRegistryHostFile =
    'packages/colonizethis_ai/lib/src/planning/observer_goal_phase.dart';

/// The `ExpandPeaceDecider` function-type alias that every registered decider
/// must satisfy.
const String _expandPeaceDeciderTypedef = 'ExpandPeaceDecider';

/// The ordered registry constants that the EXPAND-regime peace aggregators must
/// fold. The bare loop variable bound by each aggregator's
/// `for (final decider in <registry>)`.
const List<String> expandPeaceDeciderRegistryConstants = <String>[
  'kSurvivalGreatPowerPeaceDeciders',
  'kExpandRatchetGreatPowerPeaceDeciders',
];

/// The canonical loop-variable name each aggregator yields through; the only
/// identifier allowed after `yield*` in the registry host.
const String _registryLoopVariable = 'decider';

/// Strips `//`/`///` line comments so doc-comment prose that mentions `yield*`
/// or the registry symbols never trips the structural checks. Block comments
/// are not used for these patterns in the host file, so line stripping is
/// sufficient and deterministic.
String _stripLineComments(String content) {
  final out = StringBuffer();
  for (final line in content.split('\n')) {
    final idx = line.indexOf('//');
    out.writeln(idx >= 0 ? line.substring(0, idx) : line);
  }
  return out.toString();
}

final RegExp _yieldStarCall = RegExp(r'yield\*\s+([A-Za-z_]\w*)\s*\(');

/// Returns the list of structural violations for the registry host file
/// [content] (already read from disk), or an empty list when compliant.
///
/// Pure and deterministic — identical [content] always yields identical
/// reasons, so the gate can be unit-tested without filesystem access.
List<String> expandPeaceDeciderRegistryViolations(String content) {
  final code = _stripLineComments(content);
  final violations = <String>[];

  if (!code.contains('typedef $_expandPeaceDeciderTypedef')) {
    violations.add(
      'missing `typedef $_expandPeaceDeciderTypedef` — the expand-peace '
      'decider registry contract must be declared here',
    );
  }

  for (final registry in expandPeaceDeciderRegistryConstants) {
    if (!code.contains(
      'List<$_expandPeaceDeciderTypedef> $registry',
    )) {
      violations.add(
        'missing ordered registry constant '
        '`List<$_expandPeaceDeciderTypedef> $registry`',
      );
    }
    if (!code.contains('for (final $_registryLoopVariable in $registry)')) {
      violations.add(
        'no aggregator folds `$registry` via '
        '`for (final $_registryLoopVariable in $registry)` — peace targets '
        'must be composed from the ordered registry, not a hand-unrolled chain',
      );
    }
  }

  for (final match in _yieldStarCall.allMatches(code)) {
    final yielded = match.group(1);
    if (yielded != _registryLoopVariable) {
      violations.add(
        'hand-unrolled `yield* $yielded(...)` bypasses the decider registry; '
        'add the decider to an `$_expandPeaceDeciderTypedef` registry constant '
        'and fold it via `for (final $_registryLoopVariable in <registry>)`',
      );
    }
  }

  return violations;
}

int runCheckAiExpandPeaceDeciderRegistry(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final hostPath = '$repoRoot/$expandPeaceDeciderRegistryHostFile';
  final hostFile = File(hostPath.replaceAll('/', Platform.pathSeparator));
  if (!hostFile.existsSync()) {
    logE(
      'check_ai_expand_peace_decider_registry: registry host file missing: '
      '$expandPeaceDeciderRegistryHostFile',
    );
    return 1;
  }

  final violations = expandPeaceDeciderRegistryViolations(
    hostFile.readAsStringSync(),
  );

  if (violations.isEmpty) {
    logI(
      'check_ai_expand_peace_decider_registry: EXPAND-regime peace deciders '
      'are composed via the documented registry.',
    );
    return 0;
  }

  logE(
    'check_ai_expand_peace_decider_registry: ${violations.length} '
    'violation(s) in $expandPeaceDeciderRegistryHostFile:',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAiExpandPeaceDeciderRegistry(Directory.current.path));
}
