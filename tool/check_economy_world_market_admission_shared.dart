import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3615 Cluster 1).
///
/// Guards the shared world-market trade-order admission helpers in the economy
/// package. `trade_order_admission.dart` owns the rule-2 (tradeable),
/// rule-3 (mutual exclusion) and rule-4 (submission-order bid admission)
/// contracts; `TradeOrderValidator` and `TradeOrderSuggester` must delegate to
/// it instead of re-inlining the riches predicate or the bid-admission loop.
///
/// This rule fails when either consumer drops its reference to the shared
/// module or when the canonical helper definitions disappear from the module
/// (mirrors `repo.economy_cost_check_shared_helper`, #3517 Cluster 2).
const _helperRelativePath =
    'packages/colonizethis_economy/lib/src/economy/world_market/trade_order_admission.dart';

/// Shared symbols the admission module must define.
const _helperSymbols = <String>[
  'isWorldMarketTradeableCommodity',
  'commoditiesWithBidAndOffer',
  'admittedBidCommodityIdsInSubmissionOrder',
];

/// World-market consumers that must reference the shared admission module
/// instead of re-inlining the riches predicate / mutual-exclusion /
/// bid-admission idioms.
const _consumerRelativePaths = <String>[
  'packages/colonizethis_economy/lib/src/economy/world_market/trade_order_validator.dart',
  'packages/colonizethis_economy/lib/src/economy/world_market/trade_order_suggester.dart',
];

/// Marker that a consumer references the shared admission module.
const _sharedModuleImportToken = "trade_order_admission.dart'";

void main() {
  exit(runCheckEconomyWorldMarketAdmissionShared(Directory.current.path));
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckEconomyWorldMarketAdmissionShared(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);

  final helperFile = File(p.join(root, _helperRelativePath));
  if (!helperFile.existsSync()) {
    logE(
      'ERROR: Missing shared world-market admission helper file: '
      '$_helperRelativePath',
    );
    return 1;
  }
  final helperSource = helperFile.readAsStringSync();
  for (final symbol in _helperSymbols) {
    if (!helperSource.contains('$symbol(')) {
      logE(
        'ERROR: $_helperRelativePath no longer defines the shared `$symbol` '
        'helper; the canonical world-market admission contracts (rule 2/3/4) '
        'must live in one place (Refs #3615 Cluster 1).',
      );
      return 1;
    }
  }

  final violations = <String>[];
  for (final relative in _consumerRelativePaths) {
    final file = File(p.join(root, relative));
    if (!file.existsSync()) {
      logE('ERROR: Missing world-market admission consumer: $relative');
      return 1;
    }
    final source = file.readAsStringSync();
    if (!source.contains(_sharedModuleImportToken)) {
      violations.add(
        '$relative no longer imports trade_order_admission.dart; the '
        'validator and suggester must delegate riches/mutual-exclusion/'
        'bid-admission logic to the shared module instead of re-inlining it.',
      );
    }
  }

  if (violations.isEmpty) {
    logI('Economy world-market admission shared-helper check passed.');
    return 0;
  }

  logE(
    'ERROR: World-market admission logic must stay deduplicated via '
    'trade_order_admission.dart (Refs #3615 Cluster 1).',
  );
  for (final v in violations) {
    logE(v);
  }
  return 1;
}
