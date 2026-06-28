import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3288).
///
/// Guards the treasury-planner hot path against re-introducing full
/// `ProductionRecipesCatalog.all` scans. The treasury planner now resolves
/// recipes by output commodity through the O(1) index
/// `ProductionRecipesCatalog.producing(commodityId)` (backed by
/// `byOutputCommodityId`). Iterating `ProductionRecipesCatalog.all` and
/// filtering on `outputCommodityId` is O(recipes) per commodity per player and
/// regresses the 15 000 ms next-turn budget (see
/// `SPEC/program/turn-resolution.md` and
/// `.cursor/rules/colonizethis-turn-resolution-budget.mdc`).
///
/// Scope: `packages/colonizethis_ai/lib/src/planning/treasury_planner.dart`
/// only. `ProductionRecipesCatalog.all` remains allowed elsewhere (for example
/// `economy_planner.dart`, which legitimately needs the full catalog).

const _treasuryPlannerRelative =
    'packages/colonizethis_ai/lib/src/planning/treasury_planner.dart';

/// Matches `ProductionRecipesCatalog.all` as a member access (word-bounded so
/// future members such as `allBy...` would not false-positive).
final RegExp _catalogAllAccess = RegExp(
  r'ProductionRecipesCatalog\s*\.\s*all\b',
);

void main(List<String> args) {
  exit(runCheckAiNoRepeatedProductionRecipesCatalogScan(Directory.current.path));
}

int runCheckAiNoRepeatedProductionRecipesCatalogScan(
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
  for (final match in _catalogAllAccess.allMatches(content)) {
    final lineNumber =
        '\n'.allMatches(content.substring(0, match.start)).length + 1;
    violations.add('$_treasuryPlannerRelative:$lineNumber');
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_no_repeated_production_recipes_catalog_scan: '
      'no violations found.',
    );
    return 0;
  }

  logE(
    'check_ai_no_repeated_production_recipes_catalog_scan: found '
    '${violations.length} ProductionRecipesCatalog.all scan(s) in '
    '$_treasuryPlannerRelative. Use the O(1) index '
    'ProductionRecipesCatalog.producing(commodityId) keyed by output '
    'commodity instead (Refs #3288).',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  return 1;
}
