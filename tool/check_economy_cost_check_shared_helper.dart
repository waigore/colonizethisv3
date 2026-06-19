import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3517 Cluster 2).
///
/// Guards the shared "canonical order, first failure" cost-check idiom in the
/// economy package. Recruit-worker affordability (`canAffordRecruitWorker`,
/// `worker_action_cost.dart`) and build-unit affordability
/// (`_resolveBuildPlanForCatalog`, `build_cost.dart`) both evaluate a fixed
/// priority sequence of preconditions (tech -> workers -> treasury ->
/// materials) and return the first failing reason string. That control flow is
/// centralized in `checkPreconditionsInOrder` (`cost_check.dart`) so the
/// canonical priority order and failure-reason vocabulary stay consistent
/// across both paths.
///
/// This rule fails when either consumer drops its reference to the shared
/// helper (i.e. re-inlines the sequential first-failure idiom) or when the
/// canonical helper definition disappears from `cost_check.dart`.
const _helperRelativePath =
    'packages/colonizethis_economy/lib/src/economy/cost_check.dart';

/// The shared helper symbol every cost-check consumer must call.
const _helperSymbol = 'checkPreconditionsInOrder';

/// Cost-check consumers that must delegate to [_helperSymbol] instead of
/// re-inlining the priority-ordered first-failure precondition sweep.
const _consumerRelativePaths = <String>[
  'packages/colonizethis_economy/lib/src/economy/worker_action_cost.dart',
  'packages/colonizethis_economy/lib/src/economy/build_cost.dart',
];

void main() {
  exit(runCheckEconomyCostCheckSharedHelper(Directory.current.path));
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckEconomyCostCheckSharedHelper(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);

  final helperFile = File(p.join(root, _helperRelativePath));
  if (!helperFile.existsSync()) {
    logE('ERROR: Missing shared cost-check helper file: $_helperRelativePath');
    return 1;
  }
  final helperSource = helperFile.readAsStringSync();
  if (!helperSource.contains('$_helperSymbol(')) {
    logE(
      'ERROR: $_helperRelativePath no longer defines the shared '
      '`$_helperSymbol` helper; the canonical cost-check priority order and '
      'failure-reason vocabulary must live in one place (Refs #3517 '
      'Cluster 2).',
    );
    return 1;
  }

  final violations = <String>[];
  for (final relative in _consumerRelativePaths) {
    final file = File(p.join(root, relative));
    if (!file.existsSync()) {
      logE('ERROR: Missing cost-check consumer: $relative');
      return 1;
    }
    final source = file.readAsStringSync();
    if (!source.contains('$_helperSymbol(')) {
      violations.add(
        '$relative no longer calls `$_helperSymbol`; cost-check functions '
        '(canAfford*, _resolve*PlanForCatalog) must delegate the priority-'
        'ordered first-failure sweep to the shared helper in cost_check.dart '
        'instead of re-inlining it.',
      );
    }
  }

  if (violations.isEmpty) {
    logI('Economy cost-check shared-helper check passed.');
    return 0;
  }

  logE(
    'ERROR: Economy cost-check affordability must stay deduplicated via '
    '`$_helperSymbol` (Refs #3517 Cluster 2).',
  );
  for (final v in violations) {
    logE(v);
  }
  return 1;
}
